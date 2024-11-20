defmodule IckyVenus.WebSocketServer.PostCreatedServer do
  use WebSockex
  require Logger

  @registry BlueSky.EventRegistry.PostCreated
  @reconnect_delay 500

  def init(_) do
    Process.flag(:trap_exit, true)
    schedule_registration()
    {:ok, 0}
  end

  def handle_in({_type, _msg}, state) do
    {:ok, state}
  rescue
    error ->
      Logger.error("Error handling incoming message: #{inspect(error)}")
      {:ok, state}
  end

  @impl true
  def handle_info(:broadcast, state) do
    count = state + 1
    formatted_count = Number.Delimit.number_to_delimited(count)
    response = "<span id=\"count\">#{formatted_count}</span>"

    {:reply, :ok, {:text, response}, count}
  rescue
    error ->
      Logger.error("Error broadcasting count: #{inspect(error)}")
      {:ok, state}
  end

  @impl true
  def handle_info(:register_event, state) do
    case Registry.register(@registry, :post_created, %{}) do
      {:ok, _pid} ->
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to register with registry: #{inspect(reason)}")
        schedule_registration()
        {:ok, state}
    end
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    Logger.warning("Terminating due to: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("WebSocket disconnected: #{inspect(reason)}")
    {:reconnect, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Server terminating. Reason: #{inspect(reason)}")
    {:ok, state}
  end

  defp schedule_registration do
    Process.send_after(self(), :register_event, @reconnect_delay)
  end
end
