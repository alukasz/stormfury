defmodule Fury.Session do
  @storm_bridge Application.get_env(:fury, :storm_bridge)

  # stub for testing until functionality is implemented
  def get_url(_session_id) do
    {:ok, "localhost"}
  end

  def get_request(session_id, request_id) do
    @storm_bridge.get_request(session_id, request_id)
  end
end
