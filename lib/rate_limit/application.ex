defmodule RateLimit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias RateLimit.DynamicSupervisor

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DynamicSupervisor
      # Starts a worker by calling: RateLimit.Worker.start_link(arg)
      # {RateLimit.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RateLimit.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
