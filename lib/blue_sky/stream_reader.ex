defmodule BlueSky.StreamReader do
  use WebSockex
  require Logger

  @bluesky_websocket_url "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos"
  @post_path_prefix "app.bsky.feed.post"
  @initial_backoff 500

  def start_link(initial_state \\ []) do
    Task.start_link(fn ->
      connect_with_backoff(initial_state, @initial_backoff)
    end)

    {:ok, self()}
  end

  @impl true
  def handle_frame({_type, message}, state) do
    with {:ok, decoded_message, raw_payload} <- CBOR.decode(message),
         true <- commit_message?(decoded_message),
         {:ok, payload, _} <- CBOR.decode(raw_payload),
         true <- contains_post_creation?(payload) do
      broadcast_post_created()
      {:ok, state}
    else
      false ->
        # Not a commit message or post creation - normal case
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to process frame: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl true
  def handle_disconnect(_, state) do
    Logger.error("Disconnected from BlueSky WebSocket; reconnecting...")
    {:reconnect, state}
  end

  defp connect_with_backoff(initial_state, delay) do
    case WebSockex.start_link(@bluesky_websocket_url, __MODULE__, initial_state) do
      {:ok, pid} ->
        Logger.info("Successfully connected to BluSky WebSocket")
        pid

      {:error, reason} ->
        jitter = trunc(:rand.uniform() * delay * 0.1)
        next_delay = min(delay * 2, 30_000)

        Logger.warning("Failed to connect: #{inspect(reason)}. Retrying in #{delay + jitter}ms")
        Process.sleep(delay + jitter)
        connect_with_backoff(initial_state, next_delay)
    end
  end

  defp commit_message?(message) do
    Map.get(message, "t", "") == "#commit"
  end

  defp contains_post_creation?(payload) do
    payload
    |> Map.get("ops", [])
    |> Enum.any?(fn operation ->
      operation["action"] == "create" &&
        String.starts_with?(operation["path"] || "", @post_path_prefix)
    end)
  end

  defp broadcast_post_created do
    Registry.dispatch(BlueSky.EventRegistry.PostCreated, :post_created, fn entries ->
      for {pid, _} <- entries, do: send(pid, :broadcast)
    end)
  end
end
