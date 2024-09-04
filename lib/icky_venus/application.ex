defmodule IckyVenus.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      {Bandit, scheme: :http, plug: IckyVenus.Router, port: server_port()},
      Registry.child_spec(
        keys: :duplicate,
        name: BlueSky.EventRegistry.PostCreated
      ),
      BlueSky.StreamReader,
      BlueSky.PostCreatedWriter
    ]

    opts = [strategy: :one_for_one, name: IckyVenus.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end

  defp server_port, do: Application.get_env(:example, :server_port, 4000)
end
