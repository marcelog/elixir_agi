defmodule ElixirAgi.Agi.Proto do
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

  @type reader :: function
  @type writer :: function

  defmacro log(level, message) do
    quote do
      Logger.unquote(level)("ElixirAgi AGI: #{unquote(message)}")
    end
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_answer
  """
  @spec answer(reader, writer) :: Result.t | :eof
  def answer(reader, writer) do
    exec reader, writer, "ANSWER"
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_hangup
  """
  @spec hangup(reader, writer, String.t) :: Result.t | :eof
  def hangup(reader, writer, channel \\ "") do
    exec reader, writer, "HANGUP", [channel]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_set+variable
  """
  @spec set_variable(reader, writer, String.t, String.t) :: Result.t | :eof
  def set_variable(reader, writer, name, value) do
    run reader, writer, "SET", ["VARIABLE", "#{name}", "#{value}"]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+AGICommand_get+full+variable
  """
  @spec get_full_variable(reader, writer, String.t) :: Result.t | :eof
  def get_full_variable(reader, writer, name) do
    case run reader, writer, "GET", ["FULL", "VARIABLE", "${#{name}}"] do
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
  @spec dial(
    reader, writer, String.t, non_neg_integer(), [String.t]
  ) :: Result.t | :eof
  def dial(reader, writer, dial_string, timeout_seconds, options) do
    exec reader, writer, "DIAL", [
      dial_string,
      to_string(timeout_seconds),
      Enum.join(options, ",")
    ]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/Application_Wait
  """
  @spec wait(reader, writer, non_neg_integer()) :: Result.t | :eof
  def wait(reader, writer, seconds) do
    exec reader, writer, "WAIT", [seconds]
  end

  @doc """
  See: https://wiki.asterisk.org/wiki/display/AST/AGICommand_exec
  """
  @spec exec(reader, writer, String.t, [String.t]) :: Result.t | :eof
  def exec(reader, writer, application, args \\ []) do
    run reader, writer, "EXEC", [application|args]
  end

  @spec run(reader, writer, String.t, [String.t]) :: Result.t | :eof
  def run(reader, writer, cmd, args) do
    args = for a <- args, do: ["\"", to_string(a), "\" "]
    cmd = ["\"", cmd, "\" "|args]
    :ok = write writer, cmd
    case read reader do
      :eof -> :eof
      line -> Result.new line
    end
  end

  @spec read_variables(reader, Map.t) :: Map.t | :eof
  def read_variables(reader, vars \\ %{}) do
    log :debug, "Reading next variable"
    line = read reader
    cond do
      line === :eof -> :eof
      String.length(line) < 2 -> vars
      true ->
        [k, v] = String.split line, ":", parts: 2
        vars = Map.put vars, String.strip(k), String.strip(v)
        read_variables reader, vars
    end
  end

  defp write(writer, data) do
    log :debug, "Writing #{data}"
    :ok = writer.([data, "\n"])
    :ok
  end

  defp read(reader) do
    line = reader.()
    {line, _} = String.split_at line, -1
    log :debug, "Read #{line}"
    case line do
      "HANGUP" <> _rest -> :eof
      _ -> line
    end
  end
end