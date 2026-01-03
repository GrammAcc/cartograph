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

  base_urls = [
    "/",
    "/page/",
    "/page?foo=bar",
    "/page/?foo=bar",
    "https://localhost:4000/",
    "https://localhost:4000/page",
    "https://localhost:4000/page/",
    "https://localhost:4000/page?foo=bar",
    "https://localhost:4000/page/?foo=bar",
  ]

  passthrough_opts = [
    :loading,
    :page_loading,
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

      for url <- base_urls do
        test "navigate: #{op} - #{desc} - #{url}" do
          op = unquote(op)
          val = unquote(Macro.escape(val))
          url = unquote(url)

          query_opts = [
            query: [{op, val}],
          ]

          assert_does_not_raise(Cartograph.Component.cartograph_navigate(url, query_opts))
        end
      end
    end

    for opt <- passthrough_opts do
      test "cartograph_patch passes #{opt} through to JS.push/2" do
        opt = unquote(opt)
        opts = [{opt, "value"}]
        sut = Cartograph.Component.cartograph_patch(opts)
        assert inspect(sut) =~ " #{to_string(opt)}: "
      end

      test "cartograph_navigate passes #{opt} through to JS.push/2" do
        opt = unquote(opt)
        opts = [{opt, "value"}]
        sut = Cartograph.Component.cartograph_navigate("/", opts)
        assert inspect(sut) =~ " #{to_string(opt)}: "
      end
    end
  end
end
