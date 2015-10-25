defmodule ElixirAgi.Supervisor.Agi do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def new(io_init, reader, writer, io_close) do
    Supervisor.start_child __MODULE__, [%{
      reader: reader,
      writer: writer,
      io_init: io_init,
      io_close: io_close
    }]
  end

  def init([]) do
    children = [
      worker(ElixirAgi.Agi, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end