defmodule Trc.ConsumerTest do
  use TrcWeb.ConnCase, async: false
  import Mox
  alias Trc.Consumer
  alias Trc.TestUtils
  alias Trc.Repo

  setup :set_mox_global

  test "inserts entries received from publisher" do
    dataset = :foo

    Trc.AMQP.QueueMock
    |> expect(:connect, fn -> {:ok, nil} end)
    |> expect(:declare, fn _, _ -> :ok end)
    |> expect(:consume, fn _, queue_name ->
      assert queue_name == "foo"
    end)
    |> expect(:ack_message, fn _, _ -> :ok end)

    {:ok, _} = TestUtils.setup_dataset(dataset)

    {:ok, pid} = Consumer.start_link(dataset: dataset)

    send_payload(pid, "1,2\n3,4\n5,6")

    :timer.sleep(100)

    [e1, e2, e3] =
      Trc.Model.DatasetEntry
      |> Repo.all()
      |> Enum.sort_by(& &1.entry)

    assert e1.entry == "1,2"
    assert e2.entry == "3,4"
    assert e3.entry == "5,6"
  end

  defp send_payload(pid, payload) do
    meta = %{}
    Process.send(pid, {:basic_deliver, payload, meta}, [])
  end
end
