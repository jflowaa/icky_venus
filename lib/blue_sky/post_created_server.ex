defmodule BlueSky.PostCreatedServer do
  use GenServer
  require Logger

  @state_file "post_created_state.json"
  @five_minutes_in_milliseconds 300_000
  @registry BlueSky.EventRegistry.PostCreated

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    Process.flag(:trap_exit, true)
    schedule_tasks()

    {:ok, load_initial_state()}
  end

  @impl GenServer
  def handle_call(:get_totals, _from, state), do: {:reply, state, state}

  @impl GenServer
  def handle_info(:register_event, state) do
    Registry.register(@registry, :post_created, %{})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:broadcast, state) do
    today = get_today()
    {:noreply, update_count(state, today)}
  end

  @impl GenServer
  def handle_info(:persist_state, state) do
    save_state(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:EXIT, _pid, _reason}, state) do
    save_state(state)
    {:stop, :normal, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    save_state(state)
  end

  defp schedule_tasks do
    Process.send_after(self(), :register_event, 1000)
    :timer.send_interval(@five_minutes_in_milliseconds, :persist_state)
  end

  defp load_initial_state do
    case File.read(get_state_file_path()) do
      {:ok, contents} ->
        Jason.decode!(contents)

      {:error, _reason} ->
        Logger.warning("No state file found, starting fresh")
        %{}
    end
  rescue
    e ->
      Logger.error("Failed to load state: #{inspect(e)}")
      %{}
  end

  defp save_state(state) do
    File.write!(get_state_file_path(), Jason.encode!(state))
  rescue
    e -> Logger.error("Failed to save state: #{inspect(e)}")
  end

  defp get_today, do: Date.utc_today() |> Date.to_string()

  defp update_count(state, date) do
    Map.update(state, date, 1, &(&1 + 1))
  end

  defp get_state_file_path do
    config_dir = :filename.basedir(:user_config, to_string(:icky_venus))
    IO.puts("config_dir: #{inspect(config_dir)}")
    Path.join([config_dir, @state_file])
  end
end
