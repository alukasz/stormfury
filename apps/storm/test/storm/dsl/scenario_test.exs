defmodule Storm.DSL.ScenarioTest do
  use ExUnit.Case, async: true

  alias Storm.DSL.Scenario

  describe "build/1" do
    test "builds push" do
      assert Scenario.build([push: ["data"]]) == {:ok, [push: "data"]}
    end

    test "builds think" do
      assert Scenario.build([think: [10]]) == {:ok, [think: 10]}
    end

    test "expands loop" do
      ast = [
        for: [
          in: [var: ["i"], range: [1, 2]],
          block: [push: ["data {{i}}"]]
        ]
      ]

      assert Scenario.build(ast) ==
        {:ok, [push: "data 1", push: "data 2"]}
    end

    test "expands nested loops" do
      ast = [
        for: [
          in: [var: ["i"], range: [1, 2]],
          block: [
            for: [
              in: [var: ["j"], range: [3, 4]],
              block: [push: ["{{i}}-{{j}}"]]]
          ]
        ]
      ]

      assert Scenario.build(ast) ==
        {:ok, [push: "1-3", push: "1-4", push: "2-3", push: "2-4"]}
    end

    test "returns error on invalid expression" do
      assert Scenario.build([foo: ["bar"]]) ==
        {:error, "invalid expression foo with arguments [\"bar\"]"}
    end
  end
end
