defmodule Fury.Client.ClientFSMTest do
  use ExUnit.Case

  import Mox

  alias Fury.Client
  alias Fury.Session
  alias Fury.Metrics
  alias Fury.Client.ClientFSM
  alias Fury.Session.SessionServer
  alias Fury.Mock.{Protocol, Transport}

  setup :default_structs

  describe "start_link/1" do
    setup :set_mox_global
    setup :metrics
    setup do
      stub Protocol, :init, fn -> %{} end

      :ok
    end

    test "starts new ClientFSM", %{client: client} do
      {:ok, pid} = ClientFSM.start_link(client)

      assert is_pid(pid)
    end
  end

  describe "init/1" do
    setup do
      stub Protocol, :init, fn -> %{} end

      :ok
    end

    test "initializes protocol state", %{client: client} do
      expect Protocol, :init, fn -> :protocol_state end

      assert {:ok, _, %{protocol_state: :protocol_state}} =
        ClientFSM.init(client)

      verify!()
    end

    test "sets initial state to :disconnected", %{client: client} do
      assert {_, :disconnected, _} = ClientFSM.init(client)
    end
  end

  describe "callback_mode/0" do
    test "is :handle_event_function" do
      assert :handle_event_function in ClientFSM.callback_mode()
    end

    test "is :state_enter" do
      assert :state_enter in ClientFSM.callback_mode()
    end
  end

  describe "handle_event(:enter, _, :disconnected, _)" do
    test "keeps state and data", %{client: client} do
      for_all_states fn state ->
        assert {:keep_state_and_data, _} =
          ClientFSM.handle_event(:enter, state, :disconnected, client)
      end
    end

    test "sets state timeout to connect in 1 second", %{client: client} do
      for_all_states fn state ->
        assert {_, [{:state_timeout, 1000, :connect}]} =
          ClientFSM.handle_event(:enter, state, :disconnected, client)
      end
    end
  end

  describe "handle_event(:enter, _, :connected, _)" do
    test "keeps state and data", %{client: client} do
      for_all_states fn state ->
        assert :keep_state_and_data =
          ClientFSM.handle_event(:enter, state, :connected, client)
      end
    end

    test "sends message to make request", %{client: client} do
      for_all_states fn state ->
        ClientFSM.handle_event(:enter, state, :connected, client)

        assert_receive :make_request
      end
    end
  end

  describe "handle_event(:state_timeout, :connect, _, _)" do
    setup %{client: client} do
      {:ok, client: %{client | supervisor_pid: self(),
                      transport_mod: Fury.Transport.WebSocket}}
    end

    test "starts transport under supervisor", %{client: client} do
      spawn fn ->
        ClientFSM.handle_event(:state_timeout, :connect, :disconnected, client)
      end

      assert_receive {_, _, {:start_child, _}}
    end
  end

  describe "handle_event(:info, :transport_connected, _, _)" do
    setup :metrics

    test "switches state to :connected", %{client: client} do
      for_all_states fn state ->
        assert {:next_state, :connected, ^client} =
          ClientFSM.handle_event(:info, :transport_connected, state, client)
      end
    end

    test "increases :connected metric", %{client: client, metrics_ref: ref} do
      for_all_states fn state ->
        ClientFSM.handle_event(:info, :transport_connected, state, client)
      end

      assert {:clients_connected, 2} in Metrics.get(ref)
    end
  end

  describe "handle_event(:info, {:transport_data, data}, _, _)" do
    setup :metrics

    test "invokes protocol to handle data", %{client: client} do
      expect Protocol, :handle_data, 2, fn "data", %{} ->
        {:ok, :updated_state}
      end

      for_all_states fn state ->
        ClientFSM.handle_event(:info, {:transport_data, "data"}, state, client)
      end

      verify!()
    end

    test "updates protocol state", %{client: client} do
      stub Protocol, :handle_data, fn "data", %{} ->
        {:ok, :updated_state}
      end

      for_all_states fn state ->
        assert {_, %{protocol_state: :updated_state}} =
          ClientFSM.handle_event(:info, {:transport_data, "data"}, state, client)
      end
    end

    test "keeps state", %{client: client} do
      stub Protocol, :handle_data, fn "data", %{} ->
        {:ok, :updated_state}
      end

      for_all_states fn state ->
        assert {:keep_state, _} =
          ClientFSM.handle_event(:info, {:transport_data, "data"}, state, client)
      end
    end

    test "increases :messages_received metric", %{client: client, metrics_ref: ref} do
      stub Protocol, :handle_data, fn "data", %{} ->
        {:ok, :updated_state}
      end

      for_all_states fn state ->
        ClientFSM.handle_event(:info, {:transport_data, "data"}, state, client)
      end

      assert {:messages_received, 2} in Metrics.get(ref)
    end
  end

  describe "handle_event(:info, :DOWN, _, _)" do
    setup :metrics
    setup %{client: client} do
      ref = make_ref()
      down_tuple = {:DOWN, ref, :a, :b, :c}

      {:ok, down_tuple: down_tuple, client: %{client | transport_ref: ref}}
    end

    test "resets transport", %{down_tuple: down_tuple, client: client} do
      for_all_states fn state ->
        assert {_, _, %{transport: nil, transport_ref: nil, request: 0}} =
          ClientFSM.handle_event(:info, down_tuple, state, client)
      end
    end

    test "when connected switches state to :disconnected",
        %{down_tuple: down_tuple, client: client} do
      assert {:next_state, :disconnected, _} =
        ClientFSM.handle_event(:info, down_tuple, :connected, client)
    end

    test "when disconnected repeats state",
        %{down_tuple: down_tuple, client: client} do
      assert {:repeat_state, :disconnected, _} =
        ClientFSM.handle_event(:info, down_tuple, :disconnected, client)
    end

    test "when connected decreases :clients_connected metric",
        %{client: client, metrics_ref: ref, down_tuple: down_tuple} do
      ClientFSM.handle_event(:info, down_tuple, :connected, client)

      assert {:clients_connected, -1} in Metrics.get(ref)
    end

    test "does not change clients_connected metric when disconnected",
        %{client: client, metrics_ref: ref, down_tuple: down_tuple} do
      ClientFSM.handle_event(:info, down_tuple, :disconnected, client)

      assert {:clients_connected, 0} in Metrics.get(ref)
    end
  end

  describe "handle_event(:info, :make_request, :disconnected, _)" do
    test "does not invoke protocol or transport", %{client: client} do
      stub Protocol, :format, fn _, _ -> send(self(), :protocol_invoked) end
      stub Transport, :push, fn _, _ -> send(self(), :transport_invoked) end

      ClientFSM.handle_event(:info, :make_request, :disconnected, client)

      refute_receive _
    end

    test "keeps state and data", %{client: client} do
      assert :keep_state_and_data =
        ClientFSM.handle_event(:info, :make_request, :disconnected, client)
    end
  end

  describe "handle_event(:info, :make_request, :connected, _)" do
    setup :start_state_server
    setup :metrics
    setup %{client: client} do
      {:ok, client: %{client | transport: self()}}
    end

    test "when request is found increases state.request",
        %{client: client} = context do
      start_session_server(context, "think 10")
      expected_request_id = client.request + 1

      assert {:keep_state, %{request: ^expected_request_id}} =
        ClientFSM.handle_event(:info, :make_request, :connected, client)
    end

    test "updates state.protocol_state", %{client: client} = context do
      start_session_server(context, "push \"data\"")
      stub Protocol, :format, fn _, _ -> {:ok, "data", :updated_state} end
      stub Transport, :push, fn _, _ -> :ok end

      assert {:keep_state, %{protocol_state: :updated_state}} =
        ClientFSM.handle_event(:info, :make_request, :connected, client)
    end

    test "does not make request on {:think, time}",
        %{client: client} = context do
      start_session_server(context, "think 10")
      stub Protocol, :format, fn _, _ -> send(self(), :protocol_called) end
      stub Transport, :push, fn _, _ -> send(self(), :tranport_called) end

      ClientFSM.handle_event(:info, :make_request, :connected, client)

      refute_receive _
    end

    test "on :done keeps state and data", %{client: client} = context do
      start_session_server(context, "think 10")
      client = %{client | request: 1}

      assert :keep_state_and_data =
        ClientFSM.handle_event(:info, :make_request, :connected, client)
    end

    test "sends message to make next request", %{client: client} = context do
      start_session_server(context, "push \"data\"")
      stub Protocol, :format, fn _, _ -> {:ok, "data", %{}} end
      stub Transport, :push, fn _, _ -> :ok end

      ClientFSM.handle_event(:info, :make_request, :connected, client)

      assert_receive :make_request
    end

    test "when request not found unmodified state", %{client: client} = context do
      start_session_server(context, "push \"data\"")
      client = %{client | request: 1_000}

      assert ClientFSM.handle_event(:info, :make_request, :connected, client) ==
        :keep_state_and_data
    end

    test "performs received request", %{client: client} = context do
      start_session_server(context, "push \"data\"")
      expect Protocol, :format, fn {:push, "data"}, _ -> {:ok, "data", %{}} end
      expect Transport, :push, fn _, "data" -> :ok end

      ClientFSM.handle_event(:info, :make_request, :connected, client)

      verify!()
    end

    test "when making request increases :messages_sent metric",
        %{client: client, metrics_ref: ref} = context do
      start_session_server(context, "push \"data\"")
      stub Protocol, :format, fn _, _ -> {:ok, "data", %{}} end
      stub Transport, :push, fn _, _ -> :ok end

      ClientFSM.handle_event(:info, :make_request, :connected, client)

      assert {:messages_sent, 1} in Metrics.get(ref)
    end

    test "on {:think, time} doesn't increase :messages_sent metric",
        %{client: client, metrics_ref: ref} = context do
      start_session_server(context, "think 10")

      ClientFSM.handle_event(:info, :make_request, :connected, client)

      refute {:messages_sent, 1} in Metrics.get(ref)
    end
  end

  def for_all_states(fun) do
    Enum.each([:connected, :disconnected], fun)
  end

  defp default_structs(_) do
    simulation_id = make_ref()
    session = %Session{
      id: make_ref(),
      simulation_id: simulation_id,
      scenario: "push \"data\""
    }
    client = %Client{
      id: :id,
      session_id: session.id,
      simulation_id: simulation_id,
      url: "localhost",
      transport_mod: Transport,
      protocol_mod: Protocol,
      protocol_state: %{},
    }

    {:ok, session: session, client: client}
  end

  defp start_state_server(%{session: %{simulation_id: id}}) do
    {:ok, _} = start_supervised({Fury.State.StateServer, id})

    :ok
  end

  defp start_session_server(%{session: session}, scenario) do
    {:ok, pid} = Supervisor.start_link([], strategy: :one_for_one)
    session = %{session | scenario: scenario, supervisor_pid: pid}
    {:ok, _} = start_supervised({SessionServer, session})

    :ok
  end

  def metrics(%{client: client}) do
    ref = Metrics.new()

    {:ok, client: %{client | metrics_ref: ref}, metrics_ref: ref}
  end
end
