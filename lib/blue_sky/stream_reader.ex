defmodule BlueSky.StreamReader do
  use WebSockex

  def start_link(state \\ []) do
    # extra_headers = [
    #   {"Authorization", "Bearer #{token}"}
    # ]

    WebSockex.start_link(
      "wss://bsky.network/xrpc/com.atproto.sync.subscribeRepos",
      __MODULE__,
      state
      # extra_headers: extra_headers
    )
  end

  def handle_frame({_, msg}, state) do
    {:ok, result, payload_raw} = CBOR.decode(msg)

    if Map.get(result, "t", "") == "#commit" do
      {:ok, payload, _} = CBOR.decode(payload_raw)
      operations = Map.get(payload, "ops", [])

      if Enum.any?(operations, fn x ->
           Map.get(x, "action", "") == "create" &&
             String.starts_with?(Map.get(x, "path", ""), "app.bsky.feed.post")
         end) do
        Registry.dispatch(BlueSky.EventRegistry.PostCreated, :post_created, fn entries ->
          for {pid, _} <- entries, do: send(pid, :broadcast)
        end)
      end
    end

    {:ok, state}
  end
end
