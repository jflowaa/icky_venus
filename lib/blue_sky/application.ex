defmodule BlueSky.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Registry.child_spec(
        keys: :duplicate,
        name: BlueSky.EventRegistry.PostCreated
      ),
      BlueSky.StreamReader,
      BlueSky.PostCreatedWriter
    ]

    opts = [strategy: :one_for_one, name: BlueSky.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
