defmodule Test.Cartograph.QueryParsing do
  use ExUnit.Case

  cases = [
    {":set single-values", [set: %{foo: "bar"}], "/test-path?foo=starting", "/test-path?foo=bar"},
    {":set multi-values", [set: %{foo: ["bar", "baz"]}], "/test-path?foo=starting",
     "/test-path?foo=bar&foo=baz"},
    {":set param order", [set: %{lorem: ["amet", "quid", "novi"]}], "/test-path?foo=starting",
     "/test-path?lorem=amet&lorem=quid&lorem=novi"},
    {":add single-values", [add: %{foo: "bar", lorem: "ipsum"}], "/test-path?foo=starting",
     "/test-path?foo=starting&foo=bar&lorem=ipsum"},
    {":add multi-values", [add: %{foo: ["bar", "baz"], lorem: "ipsum"}], "/test-path?foo=starting",
     "/test-path?foo=starting&foo=bar&foo=baz&lorem=ipsum"},
    {":add param order",
     [add: %{foo: "bar"}, add: %{foo: "baz"}, add: %{lorem: ["amet", "quid", "novi"]}],
     "/test-path?foo=starting",
     "/test-path?foo=starting&foo=bar&foo=baz&lorem=amet&lorem=quid&lorem=novi"},
    {":merge single-values", [merge: %{foo: "bar", lorem: "ipsum"}], "/test-path?foo=starting",
     "/test-path?foo=bar&lorem=ipsum"},
    {":merge multi-values", [merge: %{foo: ["bar", "baz"], lorem: "ipsum"}],
     "/test-path?foo=starting", "/test-path?foo=bar&foo=baz&lorem=ipsum"},
    {":merge nested replace-map", [merge: %{foo: %{"spam" => :eggs, baz: "qux"}}],
     "/test-path?foo=bar&foo=baz&foo=spam&bar=baz", "/test-path?foo=bar&foo=qux&foo=eggs&bar=baz"},
    {":remove key-only list value - bar", [remove: [:foo]], "/test-path?foo=bar&bar=baz",
     "/test-path?bar=baz"},
    {":remove key-only list value - baz", [remove: [:foo]], "/test-path?foo=baz&bar=baz",
     "/test-path?bar=baz"},
    {":remove key-only list value - bar and baz", [remove: [:foo]],
     "/test-path?foo=bar&foo=baz&bar=baz", "/test-path?bar=baz"},
    {":remove key-value map single-values - all matched", [remove: %{foo: "starting"}],
     "/test-path?foo=starting", "/test-path"},
    {":remove key-value map single-values - some matched", [remove: %{foo: "starting"}],
     "/test-path?foo=starting&foo=bar", "/test-path?foo=bar"},
    {":remove key-value map multi-values - all matched", [remove: %{foo: ["starting", "baz"]}],
     "/test-path?foo=starting", "/test-path"},
    {":remove key-value map multi-values - some matched", [remove: %{foo: ["starting", "baz"]}],
     "/test-path?foo=starting&foo=bar&foo=baz", "/test-path?foo=bar"},
    {":remove key-value map string keys", [remove: %{"foo" => "starting"}],
     "/test-path?foo=starting", "/test-path"},
    {":remove key-value map string keys array bracket syntax", [remove: %{"foo[]" => "starting"}],
     "/test-path?foo[]=starting", "/test-path"},
    {":toggle single-values - removed", [toggle: %{foo: "starting"}], "/test-path?foo=starting",
     "/test-path"},
    {":toggle single-values - added", [toggle: %{foo: "starting"}], "/test-path",
     "/test-path?foo=starting"},
    {":toggle multi-values", [toggle: %{foo: ["bar", "baz"]}], "/test-path?foo=starting&foo=bar",
     "/test-path?foo=starting&foo=baz"},
    {":toggle array key bracket syntax - removed", [toggle: %{"foo[]" => "starting"}],
     "/test-path?foo[]=starting", "/test-path"},
    {":toggle array key bracket syntax - added", [toggle: %{"foo[]" => "starting"}],
     "/test-path?foo[]=bar", "/test-path?foo%5B%5D=bar&foo%5B%5D=starting"},
    {":toggle param order",
     [toggle: %{foo: "bar"}, toggle: %{foo: "baz"}, toggle: %{foo: "bar"}, toggle: %{foo: "bar"}],
     "/test-path?foo=starting", "/test-path?foo=starting&foo=baz&foo=bar"},
    {"cumulative query options",
     [
       set: %{foo: "bar"},
       merge: %{foo: "baz", lorem: "ipsum"},
       merge: %{lorem: "ipsum", dolor: "sit"},
       toggle: %{foo: "baz"},
       add: %{foo: "bar"},
       add: %{foo: "baz"},
       add: %{lorem: ["amet", "quid", "novi"]},
       remove: [:foo, :lorem],
     ], "/test-path?foo=starting", "/test-path?dolor=sit"},
    {"query parsing works on url with no existing query", [set: %{foo: "bar"}], "/test-path",
     "/test-path?foo=bar"},
    {"existing params preserve order", [remove: [:bar]],
     "/test-path?foo=first&bar=second&baz=third", "/test-path?foo=first&baz=third"},
    {"literal plus sign is escaped", [set: %{foo: "bar+"}], "/test-path?foo=starting",
     "/test-path?foo=bar%2B"},
  ]

  describe "query parsing" do
    for {desc, val, starting, expected} <- cases do
      test "parse_patch: #{desc}" do
        val = unquote(Macro.escape(val))
        starting = unquote(starting)
        expected = unquote(expected)

        query_opts = [
          query: val,
        ]

        sut =
          Cartograph.Component.parse_patch(
            URI.parse("https://localhost:4000" <> starting),
            query_opts
          )

        assert ^sut = expected
      end

      test "parse_navigate: #{desc}" do
        val = unquote(Macro.escape(val))
        starting = unquote(starting)
        expected = unquote(expected)

        query_opts = [
          query: val,
        ]

        sut =
          Cartograph.Component.parse_navigate(
            URI.parse("https://localhost:4000" <> starting),
            query_opts
          )

        assert ^sut = "https://localhost:4000" <> expected
      end
    end
  end
end
