defmodule ElixirAgi.Agi.Result do
  @moduledoc """
  This structure represents the result of the execution of an AGI command.

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
  defstruct code: nil,
            success: nil,
            result: nil,
            extra: nil

  @type t :: ElixirAgi.Agi.Result

  @doc """
  Given a read line, parses it and returns a structure with the result.
  """
  @spec new(String.t()) :: t
  def new(line) do
    [code, "result=" <> result | extra] = String.split(line, " ")
    {code, ""} = Integer.parse(code)

    %ElixirAgi.Agi.Result{
      code: code,
      success: code === 200,
      result: result,
      extra: extra
    }
  end
end
