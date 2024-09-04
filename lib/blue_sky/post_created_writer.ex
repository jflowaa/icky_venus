defmodule BlueSky.PostCreatedWriter do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :register_event, 1000)
    {:ok, %{}}
  end

  def handle_call(:get_totals, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:register_event, state) do
    Registry.register(BlueSky.EventRegistry.PostCreated, :post_created, %{})
    {:noreply, state}
  end

  def handle_info(:broadcast, state) do
    count = Map.get(state, Date.to_string(Date.utc_today()), 0) + 1
    {:noreply, Map.put(state, Date.to_string(Date.utc_today()), count)}
  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  def terminate(_reason, state) do
    {:ok, state}
  end
end
