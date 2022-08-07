defmodule Trc.Publisher do
  @moduledoc """
    Produce and publishes messages to the Queue and to the Exchange
  """

  alias Trc.AMQP.{Queue, Exchange}

  @datasets Application.compile_env!(:trc, :datasets)

  @doc """
    Spawns a task for each dataset configured on the `config.exs` file.

    The task is responsible for streaming the dataset file.
  """
  @spec start_streaming() :: [term()]
  def start_streaming do
    @datasets
    |> Enum.map(fn {dataset, %{path: path}} ->
      Task.Supervisor.async(Trc.TaskSupervisor, fn ->
        stream(path, dataset)
      end)
    end)
    |> Task.await_many()
  end

  @doc """
    Streams, chunks and processes the dataset file.

    It also declares an Exchange and binds it to a Queue.
  """
  @spec stream(path :: String.t(), dataset :: atom()) :: :ok
  def stream(path, dataset) do
    # Connects to the queue
    {:ok, conn} = queue_backend().connect()

    queue_name = Queue.get_name(dataset)
    exchange_name = Exchange.get_name(dataset)
    exchange_backend().declare_and_bind(conn, exchange_name, queue_name)

    path
    # Processes the file by chunks splitted based on the chunk_size
    |> file_io().get_stream(chunk_size: 32_768)
    |> Stream.scan({0, ''}, fn chunk, {chunk_id, leftover_acc} ->
      chunk = String.to_charlist(chunk)
      chunk = [leftover_acc | chunk]

      {lines, leftover} = get_lines_from_chunk(chunk_id, chunk)

      # Send chunk to workers
      exchange_backend().publish(conn, exchange_name, lines)

      {chunk_id + 1, leftover}
    end)
    |> Stream.run()
  end

  defp get_lines_from_chunk(0, chunk) do
    # Removes header
    chunk =
      Enum.reduce_while(chunk, chunk, fn
        10, acc -> {:halt, List.delete_at(acc, 0)}
        _, acc -> {:cont, List.delete_at(acc, 0)}
      end)

    get_lines_from_chunk(nil, chunk)
  end

  defp get_lines_from_chunk(_, chunk) do
    # Reverts the chunk to find the last (now, first) line. Everything that comes after that line
    # is send back as the leftover.
    reversed_chunk = Enum.reverse(chunk)

    {lines, leftover} =
      Enum.reduce_while(reversed_chunk, {reversed_chunk, ''}, fn
        10, {rev_acc, leftover_acc} ->
          {:halt, {Enum.reverse(rev_acc), leftover_acc}}

        c, {rev_acc, leftover_acc} ->
          {:cont, {List.delete_at(rev_acc, 0), [c | leftover_acc]}}
      end)

    {List.to_string(lines), leftover}
  end

  defp exchange_backend, do: Application.get_env(:trc, :exchange_backend)
  defp queue_backend, do: Application.get_env(:trc, :queue_backend)
  defp file_io, do: Application.get_env(:trc, :file_io)
end
