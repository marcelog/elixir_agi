defmodule FastAgiApp do
  require Logger
  alias ElixirAgi.Agi

  def run(agi) do
    try do
      Agi.answer agi
      Agi.wait agi, 10
      Agi.hangup agi
      # When you're done, close the TCP communication to Asterisk.
    rescue
      Agi.HangupError ->
        Logger.info "Call terminated by caller"
        :ok
      e -> raise e
    end
    agi.close.()
  end
end