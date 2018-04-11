defmodule Storm.Dispatcher do
  defstruct [
    :simulation_id,
    :simulation_pid,
    :supervisor_pid,
    to_start: []
  ]

  def start_clients(simulation_id, session_id, ids) do
    clients =
      session_id
      |> List.wrap()
      |> Stream.cycle()
      |> Enum.zip(ids)
    request = {:add_clients, clients}

    GenServer.call(name(simulation_id), request)
  end

  def name(id) do
    {:via, Registry, {Storm.Registry.Dispatcher, id}}
  end
end
