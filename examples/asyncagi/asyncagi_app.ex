defmodule AsyncAgiApp do
  alias ElixirAgi.Agi

  def run(agi) do
    try do
      Agi.answer agi
      Agi.wait agi, 10
      Agi.hangup agi
    rescue
      Agi.HangupError ->
        Logger.info "Call terminated by caller"
        :ok
      e -> raise e
    end
  end
end