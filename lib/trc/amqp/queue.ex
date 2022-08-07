defmodule Trc.AMQP.Queue do
  @moduledoc """
    Handles the AMQP Queue implementation
  """

  # Typespec
  @type channel :: %AMQP.Channel{}
  @type queue :: String.t()
  @type delivery_tag :: %{delivery_tag: integer()}

  @doc """
    Opens an AMQP Channel and Connection
  """
  @callback connect() :: {:ok, channel()}
  @spec connect() :: {:ok, channel()}
  def connect() do
    # Opens a new connection to an AMQP broker
    if Application.get_env(:trc, :environment) == :prod do
      {:ok, connection} = AMQP.Connection.open("amqp://guest:guest@rabbitmq")

      # Opens a new channel inside the connection
      AMQP.Channel.open(connection)
    else
      {:ok, connection} = AMQP.Connection.open()

      # Opens a new channel inside the connection
      AMQP.Channel.open(connection)
    end
  end

  @doc """
    Declares an AMQP Queue
  """
  @callback declare(channel(), queue()) :: :ok
  @spec declare(channel(), queue()) :: :ok
  def declare(channel, queue) do
    AMQP.Queue.declare(channel, queue)
  end

  @doc """
    Registers a queue consumer process
  """
  @callback consume(channel(), queue()) :: :ok
  @spec consume(channel(), queue()) :: :ok
  def consume(channel, queue) do
    AMQP.Basic.consume(channel, queue)
  end

  @doc """
    Acknowledges messages
  """
  @callback ack_message(channel(), delivery_tag()) :: :ok
  @spec ack_message(channel(), delivery_tag()) :: :ok
  def ack_message(channel, %{delivery_tag: delivery_tag}) do
    AMQP.Basic.ack(channel, delivery_tag)
  end

  @doc """
    Parses the dataset name from Atom to String
  """
  @spec get_name(dataset_name :: atom()) :: String.t()
  def get_name(dataset_name), do: to_string(dataset_name)
end
