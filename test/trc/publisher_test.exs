defmodule Trc.PublisherTest do
  use ExUnit.Case, async: true
  import Mox
  alias Trc.TestUtils

  test "publishes parsed lines (without the header)" do
    """
    a,b,c,d
    1,2,3,4
    5,6,7,8
    """
    |> TestUtils.mock_bitstring()

    Trc.AMQP.QueueMock
    |> expect(:connect, fn -> {:ok, nil} end)

    Trc.AMQP.ExchangeMock
    |> expect(:declare_and_bind, fn _, exchange_name, queue_name ->
      assert queue_name == "dataset_name"
      assert exchange_name == "dataset_name_ex"
    end)
    |> expect(:publish, fn _, _, payload ->
      assert payload == "1,2,3,4\n5,6,7,8\n"
    end)

    assert :ok == Trc.Publisher.stream(:not_used, :dataset_name)
  end

  test "splits the file in multiple chunks" do
    """
    a,b,c,d
    1,2,3,4
    5,6,7,8
    """
    |> TestUtils.mock_bitstring(16)

    Trc.AMQP.QueueMock
    |> expect(:connect, fn -> {:ok, nil} end)

    Trc.AMQP.ExchangeMock
    |> expect(:declare_and_bind, fn _, exchange_name, queue_name ->
      assert queue_name == "dataset_name"
      assert exchange_name == "dataset_name_ex"
    end)
    |> expect(:publish, fn _, _, payload ->
      assert payload == "1,2,3,4\n"
    end)
    |> expect(:publish, fn _, _, payload ->
      assert payload == "5,6,7,8\n"
    end)

    assert :ok == Trc.Publisher.stream(:not_used, :dataset_name)
  end
end
