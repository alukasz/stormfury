defmodule Storm.SessionServer do
  use GenServer

  @registry Storm.Session.Registry

  defmodule State do
    defstruct [:id, :clients, :arrival_rate, :scenario]
  end

  def start_link([id | _] = opts) do
    GenServer.start_link(__MODULE__, opts, name: name(id))
  end

  def get_request(session, index) do
    GenServer.call(name(session), {:get_request, index})
  end

  def init([id, clients, arrival_rate, scenario]) do
    state = %State{
      id: id,
      clients: clients,
      arrival_rate: arrival_rate,
      scenario: scenario
    }

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
