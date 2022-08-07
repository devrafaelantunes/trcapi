defmodule Trc.Redis do
  @moduledoc """
    Handles the Redis Cache implementation
  """

  # Typespecs
  @type k :: String.t()
  @type v :: String.t()

  @redis_url Application.compile_env!(:trc, :redis_url)

  # Expires the data in one day
  @expire_interval 86_400

  use GenServer

  @spec start_link(any()) :: {:ok, pid()} | {:error, any()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: :redis)
  end

  @doc """
    Stores the value under key in the cache
  """
  @spec set(k(), v()) :: String.t() | Redix.Error.t()
  def set(k, v) do
    GenServer.call(:redis, {:set, k, v})
  end

  @doc """
    Gets the value under key in the cache
  """
  @spec get(k()) :: String.t() | Redix.Error.t()
  def get(k) do
    GenServer.call(:redis, {:get, k})
  end

  @doc """
    Initializes the cache
  """
  @spec init(any()) :: {:ok, Redix.Connection} | {:error, any()}
  def init(_) do
    case Redix.start_link(@redis_url) do
      {:ok, conn} -> {:ok, conn}
      {:error, err} -> {:error, err}
    end
  end

  @doc false
  def handle_call({:set, key, value}, _from, state) do
    # Encode the value to be inserted in the cache
    value = Jason.encode!(value)
    result = Redix.command(state, ["SET", key, value])

    # Sets a TTL, that is: the datasets will be expired based on the `expire_interval`
    Redix.command(state, ["EXPIRE", key, @expire_interval])

    {:reply, result, state}
  end

  @doc false
  def handle_call({:get, key}, _from, state) do
    {:ok, reply} = Redix.command(state, ["GET", key])

    # Parses the result
    result =
      case reply do
        nil -> nil
        str when is_binary(str) -> Jason.decode!(str)
      end

    {:reply, result, state}
  end
end
