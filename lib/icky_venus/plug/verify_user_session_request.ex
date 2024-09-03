defmodule IckyVenus.Plug.VerifyUserSessionRequest do
  defmodule UnauthenticatedRequestError do
    @moduledoc """
    Error raised when the user session cookie is missing.
    """

    defexception message: "No user session provided"
  end

  def init(options), do: options

  def call(%Plug.Conn{request_path: path} = conn, opts) do
    if path in opts[:paths], do: verify_request!(conn.params, opts[:fields])
    conn
  end

  defp verify_request!(params, fields) do
    verified =
      params
      |> Map.keys()
      |> contains_fields?(fields)

    unless verified, do: raise(UnauthenticatedRequestError)
  end

  defp contains_fields?(keys, fields), do: Enum.all?(fields, &(&1 in keys))
end
