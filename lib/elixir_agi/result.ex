defmodule ElixirAgi.Agi.Result do
  defstruct \
    code: nil,
    success: nil,
    result: nil,
    extra: nil

  @type t :: ElixirAgi.Agi.Result

  def new(line) do
    [code, "result=" <> result|extra] = String.split line, " "
    {code, ""} = Integer.parse code
    %ElixirAgi.Agi.Result{
      code: code,
      success: (code === 200),
      result: result,
      extra: extra
    }
  end
end