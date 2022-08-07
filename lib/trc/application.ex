defmodule Trc.Application do
  @moduledoc false

  use Application

  @datasets Application.compile_env!(:trc, :datasets)
  @env Mix.env()

  @impl true
  def start(_type, _args) do
    children =
      [
        Trc.Repo,
        {Task.Supervisor, name: Trc.TaskSupervisor},
        consumer_supervisors(),
        Trc.Redis,
        {Phoenix.PubSub, name: Trc.PubSub},
        TrcWeb.Endpoint
      ]
      |> List.flatten()

    opts = [strategy: :one_for_one, name: Trc.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    if @env != :test do
      bootstrap()
    end

    {:ok, pid}
  end

  defp consumer_supervisors do
    @datasets
    |> Enum.map(fn {dataset, _} ->
      %{
        id: dataset,
        start: {Trc.ConsumerSupervisor, :start_link, dataset: dataset}
      }
    end)
  end

  defp bootstrap do
    Enum.each(@datasets, fn {dataset, %{consumers: consumers}} ->
      # Setup datasets
      Trc.Service.Dataset.setup(dataset)

      # Initialize consumers (workers) for each dataset
      1..consumers
      |> Enum.each(fn _ ->
        Trc.ConsumerSupervisor.start_child(dataset)
      end)
    end)

    # Stream all datasets
    Trc.Publisher.start_streaming()
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrcWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
