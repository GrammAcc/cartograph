defmodule Test.Navigation do
  use ExUnit.Case

  import Test.Utils

  cases = [
    {:set, "map", %{foo: "bar"}},
    {:add, "map", %{foo: "bar"}},
    {:merge, "map", %{foo: "bar"}},
    {:merge, "nested map", %{foo: %{"bar" => "baz"}}},
    {:toggle, "map", %{foo: "bar"}},
    {:remove, "map", %{foo: "bar"}},
    {:remove, "key-only list", [:foo]},
  ]

  describe "cartograph navigation events" do
    for {op, desc, val} <- cases do
      test "patch: #{op} - #{desc}" do
        op = unquote(op)
        val = unquote(Macro.escape(val))

        query_opts = [
          query: [{op, val}],
        ]

        assert_does_not_raise(Cartograph.Component.cartograph_patch(query_opts))
      end

      test "navigate: #{op} - #{desc}" do
        op = unquote(op)
        val = unquote(Macro.escape(val))

        query_opts = [
          query: [{op, val}],
        ]

        assert_does_not_raise(Cartograph.Component.cartograph_navigate("/", query_opts))
      end
    end
  end
end
