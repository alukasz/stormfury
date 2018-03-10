defmodule Fury.SessionTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.Session
  alias Fury.Mock.Storm

  describe "get_request/2" do
    test "invokes StormBridge.get_request/2" do
      expect Storm, :get_request, fn _, _ -> {:ok, {:think, 10}} end

      Session.get_request(:session_id, :request_id)

      verify!()
    end
  end
end
