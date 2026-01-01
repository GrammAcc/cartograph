defmodule Cartograph.LiveViewParams do
  @moduledoc """
  This module provides integration with the Cartograph navigation events for a LiveView process.

  To enable cartograph patch and navigate events, simply `use Cartograph.LiveViewParams` from
  a LiveView module.

  This will also add a `@cartograph_uri` key to the assigns. This key will always contain the current URI from the latest call to `c:Phoenix.LiveView.handle_params/3`.

  The `LiveViewParams` module also provides some conveniences for reducing boilerplate related to `c:Phoenix.LiveView.handle_params/3`.

  See the documentation for `__using__/1` for available options.

  See the api documentation for `Cartograph.Component` for how to send patch and navigation events to the using LiveView.
  """

  import Phoenix.LiveView, only: [push_patch: 2, push_navigate: 2]

  @doc """
  Adds cartograph event handling to a LiveView.

      use Cartograph.LiveViewParams,
        cartograph_parser: true,
        handle_params: false,

  ## Options

    * `:cartograph_parser` - if `true` (default: true) then run any parsing handlers defined with
    the `@cartograph_parser` module attribute on the using LiveView.

    * `:handle_params` - if `true` (default: false) then add a default implementation of
      `c:Phoenix.LiveView.handle_params/3`. Useful when using `:cartograph_parser` to
      parse the params.

  > #### Important {: .info}
  >
  > The `LiveViewParams` must be `use`d **AFTER** the `LiveView` behavior or the `on_mount/1` hook
  > that sets up the param parsing will not be registered. This is needed even if
  > `:cartograph_parser` is false because cartograph adds the `@cartograph_uri` assign to allow
  > relative query patching.
  >
  > Good:
  >
  > ```elixir
  > use Phoenix.LiveView
  > use Cartograph.LiveViewParams
  > ```
  >
  > Bad:
  > ```elixir
  > use Cartograph.LiveViewParams
  > use Phoenix.LiveView
  > ```
  """
  defmacro __using__(opts \\ []) do
    implement_handle_params = Keyword.get(opts, :handle_params, false)
    run_parsers = Keyword.get(opts, :cartograph_parser, true)

    caller = __CALLER__.module

    quote do
      import Cartograph.LiveViewParams

      if unquote(run_parsers) do
        Module.register_attribute(unquote(caller), :cartograph_parser, accumulate: true)
      end

      on_mount({__MODULE__, :cartograph})

      if unquote(implement_handle_params) do
        @impl true
        def handle_params(_params, _uri, socket), do: {:noreply, socket}
      end

      @impl true
      def handle_event(
            "cartograph_patch",
            %{"query_opts" => query_opts, "value" => phx_value},
            socket
          ) do
        uri = socket.assigns.cartograph_uri
        href = Cartograph.Component.parse_patch(uri, query: query_opts, phx_value: phx_value)
        {:noreply, push_patch(socket, to: href)}
      end

      @impl true
      def handle_event("cartograph_patch", %{"query_opts" => query_opts}, socket) do
        uri = socket.assigns.cartograph_uri
        href = Cartograph.Component.parse_patch(uri, query: query_opts)
        {:noreply, push_patch(socket, to: href)}
      end

      @impl true
      def handle_event(
            "cartograph_navigate",
            %{"uri" => uri, "query_opts" => query_opts, "value" => phx_value},
            socket
          ) do
        href =
          Cartograph.Component.parse_navigate(URI.new!(uri),
            query: query_opts,
            phx_value: phx_value
          )

        {:noreply, push_navigate(socket, to: href)}
      end

      @impl true
      def handle_event("cartograph_navigate", %{"uri" => uri, "query_opts" => query_opts}, socket) do
        href = Cartograph.Component.parse_navigate(URI.new!(uri), query: query_opts)

        {:noreply, push_navigate(socket, to: href)}
      end

      @before_compile Cartograph.LiveViewParams
    end
  end

  defmacro __before_compile__(_env) do
    caller = __CALLER__.module

    cartograph_parsers =
      Module.get_attribute(caller, :cartograph_parser, [])
      |> Enum.map(fn kw -> Macro.escape(struct!(Cartograph.CartographParser, kw)) end)

    quote do
      defp run_parser(socket, params, %Cartograph.CartographParser{} = parser) do
        Enum.reduce(parser.keys, socket, &parser.handler.(&2, params, &1))
      end

      defp reduce_parsers(socket, params, []), do: socket

      defp reduce_parsers(socket, params, parsers) do
        Enum.reduce(parsers, socket, &run_parser(&2, params, &1))
      end

      defp parse_cartograph(params, uri, socket) do
        parsers = socket.assigns.__cartograph_parsers__

        updated_socket =
          socket
          |> reduce_parsers(params, parsers)
          |> assign(:cartograph_uri, URI.parse(uri))

        {:cont, updated_socket}
      end

      def on_mount(:cartograph, _params, _assigns, socket) do
        updated_socket =
          socket
          |> assign(:__cartograph_parsers__, unquote(cartograph_parsers))
          |> attach_hook(:cartograph_parser, :handle_params, &parse_cartograph/3)

        {:cont, updated_socket}
      end
    end
  end
end
