defmodule Trc.Repo do
  use Ecto.Repo,
    otp_app: :trc,
    adapter: Ecto.Adapters.MyXQL
end
