defmodule Fury.ClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias Fury.Client
  alias Fury.Mock.{Protocol, Transport}

  describe "connect/2" do
    setup do
      {:ok, url: "localhost"}
    end

    test "invokes Transport.connect", %{url: url} do
      expect Transport, :connect, fn _, _ -> {:ok, self()} end

      Client.connect(Transport, url)

      verify!()
    end

    test "returns transport pid", %{url: url} do
      stub Transport, :connect, fn _, _ -> {:ok, self()} end

      assert Client.connect(Transport, url) == {:ok, self()}
    end

    test "on error returns error tuple", %{url: url} do
      stub Transport, :connect, fn _, _ -> {:error, :timeout} end

      assert Client.connect(Transport, url) == {:error, :timeout}
    end
  end

  describe "make_request/4" do
    test "invokes Protocol.format/2" do
      expect Protocol, :format, fn _, _ -> {:ok, "data"} end
      stub Transport, :push, fn _, _ -> :ok end

      Client.make_request(Transport, self(), Protocol, "data")

      verify!()
    end

    test "invokes Transport.push/2" do
      stub Protocol, :format, fn _, _ -> {:ok, "data"} end
      expect Transport, :push, fn _, _ -> :ok end

      Client.make_request(Transport, self(), Protocol, "data")

      verify!()
    end
  end
end
