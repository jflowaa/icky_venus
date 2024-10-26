defmodule BlueSky.PostCreatedClient do
  def get_totals() do
    GenServer.call(BlueSky.PostCreatedServer, :get_totals)
  end
end
