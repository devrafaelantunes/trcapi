defmodule TrcWeb.Router do
  use TrcWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TrcWeb do
    pipe_through :api

    get "/entries", DatasetController, :index
  end
end
