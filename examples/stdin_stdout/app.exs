defmodule StdinStdoutAgi do
  alias ElixirAgi.Agi

  def run() do
    agi = Agi.new
    Agi.answer agi
    Agi.wait agi, 10
    Agi.hangup agi
  end
end

# Don't log to console
Logger.remove_backend :console
Application.ensure_all_started :elixir_agi
StdinStdoutAgi.run
System.halt 0