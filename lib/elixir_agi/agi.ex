defmodule ElixirAgi.Agi do
  @moduledoc """
  This module represents an AGI application

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
  require Logger
  alias ElixirAgi.Agi.Result
  alias ElixirAgi.Agi.Proto
  use GenServer

  defstruct \
    app_module: nil,
    app_state: nil,
    reader: nil,
    io_init: nil,
    io_close: nil,
    writer: nil,
    variables: %{}

  @type t :: ElixirAgi.Agi
  @typep state :: Map.t

  defmacro log(level, message) do
    quote do
      state = var! state
      Logger.unquote(level)("ElixirAgi AGI: #{unquote(message)}")
    end
  end

  @doc """
  Starts and link an AGI application.
  """
  @spec start_link(t) :: GenServer.on_start
  def start_link(info) do
    GenServer.start_link __MODULE__, info
  end

  @doc """
  Starts an AGI application.
  """
  @spec start(t) :: GenServer.on_start
  def start(info) do
    GenServer.start __MODULE__, info
  end

  @doc """
  Closes an AGI socket.
  """
  @spec close(GenServer.server) :: :ok
  def close(server) do
    GenServer.call server, :close
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_answer
  """
  @spec answer(GenServer.server) :: Result.t
  def answer(server) do
    run_generic server, :answer
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_hangup
  """
  @spec hangup(GenServer.server, String.t) :: Result.t
  def hangup(server, channel \\ "") do
    run_generic server, :hangup, [channel]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_set+variable
  """
  @spec set_variable(GenServer.server, String.t, String.t) :: Result.t
  def set_variable(server, name, value) do
    run_generic server, :set_variable, [name, value]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_get+full+variable
  """
  @spec get_full_variable(GenServer.server, String.t) :: Result.t
  def get_full_variable(server, name) do
    run_generic server, :get_full_variable, [name]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_Dial
  """
  @spec dial(
    GenServer.server, String.t, non_neg_integer(), [String.t]
  ) :: Result.t
  def dial(server, dial_string, timeout_seconds, options) do
    run_generic server, :dial, [dial_string, timeout_seconds, options]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_Wait
  """
  @spec wait(GenServer.server, non_neg_integer()) :: Result.t
  def wait(server, seconds) do
    run_generic server, :wait, [seconds]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_AMD
  """
  @spec amd(
    GenServer.server,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer,
    non_neg_integer
  ) :: Result.t | :eof
  def amd(
    server,
    initial_silence,
    greeting,
    after_greeting_silence,
    total_time,
    min_word_length,
    between_words_silence,
    max_words,
    silence_threshold,
    max_word_length
  ) do
    run_generic server, :amd, [
      initial_silence,
      greeting,
      after_greeting_silence,
      total_time,
      min_word_length,
      between_words_silence,
      max_words,
      silence_threshold,
      max_word_length
    ]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_exec
  """
  @spec exec(GenServer.server, String.t, [String.t]) :: Result.t
  def exec(server, application, args \\ []) do
    run_generic server, :exec, [application, args]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_stream+file
  """
  @spec stream_file(GenServer.server, String.t, String.t) :: Result.t
  def stream_file(server, file, escape_digits \\ "") do
    run_generic server, :stream_file, [file, escape_digits]
  end

  defp run_generic(server, command, args \\ []) do
    GenServer.call server, {:run_generic, command, args}, :infinity
  end

  @doc """
  GenServer callback
  """
  @spec init(t) :: {:ok, state}
  def init(info) do
    send self, :read_variables
    :ok = info.io_init.()
    {:ok, %{info: info}}
  end

  @doc """
  GenServer callback
  """
  @spec handle_call(term, term, state) ::
    {:noreply, state} | {:reply, term, state}
  def handle_call(:close, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_call({:run_generic, command, args}, _from, state) do
    case :erlang.apply(
      Proto, command, [state.info.reader, state.info.writer] ++ args
    ) do
      :eof -> {:stop, :normal, state}
      result -> {:reply, result, state}
    end
  end

  def handle_call(message, _from, state) do
    log :warn, "Unknown call: #{inspect message}"
    {:reply, :not_implemented, state}
  end

  @doc """
  GenServer callback
  """
  @spec handle_cast(term, state) :: {:noreply, state} | {:stop, :normal, state}
  def handle_cast(message, state) do
    log :warn, "Unknown cast: #{inspect message}"
    {:noreply, state}
  end

  @doc """
  GenServer callback
  """
  @spec handle_info(term, state) :: {:noreply, state}
  def handle_info(:read_variables, state) do
    case Proto.read_variables state.info.reader do
      :eof -> {:stop, :normal, state}
      vars ->
        log :debug, "Read variables: #{inspect vars}"
        {:ok, _} = :erlang.apply(
          state.info.app_module, :start_link, [self, state.info.app_state]
        )
        {:noreply, state}
    end
  end

  def handle_info(message, state) do
    log :warn, "Unknown message: #{inspect message}"
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
    log :info, "Terminating with: #{inspect reason}"
    :ok = state.info.io_close.()
    :ok
  end
end
