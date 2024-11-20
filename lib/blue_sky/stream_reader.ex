defmodule BlueSky.StreamReader do
  use WebSockex
  require Logger

  @bluesky_websocket_url "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos"
  @post_path_prefix "app.bsky.feed.post"

  def start_link(initial_state \\ []) do
    WebSockex.start_link(
      @bluesky_websocket_url,
      __MODULE__,
      initial_state
    )
  end

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
