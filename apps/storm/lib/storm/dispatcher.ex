defmodule Storm.Dispatcher do
  defstruct [
    :simulation_id,
    to_start: []
  ]

  def start_clients(pid, session_id, ids) do
    clients =
      session_id
      |> List.wrap()
      |> Stream.cycle()
      |> Enum.zip(ids)
    request = {:add_clients, clients}

    GenServer.cast(pid, request)
  end
end
