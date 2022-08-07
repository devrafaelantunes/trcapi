defmodule Trc.Consumer do
  @moduledoc """
    Consumes and acknowledges messages from the Queue
  """

  alias Trc.{Service, Repo}
  alias Trc.AMQP.Queue
  use GenServer
  require Logger

  @spec start_link(args :: [dataset: atom()]) :: {:ok, pid()} | {:error, any()}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @doc """
    Initializes the consumer with a dataset,queue,conn and a tag
  """
  @spec init(dataset :: atom()) :: {:ok, map()}
  def init(dataset: dataset) do
    {:ok, conn} = queue_backend().connect()

    state = %{
      dataset: Service.Dataset.get_by_name!(dataset),
      queue: Queue.get_name(dataset),
      conn: conn,
      consumer_tag: nil
    }

    {:ok, state, {:continue, :setup}}
  end

  @doc """
    Sets the consumer up by declaring and consuming a queue
  """
  @spec handle_continue(:setup, map()) :: :ok
  def handle_continue(:setup, state) do
    queue_backend().declare(state.conn, state.queue)
    queue_backend().consume(state.conn, state.queue)

    {:noreply, state}
  end

  @doc false
  @spec handle_info({:basic_consume_ok, %{consumer_tag: String.t()}}, map()) :: :ok
  def handle_info({:basic_consume_ok, %{consumer_tag: tag}}, state) do
    Logger.info("#{inspect(self())} listening on topic #{state.queue} with tag #{tag}")
    {:noreply, %{state | consumer_tag: tag}}
  end

  @doc """
    Consumes the payload by inserting multiple entries at the same time

    To do that, a dynamic SQL query is created depending on the given amount of entries
  """
  @spec handle_info({:basic_deliver, payload :: String.t(), meta :: map()}, map()) :: :ok
  def handle_info({:basic_deliver, payload, meta}, state) do
    lines = String.split(payload, "\n", trim: true)
    total_lines = length(lines)

    args =
      Enum.reduce(lines, [], fn line, acc ->
        acc ++ [state.dataset.id, DateTime.utc_now(), line]
      end)

    # Creates the bindings based on the payload's total_lines
    sql_bindings =
      Enum.reduce(1..total_lines, "", fn i, acc ->
        if i == total_lines do
          acc <> "(?, ?, ?)"
        else
          acc <> "(?, ?, ?), "
        end
      end)

    # Creates the query by parsing it with the SQL bindings
    sql_query =
      "insert into dataset_entries (dataset_id, timestamp, entry) values #{sql_bindings}"

    # Inserts the entries
    Ecto.Adapters.SQL.query!(Repo, sql_query, args)

    # Acks the message
    queue_backend().ack_message(state.conn, meta)

    {:noreply, state}
  end

  defp queue_backend, do: Application.get_env(:trc, :queue_backend)
end
