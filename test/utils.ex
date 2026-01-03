defmodule Test.Utils do
  require ExUnit.Assertions

  defmacro assert_does_not_raise(expression) do
    quote do
      try do
        unquote(expression)
      rescue
        e -> assert false, "Raised exception: #{inspect(e)}"
      end
    end
  end
end
