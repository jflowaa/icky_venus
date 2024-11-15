defmodule BlueSky.PostCreatedServer do
  use GenServer
  require Logger

  @state_file "post_created_state.json"
  @hour_in_milliseconds 3_600_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    state = read_state_from_file()
    Process.send_after(self(), :register_event, 1000)
    :timer.send_interval(@hour_in_milliseconds, :persist_state)
    {:ok, state}
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

  def handle_info(:persist_state, state) do
    write_state_to_file(state)
    {:noreply, state}
  end

  def terminate(reason, state) do
    write_state_to_file(state)
    Logger.info("PostCreatedServer is terminating", reason: reason)
    {:ok, state}
  end

  defp read_state_from_file do
    state_file_path = get_state_file_path()

    if File.exists?(state_file_path) do
      case File.read(state_file_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, state} ->
              state

            {:error, reason} ->
              Logger.error("Failed to decode JSON from state file", reason: reason)
              %{}
          end

        {:error, reason} ->
          Logger.error("Failed to read state file", reason: reason)
          %{}
      end
    else
      %{}
    end
  end

  defp write_state_to_file(state) do
    state
    |> Jason.encode!()
    |> (&File.write!(get_state_file_path(), &1)).()
  rescue
    e in File.Error ->
      Logger.error("Failed to write state file", exception: e)
      File.mkdir_p!(Path.dirname(get_state_file_path()))
      Logger.info("Attempting to write state file again after creating directory")

      state
      |> Jason.encode!()
      |> (&File.write!(get_state_file_path(), &1)).()
  end

  defp get_state_file_path do
    config_dir = :filename.basedir(:user_config, to_string(:icky_venus))
    Path.join([config_dir, @state_file])
  end
end
