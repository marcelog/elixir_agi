defmodule AsyncAgiApp do
  alias ElixirAgi.Agi

  def run(agi) do
    Agi.answer agi
    Agi.wait agi, 10
    Agi.hangup agi
    # When you're done, close the TCP communication to Asterisk.
    agi.close.()
  end
end