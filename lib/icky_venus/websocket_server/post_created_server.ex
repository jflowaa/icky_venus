defmodule IckyVenus.WebsocketServer.PostCreatedServer do
  def init(_) do
    Process.send_after(self(), :register_event, 1000)
    {:ok, 0}
  end

  def handle_in(_, state) do
    {:ok, state}
  end

  def handle_info(:broadcast, state) do
    count = state + 1
    {:reply, :ok, {:text, "<span id=\"count\">#{count}</span>"}, count}
  end

  def handle_info(:register_event, state) do
    Registry.register(BlueSky.EventRegistry.PostCreated, :post_created, %{})
    {:ok, state}
  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, state) do
    {:ok, state}
  end
end
