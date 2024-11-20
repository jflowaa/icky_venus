defmodule BlueSky.Application do
  use Application

  @registry BlueSky.EventRegistry.PostCreated

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, [keys: :duplicate, name: @registry]},
      %{
        id: BlueSky.StreamReader,
        start: {BlueSky.StreamReader, :start_link, []},
        shutdown: 10_000
      },
      %{
        id: BlueSky.PostCreatedServer,
        start: {BlueSky.PostCreatedServer, :start_link, [%{}]}
      }
    ]

    Supervisor.start_link(children,
      strategy: :one_for_one,
      name: BlueSky.Supervisor
    )
  end
end
