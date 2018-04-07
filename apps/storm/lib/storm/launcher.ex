defmodule Storm.Launcher do
  def perform(session_id) do
    GenServer.call(name(session_id), :perform)
  end

  def name(session_id) do
    {:via, Registry, {Storm.Registry.Launcher, session_id}}
  end
end
