defmodule ElixirAgi.Agi do
  @moduledoc """
  This module handles the AGI implementation by reading and writing to/from
  the source.

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

  defstruct \
    reader: nil,
    writer: nil,
    variables: %{}

  @type t :: ElixirAgi.Agi
  @typep state :: Map.t
  @type reader :: function
  @type writer :: function

  defmacro log(level, message) do
    quote do
      Logger.unquote(level)("ElixirAgi AGI: #{unquote(message)}")
    end
  end

  @doc """
  Returns an AGI struct that uses STDIN and STDOUT.
  """
  @spec new() :: t
  def new() do
    new fn() -> IO.gets "" end, fn(data) -> IO.puts data en
  end

  @doc """
  Returns an AGI struct.
  """
  @spec new(reader, writer) :: t
  def new(reader, writer) do
    %{
      reader: reader,
      writer: writer,
      variable: read_variables(reader)
    }
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_answer
  """
  @spec answer(t) :: Result.t | :eof
  def answer(agi) do
    exec ragi, "ANSWER"
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_hangup
  """
  @spec hangup(t, String.t) :: Result.t | :eof
  def hangup(agi, channel \\ "") do
    exec agi, "HANGUP", [channel]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_set+variable
  """
  @spec set_variable(t, String.t, String.t) :: Result.t | :eof
  def set_variable(agi, name, value) do
    run agi, "SET", ["VARIABLE", "#{name}", "#{value}"]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_get+full+variable
  """
  @spec get_full_variable(t, String.t) :: Result.t | :eof
  def get_full_variable(agi, name) do
    case run agi, "GET", ["FULL", "VARIABLE", "${#{name}}"] do
      :eof -> :eof
      result -> if result.result === "1" do
        [_, var] = Regex.run ~r/\(([^\)]*)\)/, hd(result.extra)
        %Result{result | extra: var}
      else
        %Result{result | extra: nil}
      end
    end
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_Dial
  """
  @spec dial(t, String.t, non_neg_integer(), [String.t]) :: Result.t | :eof
  def dial(agi, dial_string, timeout_seconds, options) do
    exec agi, "DIAL", [
      dial_string,
      to_string(timeout_seconds),
      Enum.join(options, ",")
    ]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_Wait
  """
  @spec wait(t, non_neg_integer()) :: Result.t | :eof
  def wait(agi, seconds) do
    exec agi, "WAIT", [seconds]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_AMD
  """
  @spec amd(
    t,
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
    agi,
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
    exec agi, "AMD", [
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
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_stream+file
  """
  @spec stream_file(t, String.t, String.t) :: Result.t | :eof
  def stream_file(agi, file, escape_digits \\ "") do
    run agi, "STREAM", ["FILE", file, escape_digits]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_exec
  """
  @spec exec(t, String.t, [String.t]) :: Result.t | :eof
  def exec(agi, application, args \\ []) do
    run agi, "EXEC", [application|args]
  end

  @spec run(t, String.t, [String.t]) :: Result.t | :eof
  def run(agi, cmd, args) do
    args = for a <- args, do: ["\"", to_string(a), "\" "]
    cmd = ["\"", cmd, "\" "|args]
    :ok = write agi, cmd
    case read agi do
      :eof -> :eof
      line -> Result.new line
    end
  end

  @spec read_variables(t, Map.t) :: Map.t | :eof
  def read_variables(agi, vars \\ %{}) do
    log :debug, "Reading next variable"
    line = read agi.reader
    cond do
      line === :eof -> :eof
      String.length(line) < 2 -> vars
      true ->
        [k, v] = String.split line, ":", parts: 2
        vars = Map.put vars, String.strip(k), String.strip(v)
        read_variables agi, vars
    end
  end

  defp write(agi, data) do
    log :debug, "Writing #{data}"
    :ok = agi.writer.([data, "\n"])
    :ok
  end

  defp read(agi) do
    line = agi.reader.()
    {line, _} = String.split_at line, -1
    log :debug, "Read #{line}"
    case line do
      "HANGUP" <> _rest -> :eof
      _ -> line
    end
  end
end