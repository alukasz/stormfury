defmodule Storm.SessionServer do
  use GenServer

  @registry Storm.Session.Registry

  def start_link(%{id: id} = state) do
    GenServer.start_link(__MODULE__, state, name: name(id))
  end

  def get_request(session, index) do
    GenServer.call(name(session), {:get_request, index})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:get_request, index}, _, %{scenario: scenario} = state) do
    reply =
      case Enum.at(scenario, index, :not_found) do
        :not_found -> {:error, :not_found}
        request -> {:ok, request}
      end

    {:reply, reply, state}
  end

  defp name(id) do
    {:via, Registry, {@registry, id}}
  end
end
