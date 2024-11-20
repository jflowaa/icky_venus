defmodule BlueSky.PostCreatedClient do
  @server BlueSky.PostCreatedServer
  @timeout 5000

  def get_totals do
    try do
      {:ok, GenServer.call(@server, :get_totals, @timeout)}
    catch
      :exit, reason ->
        {:error, reason}
    end
  end
end
