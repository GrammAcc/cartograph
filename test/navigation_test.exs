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
    {:remove, "map string keys", %{"foo" => "bar"}},
    {:remove, "map array bracket keys", %{"foo[]" => "bar"}},
    {:remove, "key-only list", [:foo]},
  ]

  base_urls = [
    "/",
    "/page/",
    "/page?foo=bar",
    "/page/?foo=bar",
    "/page?foo[]=bar",
    "https://localhost:4000/",
    "https://localhost:4000/page",
    "https://localhost:4000/page/",
    "https://localhost:4000/page?foo=bar",
    "https://localhost:4000/page?foo[]=bar",
    "https://localhost:4000/page/?foo=bar",
  ]

  passthrough_opts = [
    :loading,
    :page_loading,
  ]

  describe "cartograph navigation events" do
    for {op, desc, val} <- cases do
      for url <- base_urls do
        test "patch: #{op} - #{desc} - #{url}" do
          op = unquote(op)
          val = unquote(Macro.escape(val))
          url = unquote(url)

          query_opts = [
            query: [{op, val}],
          ]

          assert_does_not_raise(Cartograph.Component.cartograph_patch(query_opts))

          # Note: The JS struct is opaque, so this test may break between liveview versions.
          sut = Cartograph.Component.cartograph_patch(query_opts)

          event_value =
            sut.ops |> List.first() |> Enum.at(1) |> Map.get(:value) |> Map.get("query_opts")

          assert_does_not_raise(Cartograph.Component.parse_patch(url, query: event_value))
        end

        test "navigate: #{op} - #{desc} - #{url}" do
          op = unquote(op)
          val = unquote(Macro.escape(val))
          url = unquote(url)

          query_opts = [
            query: [{op, val}],
          ]

          assert_does_not_raise(Cartograph.Component.cartograph_navigate(url, query_opts))

          # Note: The JS struct is opaque, so this test may break between liveview versions.
          sut = Cartograph.Component.cartograph_navigate(url, query_opts)

          event_value =
            sut.ops |> List.first() |> Enum.at(1) |> Map.get(:value) |> Map.get("query_opts")

          assert_does_not_raise(Cartograph.Component.parse_navigate(url, query: event_value))
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
