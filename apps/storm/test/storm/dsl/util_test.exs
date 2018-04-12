defmodule Storm.DSL.UtilTest do
  use ExUnit.Case, async: true

  alias Storm.DSL.Util

  describe "replace_var/2" do
    test "replaces placeholders for variable with value" do
      assigns = %{"v1" => "{{v2}}", "v2" => "v3"}

      assert Util.replace_vars("{{v1}}", assigns) == "v3"
    end

    test "returns unmodified data when data is not binary" do
      assigns = %{"key" => "val"}

      assert Util.replace_vars(%{"key" => "val"}, assigns) ==
        %{"key" => "val"}
    end
  end
end
