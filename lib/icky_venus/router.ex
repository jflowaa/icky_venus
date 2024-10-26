defmodule IckyVenus.Router do
  import EEx
  use Plug.Router
  use Plug.ErrorHandler

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html; charset=utf-8")
    |> send_resp(
      200,
      IckyVenus.HtmlRenderer.render_html("lib/icky_venus/index.html.eex", %{
        total_content:
          eval_file(
            "lib/icky_venus/totals.html.eex",
            assigns: %{totals: BlueSky.PostCreatedClient.get_totals()}
          )
      })
    )
  end

  get "/events/post-created/totals" do
    conn
    |> put_resp_content_type("text/html; charset=utf-8")
    |> send_resp(
      200,
      eval_file(
        "lib/icky_venus/totals.html.eex",
        assigns: %{totals: BlueSky.PostCreatedClient.get_totals()}
      )
    )
  end

  get "/events/post-created/stream" do
    conn
    |> WebSockAdapter.upgrade(IckyVenus.WebSocketServer.PostCreatedServer, [], timeout: 60_000)
    |> halt()
  end

  get "/favicon.ico" do
    conn
    |> put_resp_content_type("image/x-icon")
    |> send_file(200, "priv/static/favicon.ico")
  end

  get "/robots.txt" do
    conn
    |> put_resp_content_type("text/plain; charset=utf-8")
    |> send_file(200, "priv/static/robots.txt")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    IO.inspect(kind, label: :kind)
    IO.inspect(reason, label: :reason)
    IO.inspect(stack, label: :stack)
    send_resp(conn, conn.status, "Encountered an error that cannot be handled")
  end
end
