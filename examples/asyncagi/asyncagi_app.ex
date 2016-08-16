defmodule AsyncAgiApp do
  alias ElixirAgi.Agi

  def run(agi) do
    Agi.answer agi
    Agi.wait agi, 10
    Agi.hangup agi
  end
end