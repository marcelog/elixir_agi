defmodule ElixirAgi.Supervisor.FastAgi do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def new(app_module, name, host, port) do
    Supervisor.start_child __MODULE__, [%{
      name: name, host: host, port: port, app_module: app_module
    }]
  end

  def init([]) do
    children = [
      worker(ElixirAgi.FastAgi, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end