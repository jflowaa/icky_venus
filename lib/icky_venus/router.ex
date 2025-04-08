defmodule IckyVenus.Router do
  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  plug(:match)
  plug(Plug.Logger)
  plug(:dispatch)

  @static_paths %{
    "/favicon.ico" => {"image/x-icon", "priv/static/favicon.ico"},
    "/robots.txt" => {"text/plain; charset=utf-8", "priv/static/robots.txt"}
  }

  get "/" do
    conn
    |> put_resp_content_type("text/html; charset=utf-8")
    |> send_resp(
      200,
      IckyVenus.HtmlRenderer.render_html("lib/icky_venus/index.html.eex")
    )
  end

  get "/events/post-created/totals" do
    totals =
      case BlueSky.PostCreatedClient.get_totals() do
        {:ok, totals} ->
          totals

        {:error, reason} ->
          Logger.error("Failed to get totals: #{inspect(reason)}")

          %{}
      end

    conn
    |> put_resp_content_type("application/json; charset=utf-8")
    |> send_resp(200, Jason.encode!(totals))
  end

  get "/events/post-created/stream" do
    conn
    |> WebSockAdapter.upgrade(
      IckyVenus.WebSocketServer.PostCreatedServer,
      [],
      timeout: 60_000
    )
    |> halt()
  end

  get "/:path" do
    full_path = "/" <> path

    if Map.has_key?(@static_paths, full_path) do
      {content_type, filepath} = @static_paths[full_path]

      if File.exists?(filepath) do
        conn
        |> put_resp_content_type(content_type)
        |> send_file(200, filepath)
      else
        Logger.warning("Static file not found: #{filepath}")
        send_resp(conn, 404, "File not found")
      end
    else
      # Pass through to next route if not a static file
      conn
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    status = conn.status || 500

    case status do
      status when status >= 500 ->
        Logger.error("""
        #{status} Error:
        Kind: #{inspect(kind)}
        Reason: #{inspect(reason)}
        Stack: #{Exception.format_stacktrace(stack)}
        Request: #{inspect(conn.method)} #{inspect(conn.request_path)}
        Params: #{inspect(conn.params)}
        """)

        send_resp(conn, status, "Internal server error")

      _ ->
        send_resp(conn, status, "Request error")
    end
  end
end
