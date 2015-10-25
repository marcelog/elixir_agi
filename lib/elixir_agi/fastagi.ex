defmodule ElixirAgi.FastAgi do
  @moduledoc """
  FastAGI server used to listen for connections and launching an AGI
  application for every connection.

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
  alias ElixirAgi.Supervisor.Agi, as: Sup
  use GenServer
  require Logger
  defstruct \
    name: nil,
    host: nil,
    port: nil,
    app_module: nil

  @type t :: ElixirAgi.FastAgi
  @typep state :: Map.t

  defmacro log(level, message) do
    quote do
      state = var! state
      Logger.unquote(level)("FastAGI: #{state.info.name} #{unquote(message)}")
    end
  end

  @doc """
  Starts and link a FastAGI server.
  """
  @spec start_link(t) :: GenServer.on_start
  def start_link(info) do
    GenServer.start_link __MODULE__, info, name: info.name
  end

  @doc """
  Starts a FastAGI server.
  """
  @spec start(t) :: GenServer.on_start
  def start(info) do
    GenServer.start __MODULE__, info, name: info.name
  end

  @doc """
  Closes a FastAGI server.
  """
  @spec close(GenServer.server) :: :ok
  def close(server) do
    GenServer.cast server, :close
  end

  @doc """
  GenServer callback
  """
  @spec init(t) :: {:ok, state}
  def init(info) do
    case :inet.parse_ipv4_address to_char_list(info.host) do
      {:ok, address} ->
        case :gen_tcp.listen(info.port, [
          :binary, {:ip, address}, {:port, info.port},
          :inet, {:active, :false}, {:packet, :line}, {:reuseaddr, true}
        ]) do
          {:ok, socket} ->
            send self, :accept
            {:ok, %{
              clients: [],
              info: info,
              socket: socket
            }}
          {:error, e} -> {:stop, e}
        end
      {:error, e} -> {:stop, e}
    end
  end

  @doc """
  GenServer callback
  """
  @spec handle_call(term, term, state) ::
    {:noreply, state} | {:reply, term, state}
  def handle_call(message, _from, state) do
    log :warn, "unknown call: #{inspect message}"
    {:reply, :not_implemented, state}
  end

  @doc """
  GenServer callback
  """
  @spec handle_cast(term, state) :: {:noreply, state} | {:stop, :normal, state}
  def handle_cast(:close, state) do
    log :info, "shutting down"
    {:stop, :normal, state}
  end

  def handle_cast(message, state) do
    log :warn, "unknown cast: #{inspect message}"
    {:noreply, state}
  end

  @doc """
  GenServer callback
  """
  @spec handle_info(term, state) :: {:noreply, state}
  def handle_info(:accept, state) do
    state = case :gen_tcp.accept state.socket, 50 do
      {:ok, socket} ->
        {:ok, {address, port}} = :inet.peername socket
        ip = :inet.ntoa address
        log :debug, "accepted new connection from: #{ip}:#{port}"

        io_init = fn() ->
          :inet.setopts socket, [{:active, false}, {:packet, :line}, :binary]
          :gen_tcp.controlling_process socket, self
          :ok
        end

        reader = fn() ->
          {:ok, read_data} = :gen_tcp.recv socket, 0
          read_data
        end

        writer = fn(write_data) ->
          :ok = :gen_tcp.send socket, write_data
        end

        io_close = fn() ->
          :ok = :gen_tcp.close socket
        end

        {:ok, _} = Sup.new(
          state.info.app_module, io_init, reader, writer, io_close
        )
        state
      {:error, :timeout} ->
        send self, :accept
        state
      {:error, e} ->
        log :error, "could not accept socket: #{inspect e}"
        state
    end
    {:noreply, state}
  end

  def handle_info(message, state) do
    log :warn, "unknown message: #{inspect message}"
    {:noreply, state}
  end

  @doc """
  GenServer callback
  """
  @spec code_change(term, state, term) :: {:ok, state}
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @doc """
  GenServer callback
  """
  @spec terminate(term, state) :: :ok
  def terminate(reason, state) do
    log :info, "terminating with: #{inspect reason}"
    :ok
  end
end
