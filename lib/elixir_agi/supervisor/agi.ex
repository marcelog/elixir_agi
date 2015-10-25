defmodule ElixirAgi.Supervisor.Agi do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def new(app_module) do
    Supervisor.start_child __MODULE__, [%{
      reader: fn() -> IO.gets "" end,
      writer: fn(data) -> IO.puts data end,
      io_init: fn() -> :ok end,
      io_close: fn() -> :ok end,
      app_module: app_module
    }]
  end

  def new(app_module, io_init, reader, writer, io_close) do
    Supervisor.start_child __MODULE__, [%{
      reader: reader,
      writer: writer,
      io_init: io_init,
      io_close: io_close,
      app_module: app_module
    }]
  end

  def init([]) do
    children = [
      worker(ElixirAgi.Agi, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end