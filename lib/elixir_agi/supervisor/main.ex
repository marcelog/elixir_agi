defmodule ElixirAgi.Supervisor.Main do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      supervisor(ElixirAgi.Supervisor.Agi, [], [
        restart: :permanent,
        shutdown: :infinity
      ]),
      supervisor(ElixirAgi.Supervisor.FastAgi, [], [
        restart: :permanent,
        shutdown: :infinity
      ])
    ]

    supervise(children, strategy: :one_for_one)
  end
end