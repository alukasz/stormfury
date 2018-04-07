defmodule Fury.Session.SessionServer do
  use GenServer

  alias Fury.Session
  alias Fury.Simulation.Config

  defmodule State do
    defstruct [
      :id,
      :simulation_id,
      :session,
      requests: []
    ]

    def new([simulation_id, session_id]) do
      %State{
        id: session_id,
        simulation_id: simulation_id,
        session: Config.session(simulation_id, session_id),
      }
    end
  end

  def start_link(simulation_id, session_id) do
    opts = [simulation_id, session_id]

    GenServer.start_link(__MODULE__, opts, name: name(session_id))
  end

  def init(opts) do
    send(self(), :parse_scenario)
    {:ok, State.new(opts)}
  end

  def handle_call({:get_request, id}, _, %{requests: requests} = state) do
    request = Enum.at(requests, id, :error)

    {:reply, request, state}
  end

  def handle_info(:parse_scenario, %{session: %{scenario: scenario}} = state) do
    {:ok, requests} = Storm.DSL.parse(scenario)

    {:noreply, %{state | requests: requests ++ [:done]}}
  end

  defp name(id) do
    Session.name(id)
  end
end