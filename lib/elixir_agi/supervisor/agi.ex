defmodule ElixirAgi.Supervisor.Agi do
  @moduledoc """
  AGI Application supervisor.

  Copyright 2015 Marcelo Gornstein <marcelog@gmail.com>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  """
  use Supervisor
  require Logger

  @doc """
  Starts the supervisor.
  """
  @spec start_link() :: Supervisor.on_start
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Starts a supervised AGI application.
  """
  @spec new(ElixirAgi.Agi.t) :: Supervisor.on_start_child
  def new(app_module) do
    Supervisor.start_child __MODULE__, [%{
      reader: fn() -> IO.gets "" end,
      writer: fn(data) -> IO.puts data end,
      io_init: fn() -> :ok end,
      io_close: fn() -> :ok end,
      app_module: app_module
    }]
  end

  @doc """
  Starts a supervised AGI application.
  """
  @spec new(ElixirAgi.Agi.t) :: Supervisor.on_start_child
  def new(app_module, io_init, reader, writer, io_close) do
    Supervisor.start_child __MODULE__, [%{
      reader: reader,
      writer: writer,
      io_init: io_init,
      io_close: io_close,
      app_module: app_module
    }]
  end

  @doc """
  Supervisor callback.
  """
  @spec init([]) :: {:ok, tuple}
  def init([]) do
    children = [
      worker(ElixirAgi.Agi, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end