defmodule Trc.ConsumerSupervisor do
  @moduledoc """
    Creates a Dynamic Supervision tree to handle the Consumer processes
  """

  use DynamicSupervisor

  @doc false
  @spec start_link({:dataset, atom()}) :: {:ok, pid()} | {:error, any()}
  def start_link({:dataset, dataset}) do
    DynamicSupervisor.start_link(__MODULE__, [dataset: dataset], name: dataset)
  end

  @doc false
  @spec start_child(atom()) :: {:ok, child_pid :: pid()} | {:error, any()}
  def start_child(dataset) do
    spec = {Trc.Consumer, dataset: dataset}
    DynamicSupervisor.start_child(dataset, spec)
  end

  @doc false
  @spec init(any()) :: {:ok, flags :: any()}
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
