defmodule Test.Cartograph.QueryParsing do
  use ExUnit.Case

  # TODO: Refactor these test cases to reduce duplication

  describe "patch query parsing" do
    test ":set query option - single-values" do
      query_opts = [
        query: [set: %{foo: "bar"}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=bar"
    end

    test ":set query option - multi-values" do
      query_opts = [
        query: [set: %{foo: ["bar", "baz"]}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=bar&foo=baz"
    end

    test ":set option query param order" do
      query_opts = [
        query: [set: %{lorem: ["amet", "quid", "novi"]}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?lorem=amet&lorem=quid&lorem=novi"
    end

    test ":add query option - single-values" do
      query_opts = [
        query: [add: %{foo: "bar", lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=starting&foo=bar&lorem=ipsum"
    end

    test ":add query option - multi-values" do
      query_opts = [
        query: [add: %{foo: ["bar", "baz"], lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=starting&foo=bar&foo=baz&lorem=ipsum"
    end

    test ":add option query param order" do
      query_opts = [
        query: [
          add: %{foo: "bar"},
          add: %{foo: "baz"},
          add: %{lorem: ["amet", "quid", "novi"]},
        ],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=starting&foo=bar&foo=baz&lorem=amet&lorem=quid&lorem=novi"
    end

    test ":merge query option - single-values" do
      query_opts = [
        query: [merge: %{foo: "bar", lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=bar&lorem=ipsum"
    end

    test ":merge query option - multi-values" do
      query_opts = [
        query: [merge: %{foo: ["bar", "baz"], lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=bar&foo=baz&lorem=ipsum"
    end

    test ":merge query option - nested replace-map" do
      query_opts = [
        query: [merge: %{foo: %{"spam" => :eggs, baz: "qux"}}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=bar&foo=baz&foo=spam&bar=baz"),
          query_opts
        )

      assert ^sut = "/test-path?foo=bar&foo=qux&foo=eggs&bar=baz"
    end

    test ":remove query option - key only" do
      query_opts = [
        query: [remove: [:foo]],
      ]

      sut1 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting&bar=baz"),
          query_opts
        )

      assert ^sut1 = "/test-path?bar=baz"

      sut2 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=bar&bar=baz"),
          query_opts
        )

      assert ^sut2 = "/test-path?bar=baz"

      sut3 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar&bar=baz"),
          query_opts
        )

      assert ^sut3 = "/test-path?bar=baz"
    end

    test ":remove query option - key-value single-values" do
      query_opts = [
        query: [remove: %{foo: "starting"}],
      ]

      sut1 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut1 = "/test-path"

      sut2 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar"),
          query_opts
        )

      assert ^sut2 = "/test-path?foo=bar"
    end

    test ":remove query option - key-value multi-values" do
      query_opts = [
        query: [remove: %{foo: ["starting", "baz"]}],
      ]

      sut1 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut1 = "/test-path"

      sut2 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar&foo=baz"),
          query_opts
        )

      assert ^sut2 = "/test-path?foo=bar"
    end

    test ":toggle query option - single-values" do
      query_opts = [
        query: [toggle: %{"foo" => "starting"}],
      ]

      sut1 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut1 = "/test-path"

      sut2 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=bar"),
          query_opts
        )

      assert ^sut2 = "/test-path?foo=bar&foo=starting"
    end

    test ":toggle option multi-values" do
      query_opts = [
        query: [toggle: %{foo: ["bar", "baz"]}],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar"),
          query_opts
        )

      assert ^sut = "/test-path?foo=starting&foo=baz"
    end

    test ":toggle query option - array query keys" do
      query_opts = [
        query: [toggle: %{"foo[]" => "starting"}],
      ]

      sut1 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo[]=starting"),
          query_opts
        )

      assert ^sut1 = "/test-path"

      sut2 =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo[]=bar"),
          query_opts
        )

      assert ^sut2 = "/test-path?foo[]=bar&foo[]=starting"
    end

    test ":toggle option query param order" do
      query_opts = [
        query: [
          toggle: %{foo: "bar"},
          toggle: %{foo: "baz"},
          toggle: %{foo: "bar"},
          toggle: %{foo: "bar"},
        ],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?foo=starting&foo=baz&foo=bar"
    end

    test "cumulative query options" do
      query_opts = [
        query: [
          set: %{foo: "bar"},
          merge: %{foo: "baz", lorem: "ipsum"},
          merge: %{lorem: "ipsum", dolor: "sit"},
          toggle: %{foo: "baz"},
          add: %{foo: "bar"},
          add: %{foo: "baz"},
          add: %{lorem: ["amet", "quid", "novi"]},
          remove: [:foo, :lorem],
        ],
      ]

      sut =
        Cartograph.Component.parse_patch(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "/test-path?dolor=sit"
    end

    test "query parsing works on url with no existing query" do
      sut =
        Cartograph.Component.parse_patch(URI.parse("https://localhost:4000/test-path"),
          query: [set: %{foo: "bar"}]
        )

      assert ^sut = "/test-path?foo=bar"
    end

    test "existing params preserve order" do
      uri = URI.parse("https://localhost:4000/test-path?foo=first&bar=second&baz=third")

      sut1 = Cartograph.Component.parse_patch(uri, query: [remove: [:baz]])
      assert ^sut1 = "/test-path?foo=first&bar=second"

      sut2 = Cartograph.Component.parse_patch(uri, query: [remove: [:bar]])
      assert ^sut2 = "/test-path?foo=first&baz=third"
    end
  end

  describe "navigate query parsing" do
    test ":set query option - single-values" do
      query_opts = [
        query: [set: %{foo: "bar"}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=bar"
    end

    test ":set query option - multi-values" do
      query_opts = [
        query: [set: %{foo: ["bar", "baz"]}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=bar&foo=baz"
    end

    test ":set option query param order" do
      query_opts = [
        query: [set: %{lorem: ["amet", "quid", "novi"]}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?lorem=amet&lorem=quid&lorem=novi"
    end

    test ":add query option - single-values" do
      query_opts = [
        query: [add: %{foo: "bar", lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=starting&foo=bar&lorem=ipsum"
    end

    test ":add query option - multi-values" do
      query_opts = [
        query: [add: %{foo: ["bar", "baz"], lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=starting&foo=bar&foo=baz&lorem=ipsum"
    end

    test ":add option query param order" do
      query_opts = [
        query: [
          add: %{foo: "bar"},
          add: %{foo: "baz"},
          add: %{lorem: ["amet", "quid", "novi"]},
        ],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut =
               "https://localhost:4000/test-path?foo=starting&foo=bar&foo=baz&lorem=amet&lorem=quid&lorem=novi"
    end

    test ":merge query option - single-values" do
      query_opts = [
        query: [merge: %{foo: "bar", lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=bar&lorem=ipsum"
    end

    test ":merge query option - multi-values" do
      query_opts = [
        query: [merge: %{foo: ["bar", "baz"], lorem: "ipsum"}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=bar&foo=baz&lorem=ipsum"
    end

    test ":merge query option - nested replace-map" do
      query_opts = [
        query: [merge: %{foo: %{"spam" => :eggs, baz: "qux"}}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=bar&foo=baz&foo=spam&bar=baz"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=bar&foo=qux&foo=eggs&bar=baz"
    end

    test ":remove query option - key only" do
      query_opts = [
        query: [remove: [:foo]],
      ]

      sut1 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting&bar=baz"),
          query_opts
        )

      assert ^sut1 = "https://localhost:4000/test-path?bar=baz"

      sut2 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=bar&bar=baz"),
          query_opts
        )

      assert ^sut2 = "https://localhost:4000/test-path?bar=baz"

      sut3 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar&bar=baz"),
          query_opts
        )

      assert ^sut3 = "https://localhost:4000/test-path?bar=baz"
    end

    test ":remove query option - key-value single-values" do
      query_opts = [
        query: [remove: %{foo: "starting"}],
      ]

      sut1 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut1 = "https://localhost:4000/test-path"

      sut2 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar"),
          query_opts
        )

      assert ^sut2 = "https://localhost:4000/test-path?foo=bar"
    end

    test ":remove query option - key-value multi-values" do
      query_opts = [
        query: [remove: %{foo: ["starting", "baz"]}],
      ]

      sut1 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut1 = "https://localhost:4000/test-path"

      sut2 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar&foo=baz"),
          query_opts
        )

      assert ^sut2 = "https://localhost:4000/test-path?foo=bar"
    end

    test ":toggle query option - single-values" do
      query_opts = [
        query: [toggle: %{"foo" => "starting"}],
      ]

      sut1 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut1 = "https://localhost:4000/test-path"

      sut2 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=bar"),
          query_opts
        )

      assert ^sut2 = "https://localhost:4000/test-path?foo=bar&foo=starting"
    end

    test ":toggle option multi-values" do
      query_opts = [
        query: [toggle: %{foo: ["bar", "baz"]}],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting&foo=bar"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=starting&foo=baz"
    end

    test ":toggle query option - array query keys" do
      query_opts = [
        query: [toggle: %{"foo[]" => "starting"}],
      ]

      sut1 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo[]=starting"),
          query_opts
        )

      assert ^sut1 = "https://localhost:4000/test-path"

      sut2 =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo[]=bar"),
          query_opts
        )

      assert ^sut2 = "https://localhost:4000/test-path?foo[]=bar&foo[]=starting"
    end

    test ":toggle option query param order" do
      query_opts = [
        query: [
          toggle: %{foo: "bar"},
          toggle: %{foo: "baz"},
          toggle: %{foo: "bar"},
          toggle: %{foo: "bar"},
        ],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?foo=starting&foo=baz&foo=bar"
    end

    test "cumulative query options" do
      query_opts = [
        query: [
          set: %{foo: "bar"},
          merge: %{foo: "baz", lorem: "ipsum"},
          merge: %{lorem: "ipsum", dolor: "sit"},
          toggle: %{foo: "baz"},
          add: %{foo: "bar"},
          add: %{foo: "baz"},
          add: %{lorem: ["amet", "quid", "novi"]},
          remove: [:foo, :lorem],
        ],
      ]

      sut =
        Cartograph.Component.parse_navigate(
          URI.parse("https://localhost:4000/test-path?foo=starting"),
          query_opts
        )

      assert ^sut = "https://localhost:4000/test-path?dolor=sit"
    end

    test "query parsing works on url with no existing query" do
      sut =
        Cartograph.Component.parse_navigate(URI.parse("https://localhost:4000/test-path"),
          query: [set: %{foo: "bar"}]
        )

      assert ^sut = "https://localhost:4000/test-path?foo=bar"
    end

    test "existing params preserve order" do
      uri = URI.parse("https://localhost:4000/test-path?foo=first&bar=second&baz=third")

      sut1 = Cartograph.Component.parse_navigate(uri, query: [remove: [:baz]])
      assert ^sut1 = "https://localhost:4000/test-path?foo=first&bar=second"

      sut2 = Cartograph.Component.parse_navigate(uri, query: [remove: [:bar]])
      assert ^sut2 = "https://localhost:4000/test-path?foo=first&baz=third"
    end
  end
end
