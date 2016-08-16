alias ElixirAgi.Agi

defmodule StdinStdoutAgi do
  def run(agi) do
    Agi.answer agi
    Agi.wait agi, 10
    Agi.hangup agi
  end
end

# Don't log to console
Logger.remove_backend :console
Application.ensure_all_started :elixir_agi
StdinStdoutAgi.run ElixirAgi.Agi.new
System.halt 0