defmodule IckyVenus.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias IckyVenus.Router

  @opts Router.init([])

  test "returns 200" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
