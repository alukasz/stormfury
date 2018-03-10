defmodule Storm.Session do
  alias Storm.SessionServer

  def new(id, clients, arrival_rate, scenario) do
    SessionServer.start_link([id, clients, arrival_rate, scenario])
  end

  defdelegate get_request(id, index), to: SessionServer
end
