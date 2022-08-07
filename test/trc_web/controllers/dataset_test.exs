defmodule TrcWeb.DatasetControllerTest do
  use TrcWeb.ConnCase
  import ExUnit.CaptureLog
  alias Trc.TestUtils

  test "returns empty list when there are no rows", %{conn: conn} do
    TestUtils.setup_dataset(:foo)
    assert {[], _, _} = fetch(conn, "?dataset=foo")
  end

  test "returns first few rows when `last_ts` is not set", %{conn: conn} do
    {:ok, %{id: dataset_id}} = TestUtils.setup_dataset(:foo)

    [
      {dataset_id, "1,2"},
      {dataset_id, "3,4"}
    ]
    |> Enum.each(&TestUtils.add_entry/1)

    assert {[row_1, row_2], _, _} = fetch(conn, "?dataset=foo")

    assert row_1["entry"] == "1,2"
    assert Map.has_key?(row_1, "timestamp")
    assert row_2["entry"] == "3,4"
    assert Map.has_key?(row_2, "timestamp")
  end

  test "limits returned entries", %{conn: conn} do
    {:ok, %{id: dataset_id}} = TestUtils.setup_dataset(:foo)

    [
      {dataset_id, "1,2"},
      {dataset_id, "3,4"},
      {dataset_id, "5,6"},
      {dataset_id, "7,8"}
    ]
    |> Enum.each(&TestUtils.add_entry/1)

    assert {[row_1], _, _} = fetch(conn, "?dataset=foo&limit=1")
    assert row_1["entry"] == "1,2"
  end

  test "paginates results based on `last_ts`", %{conn: conn} do
    {:ok, %{id: dataset_id}} = TestUtils.setup_dataset(:foo)

    [
      {dataset_id, "1,2"},
      {dataset_id, "3,4"},
      {dataset_id, "5,6"},
      {dataset_id, "7,8"}
    ]
    |> Enum.each(&TestUtils.add_entry/1)

    # No `last_ts` set, so we fetch the first entry
    assert {[row_1], _, _} = fetch(conn, "?dataset=foo&limit=1")
    # Fetch next one off of row_1's timestamp...
    assert {[row_2], _, _} = fetch(conn, "?dataset=foo&limit=1&last_ts=#{row_1["timestamp"]}")
    # And so on...
    assert {[row_3], _, _} = fetch(conn, "?dataset=foo&limit=1&last_ts=#{row_2["timestamp"]}")
    assert {[row_4], _, _} = fetch(conn, "?dataset=foo&limit=1&last_ts=#{row_3["timestamp"]}")

    assert row_1["entry"] == "1,2"
    assert row_2["entry"] == "3,4"
    assert row_3["entry"] == "5,6"
    assert row_4["entry"] == "7,8"
  end

  test "returns fresh data on first get request ", %{conn: conn} do
    {:ok, %{id: dataset_id}} = TestUtils.setup_dataset(:foo)

    [
      {dataset_id, "1,2"},
      {dataset_id, "3,4"}
    ]
    |> Enum.each(&TestUtils.add_entry/1)

    cache_key = TestUtils.get_cache_key(dataset_id, 0, 50)

    # Initially there's no data in redis
    assert nil == Trc.Redis.get(cache_key)

    # First request got a "cache miss"
    log =
      capture_log(fn ->
        fetch(conn, "?dataset=foo")
      end)

    assert log =~ "Cache miss"

    # And the data is now cached in Redis
    assert [row_1, row_2] = Trc.Redis.get(cache_key)
    assert row_1["entry"] == "1,2"
    assert row_2["entry"] == "3,4"

    # Second request now got a cache hit
    log =
      capture_log(fn ->
        fetch(conn, "?dataset=foo")
      end)

    assert log =~ "Cache hit"
  end

  test "returns error when dataset is not specified", %{conn: conn} do
    assert {%{"error" => "Dataset not specified"}, _, _} = fetch(conn, "")
    assert {%{"error" => "Dataset not specified"}, _, _} = fetch(conn, "?dataset=")
  end

  defp fetch(conn, query_string) do
    conn = get(conn, "/api/entries#{query_string}")
    {conn.resp_body |> Jason.decode!(), conn.status, conn}
  end
end
