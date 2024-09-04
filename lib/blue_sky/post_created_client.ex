defmodule BlueSky.PostCreatedReader do
  def get_totals() do
    GenServer.call(BlueSky.PostCreatedWriter, :get_totals)
  end
end
