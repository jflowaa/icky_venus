defmodule IckyVenus.Application do
  use Application
  require Logger

  @registry BlueSky.EventRegistry.PostCreated

  def start(_type, _args) do
    children = [
      %{
        id: Bandit,
        start:
          {Bandit, :start_link,
           [
             [
               scheme: :http,
               plug: IckyVenus.Router,
               port: server_port()
             ]
           ]}
      },
      {Registry,
       [
         keys: :duplicate,
         name: @registry
       ]},
      {BlueSky.StreamReader, []},
      {BlueSky.PostCreatedServer, [%{}]}
    ]

    Logger.info("Starting application on port http://localhost:#{server_port()}/")

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: IckyVenus.Supervisor
      # max_restarts: :infinity
    )
  end

  defp server_port do
    Application.get_env(:icky_venus, :server_port, 4000)
  end
end
