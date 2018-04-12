defmodule Storm.Launcher do
  def perform(pid) do
    GenServer.cast(pid, :perform)
  end
end
