defmodule Cartograph.Component do
  @moduledoc """
  This module provides functions for relative query patching and navigation event dispatching in templates.

  ## Examples

  ### Linkable Breadcrumbs

  ```elixir
    use Phoenix.Component
    import Cartograph.Component, only: [parse_patch: 2]

    attr :trail, :list, required: true
    attr :curr_uri, :string, required: true
    attr :id, :string, required: true

    def breadcrumbs(assigns) do
      ~H\"""
      <div id={@id}>
        <.link patch={
          parse_patch(@curr_uri, query: [remove: Enum.map(@trail, fn {p, _} -> p end)])
        }>
          Top
        </.link>
        <span>&nbsp;&gt;</span>
        <%= for {{query_param, display_label}, idx} <- Enum.with_index(@trail) do %>
          <span>
            <.link patch={
              parse_patch(@curr_uri,
                query: [
                  remove: Enum.slice(@trail, (idx + 1)..-1//1) |> Enum.map(fn {p, _} -> p end)
                ]
              )
            }>
              {display_label}
            </.link>
            <span>&nbsp;&gt;</span>
          </span>
        <% end %>
      </div>
      \"""
    end
  ```

  ### Old-School Pagination Widget

  ```elixir
    use Phoenix.Component
    import Cartograph.Component, only: [cartograph_patch: 1]

    defp compute_prev_page(page_no, page_count) do
      if page_no == 1 do
        page_count
      else
        page_no - 1
      end
    end

    defp compute_next_page(page_no, page_count) do
      if page_no == page_count do
        1
      else
        page_no + 1
      end
    end

    attr :page_no, :integer, required: true
    attr :page_count, :integer, required: true
    attr :id, :string, required: true

    def pagination(assigns) do
      ~H\"""
      <div id={@id}>
        <div>
          <button phx-click={
            cartograph_patch(
              query: [merge: %{page_no: compute_prev_page(@page_no, @page_count)}]
            )
          }>
            Prev
          </button>
          <p>Page {@page_no} of {@page_count}</p>
          <button phx-click={
            cartograph_patch(
              query: [merge: %{page_no: compute_next_page(@page_no, @page_count)}]
            )
          }>
            Next
          </button>
        </div>
        <div>
          <p>Jump to:</p>
          <input
            type="text"
            pattern="\d+"
            value={@page_no}
            phx-keydown={cartograph_patch(query: [merge: %{page_no: :phx_value}])}
            phx-key="Enter"
          />
        </div>
      </div>
      \"""
    end
  ```

  ### Simple Stateful Selectable

  ```elixir
    use Phoenix.Component
    import Cartograph.Component, only: [cartograph_patch: 1]

    attr :display_label, :string, required: true
    attr :choices, :list, required: true
    attr :selected, :string, required: true
    attr :query_param, :string, required: true
    attr :id, :string, required: true

    def generic_select(assigns) do
      ~H\"""
      <label for={@id}>{@display_label}</label>
      <select id={@id}>
        <option value="" phx-click={cartograph_patch(query: [remove: [@query_param]])}>
          No Selection
        </option>
        <%= for {value, display_text} <- @choices do %>
          <option
            value={value}
            selected={@selected == value}
            phx-click={cartograph_patch(query: [merge: %{@query_param => value}])}
          >
            {display_text}
          </option>
        <% end %>
      </select>
      \"""
    end
  ```

  ### Stateful Column Sort Button

  Cycles through no sort > ascending > descending > no sort

  ```elixir
    use Phoenix.Component
    import Cartograph.Component, only: [cartograph_patch: 1]

    defp sort_toggle(field_name, :asc = _curr_sort_order) do
      ops = [merge: %{"sort[]" => %{field_name <> "-asc" => field_name <> "-desc"}}]
      cartograph_patch(query: ops)
    end

    defp sort_toggle(field_name, :desc = _curr_sort_order) do
      cartograph_patch(query: [remove: %{"sort[]" => field_name <> "-desc"}])
    end

    defp sort_toggle(field_name, nil = _curr_sort_order) do
      cartograph_patch(query: [add: %{"sort[]" => field_name <> "-asc"}])
    end

    attr :display_text, :string, required: true
    attr :field_name, :string, required: true
    attr :sort_order, :atom, default: nil
    attr :sort_idx, :integer, default: nil

    def sort_button(assigns) do
      ~H\"""
      <button class="common-btn" phx-click={sort_toggle(@field_name, @sort_order)}>
        <span>{@display_text}</span>
        <Heroicons.icon :if={@sort_order == :desc} name="arrow-down" class="inline-icon" />
        <Heroicons.icon :if={@sort_order == :asc} name="arrow-up" class="inline-icon" />
        <span if={@sort_order != nil} class="text-sm">{@sort_idx}</span>
      </button>
      \"""
    end
  ```
  """

  alias Phoenix.LiveView.JS

  # TODO: Refactor the query parsing functions to reduce the cognitive complexity.

  @doc """
  Push a live patch event to the server with the href computed by relative query parsing.

  ## Options

    * `:query` - the query operations to apply, see: `t:query_opts/0`

      The special placeholder value `:phx_value` will be replaced by the current value
      of the input sending the event.
      - Example:
        - template: `<input type="number" phx-key="Enter" phx-keydown={cartograph_patch(query: [merge: %{"page_no" => :phx_value}])} />`
        - current uri: `/users?page_no=1`
        - user input: 4
        - resulting patch uri: `/users?page_no=4`

    * `:loading` - passed through to `Phoenix.LiveView.JS.push/2` as-is.
    * `:page_loading` - passed through to `Phoenix.LiveView.JS.push/2` as-is.
  """
  def cartograph_patch(opts \\ [])

  def cartograph_patch(opts) do
    query_opts = Keyword.get(opts, :query, [])

    push_value = %{"query_opts" => parse_query_opts(query_opts)}

    phx_opts = filter_phoenix_push_opts(opts)
    push_opts = Keyword.put(phx_opts, :value, push_value)

    JS.push("cartograph_patch", push_opts)
  end

  @doc """
  Push a live navigation event to the server with the href computed by relative query parsing.

  `uri` can be a `t:URI.t/0` struct or a string:
    - `cartograph_navigate(@cartograph_uri, query: [merge: %{page_no: 1}])`
    - `cartograph_navigate(~p"/users", query: [merge: %{page_no: 1}])`

  ## Options

    * `:query` - the query operations to apply, see: `t:query_opts/0`

      The special placeholder value `:phx_value` will be replaced by the current value
      of the input sending the event.
      - Example:
        - template: `<input type="number" phx-key="Enter" phx-keydown={cartograph_navigate(@current_uri, query: [merge: %{"page_no" => :phx_value}])} />`
        - current uri: `https://localhost:4000/users?page_no=1`
        - user input: 4
        - resulting navigate uri: `https://localhost:4000/users?page_no=4`

    * `:loading` - passed through to `Phoenix.LiveView.JS.push/2` as-is.
    * `:page_loading` - passed through to `Phoenix.LiveView.JS.push/2` as-is.
  """
  def cartograph_navigate(uri, opts \\ [])

  def cartograph_navigate(uri, opts) when is_binary(uri) do
    query_opts = Keyword.get(opts, :query, [])

    push_value = %{"uri" => uri, "query_opts" => parse_query_opts(query_opts)}

    phx_opts = filter_phoenix_push_opts(opts)
    push_opts = Keyword.put(phx_opts, :value, push_value)

    JS.push("cartograph_navigate", push_opts)
  end

  def cartograph_navigate(%URI{} = uri, opts) do
    query_opts = Keyword.get(opts, :query, [])
    cartograph_navigate(URI.to_string(uri), query_opts)
  end

  defp filter_phoenix_push_opts(opts) do
    Keyword.filter(opts, &(elem(&1, 0) in [:loading, :page_loading]))
  end

  @doc """
  Parses a new path suitable for use in a live patch operation from the provided `uri` and `opts`.

  `uri` can be a `t:URI.t/0` struct or a string:
    - `parse_patch(@cartograph_uri, query: [merge: %{page_no: 1}])`
    - `parse_patch(~p"/users", query: [merge: %{page_no: 1}])`

  ## Options

    * `:query` - the query operations to apply, see: `t:query_opts/0`
    * `:phx_value` - the value of this option will replace any ocurrences of `:phx_value`
      in the `:query` operations.
      - Example:
        - starting uri: `/users?page_no=1`
        - opts: `query: [merge: %{"page_no" => :phx_value}], phx_value: 2`
        - result: `/users?page_no=2`
  """
  def parse_patch(uri, opts \\ [])

  def parse_patch(uri, opts) when is_binary(uri) do
    parse_patch(URI.parse(uri), opts)
  end

  def parse_patch(%URI{} = uri, opts) do
    parsed_query = parse_query(uri, opts)

    uri_path =
      case uri.path do
        nil -> "/"
        p -> p
      end

    case parsed_query do
      "" -> uri_path
      query -> uri_path <> "?" <> query
    end
  end

  @doc """
  Parses a new URI suitable for use in a live navigation operation from the provided `uri` and `opts`.

  `uri` can be a `t:URI.t/0` struct or a string:
    - `parse_navigate(@cartograph_uri, query: [merge: %{page_no: 1}])`
    - `parse_navigate(~p"/users", query: [merge: %{page_no: 1}])`

  ## Options

    * `:query` - the query operations to apply, see: `t:query_opts/0`
    * `:phx_value` - the value of this option will replace any ocurrences of `:phx_value`
      in the `:query` operations.
      - Example:
        - starting uri: `https://localhost:4000/users?page_no=1`
        - opts: `query: [merge: %{"page_no" => :phx_value}], phx_value: 2`
        - result: `https://localhost:4000/users?page_no=2`
  """
  def parse_navigate(uri, opts \\ [])

  def parse_navigate(uri, opts) when is_binary(uri) do
    parse_navigate(URI.parse(uri), opts)
  end

  def parse_navigate(%URI{} = uri, opts) do
    parsed_query = parse_query(uri, opts)

    new_query =
      case parsed_query do
        "" -> nil
        q -> q
      end

    URI.to_string(%{uri | query: new_query})
  end

  defp parse_query_opts(query) when is_list(query) do
    Enum.map(query, fn
      {op, comp} when is_binary(op) ->
        [String.to_existing_atom(op), parse_query_component(String.to_existing_atom(op), comp)]

      {op, comp} when is_atom(op) ->
        [op, parse_query_component(op, comp)]

      [op, comp] when is_binary(op) ->
        [String.to_existing_atom(op), parse_query_component(String.to_existing_atom(op), comp)]

      [op, comp] when is_atom(op) ->
        [op, parse_query_component(op, comp)]
    end)
  end

  defp parse_query_opts(query) do
    raise ArgumentError, "query_opts must be a keyword list, got: #{inspect(query)}"
  end

  defp parse_query(%URI{} = uri, opts) do
    query_opts = Keyword.get(opts, :query, [])
    phx_value = Keyword.get(opts, :phx_value, "")

    query_items = parse_uri_query(uri)

    query_opts
    |> parse_query_opts()
    |> Enum.reduce(query_items, &parse_query_op/2)
    |> Enum.reverse()
    |> Enum.map(fn
      [k, v] -> Enum.join([k, v], "=")
      {k, v} -> Enum.join([k, v], "=")
    end)
    |> Enum.join("&")
    |> String.replace("phx_value", phx_value)
    |> URI.encode(&URI.char_unescaped?/1)
  end

  defp parse_query_op([:add, instructions], query_items) when is_list(query_items) do
    Enum.reduce(instructions, query_items, &process_add_instruction/2)
  end

  defp parse_query_op([:toggle, instructions], query_items) when is_list(query_items) do
    Enum.reduce(instructions, query_items, &process_toggle_instruction/2)
  end

  defp parse_query_op([:set, instructions], query_items) when is_list(query_items) do
    # Pass an empty list for the initializer to reset the full query.
    Enum.reduce(instructions, [], &process_set_instruction/2)
  end

  defp parse_query_op([:merge, instructions], query_items) when is_list(query_items) do
    Enum.reduce(instructions, query_items, &process_merge_instruction/2)
  end

  defp parse_query_op([:remove, instructions], query_items) when is_list(query_items) do
    Enum.reduce(instructions, query_items, &process_remove_instruction/2)
  end

  defp process_add_instruction({k, v}, query_items) when is_list(v) and is_list(query_items) do
    Enum.reduce(v, query_items, &process_add_instruction({k, &1}, &2))
  end

  defp process_add_instruction({k, v}, query_items) when is_binary(v) and is_list(query_items) do
    [{k, v} | query_items]
  end

  defp process_toggle_instruction({k, v}, query_items) when is_list(v) and is_list(query_items) do
    Enum.reduce(v, query_items, &process_toggle_instruction({k, &1}, &2))
  end

  defp process_toggle_instruction({k, v}, query_items) when is_binary(v) and is_list(query_items) do
    if Enum.member?(query_items, {k, v}) do
      Enum.filter(query_items, &(&1 != {k, v}))
    else
      [{k, v} | query_items]
    end
  end

  defp process_set_instruction({k, v}, query_items) when is_list(v) and is_list(query_items) do
    filtered = filter_query_key(query_items, k)
    Enum.reduce(v, filtered, &[{k, &1} | &2])
  end

  defp process_set_instruction({k, v}, query_items) when is_binary(v) and is_list(query_items) do
    filtered = filter_query_key(query_items, k)
    [{k, v} | filtered]
  end

  defp merge_replace(replace_map, query_value) do
    case Map.get(replace_map, query_value, nil) do
      nil -> query_value
      replace_value -> replace_value
    end
  end

  defp process_merge_instruction({k, v}, query_items) when is_map(v) and is_list(query_items) do
    Enum.map(query_items, fn
      {^k = qk, qv} -> {qk, merge_replace(v, qv)}
      {qk, qv} -> {qk, qv}
    end)
  end

  defp process_merge_instruction({k, v}, query_items) when is_list(v) and is_list(query_items) do
    filtered = filter_query_key(query_items, k)
    Enum.reduce(v, filtered, &[{k, &1} | &2])
  end

  defp process_merge_instruction({k, v}, query_items) when is_binary(v) and is_list(query_items) do
    filtered = filter_query_key(query_items, k)
    [{k, v} | filtered]
  end

  defp process_remove_instruction({k, v}, query_items) when is_list(v) and is_list(query_items) do
    Enum.reduce(v, query_items, &filter_query_key_value(&2, k, &1))
  end

  defp process_remove_instruction({k, v}, query_items) when is_binary(v) and is_list(query_items) do
    filter_query_key_value(query_items, k, v)
  end

  defp process_remove_instruction(k, query_items) when is_list(query_items) do
    filter_query_key(query_items, k)
  end

  defp filter_query_key(query_items, k) when is_list(query_items) do
    Enum.filter(query_items, fn {qk, _qv} -> qk != k end)
  end

  defp filter_query_key_value(query_items, k, v) when is_list(query_items) do
    Enum.filter(query_items, fn {qk, qv} -> qk != k or qv != v end)
  end

  defp parse_query_component(:remove = op, comp) when is_list(comp) do
    Enum.map(comp, fn
      k when op == :remove -> parse_query_key(op, k)
      _ -> bad_query_option_value(op, comp)
    end)
  end

  defp parse_query_component(op, comp) when is_map(comp) do
    comp
    |> Enum.map(&parse_query_key_value(op, &1))
    |> Map.new()
  end

  defp parse_query_component(op, comp), do: bad_query_option_value(op, comp)

  defp bad_query_option_value(:remove, comp) do
    raise ArgumentError, ":remove must be a map or list, got: #{inspect(comp)}"
  end

  defp bad_query_option_value(op, comp) do
    raise ArgumentError, "#{inspect(op)} must be a map, got: #{inspect(comp)}"
  end

  defp parse_query_key(:remove, k) when is_list(k) do
    raise ArgumentError, ":remove list elements must be string or atom keys, got: #{inspect(k)}"
  end

  defp parse_query_key(:remove, k), do: encode_value(k)

  defp parse_query_key(op, k) do
    raise ArgumentError, "#{inspect(op)} must be a map, got: #{inspect(k)}"
  end

  defp parse_query_key_value(:merge = _op, {k, v}) when is_map(v) do
    mapped_value =
      v
      |> Enum.map(fn {mk, mv} -> {encode_value(mk), encode_value(mv)} end)
      |> Map.new()

    {encode_value(k), mapped_value}
  end

  defp parse_query_key_value(_op, {k, v}) when is_list(v) do
    {encode_value(k), Enum.map(v, &encode_value/1)}
  end

  defp parse_query_key_value(_op, {k, v}), do: {encode_value(k), encode_value(v)}

  defp parse_query_key_value(op, k) do
    raise ArgumentError, "#{inspect(op)} - bad query option value #{inspect(k)}"
  end

  defp parse_uri_query(%URI{} = uri) do
    case uri.query do
      nil -> []
      query -> decode_uri_query(query)
    end
  end

  defp decode_uri_query(query) do
    query
    |> URI.query_decoder(:rfc3986)
    |> Enum.to_list()
    |> Enum.reverse()
  end

  defp encode_value(qv), do: to_string(qv)

  @typedoc """
    A keyword list representing the query patching operations to apply to an existing URI.

    Unless otherwise specified in the specific option section, the values of the keyword items should be maps. Keys and values of the maps can be atoms or strings. Values can also be lists of atoms or strings in which case, the resulting query string will have one ocurrence of that key for each value in the list.

    The operations are applied cumulatively in the order the keywords are provided, so the behavior of any arbitrary combination of operations is well-defined.

    Providing a list as a value in the map will set multiple values for that key in the resulting query string.
    For example, given the map `%{selected_role: [:admin, :member]}`, this would be parsed out to: `?selected_role=admin&selected_role=member` in the resulting query string. The exact semantics for how these values get applied depends on the operation being used.

  ## Valid Options

    * `:set` - replaces the whole query relative to the current document with the key-value pairs provided.
      - Example with single-values:
        - base query: `?foo=bar`
        - operation: `query: [set: %{bar: :baz}]`
        - result: `?bar=baz`
      - Example with multi-values:
        - base query: `?foo=bar`
        - operation: `query: [set: %{bar: [:baz, :qux]}]`
        - result: `?bar=baz&bar=qux`

    * `:add` - appends the provided key-value pairs into the query string without checking for existing keys. This can create duplicates, which is needed for array-valued params.
      - Example with single-values:
        - base query: `?foo=bar`
        - operation: `query: [add: %{foo: :baz, bar: :baz}]`
        - result: `?foo=bar&foo=baz&bar=baz`
      - Example with multi-values:
        - base query: `?foo=bar`
        - operation: `query: [add: %{foo: [:baz, :qux], bar: :baz}]`
        - result: `?foo=bar&foo=baz&foo=qux&bar=baz`

    * `:merge` - the same as `:add` but replaces existing keys instead of appending duplicates.

      This option allows specifying a map as the value of a key in the top-level key-value map.
      If a regular scalar or list is provided as the value of the key, then all ocurrences of that key are removed and the provided values are added at the end of the query string.
      If a map is provided as the value for a key, it is used to match values to replace in-place for the corresponding key, so only params with matching values are removed and order of params is preserved.
      - Example with single-values:
        - base query: `?foo=bar`
        - operation: `query: [merge: %{foo: :baz, bar: :baz}]`
        - result: `?foo=baz&bar=baz`
      - Example with multi-values:
        - base query: `?foo=bar&bar=baz`
        - operation: `query: [merge: %{foo: [:baz, :qux], lorem: :ipsum}]`
        - result: `?bar=baz&foo=baz&foo=qux&lorem=ipsum`
      - Example with nested map-values:
        - base query: `?foo=bar&foo=baz&foo=spam&bar=baz`
        - operation: `query: [merge: %{foo: %{"spam" => :eggs, baz: "qux"}}]`
        - result: `?foo=bar&foo=qux&foo=eggs&bar=baz`

    * `:remove` - The opposite of `:add`. Removes matching keys.

      This option allows passing a list of keys instead of a map of key-value pairs.
      If a list of keys is provided, all ocurrences of the matched keys will be removed from the query string regardless of their value.
      If a map is provided, only the ocurrences of each key that have a matching value will be removed.
      - Example with keys only:
        - base query: `?foo=bar&foo=baz&bar=baz`
        - operation: `query: [remove: [:foo]]`
        - result: `?bar=baz`
      - Example with map single-values:
        - base query: `?foo=bar&foo=baz&bar=baz`
        - operation: `query: [remove: %{foo: :baz}]`
        - result: `?foo=bar&bar=baz`
      - Example with map multi-values:
        - base query: `?foo=bar&foo=baz&foo=qux&bar=baz`
        - operation: `query: [remove: %{foo: [:baz, :qux]}]`
        - result: `?foo=bar&bar=baz`

    * `:toggle` - toggles the provided key-value pairs into or out of the query string.

      This operation has the semantics of `:add` for any key-value pairs not in the current query
      and `:remove` for any that are in the current query.
      - Example with single-values:
        - base query: `?foo=bar`
        - operation: `query: [toggle: %{foo: :bar, bar: :baz}]`
        - result: `?bar=baz`
      - Example with multi-values:
        - base query: `?foo=bar`
        - operation: `query: [toggle: %{foo: [:bar, :baz], bar: :baz}]`
        - result: `?foo=baz&bar=baz`
  """
  @type query_opts() :: Keyword.t()
end
