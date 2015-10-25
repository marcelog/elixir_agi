defmodule ElixirAgi.Agi do
  use GenServer
  require Logger
  defstruct \
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
      Logger.unquote(level)("AGI: #{unquote(message)}")
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
  def handle_call(message, _from, state) do
    log :warn, "unknown call: #{inspect message}"
    {:reply, :not_implemented, state}
  end

  @doc """
  GenServer callback
  """
  @spec handle_cast(term, state) :: {:noreply, state} | {:stop, :normal, state}
  def handle_cast(message, state) do
    log :warn, "unknown cast: #{inspect message}"
    {:noreply, state}
  end

  @doc """
  GenServer callback
  """
  @spec handle_info(term, state) :: {:noreply, state}
  def handle_info(:read_variables, state) do
    case read_variables state.info.reader do
      :eof -> {:stop, :normal, state}
      vars ->
        log :debug, "read variables: #{inspect vars}"
        {:noreply, state}
    end
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
    :ok = state.info.io_close.()
    :ok
  end

  defp read_variables(reader, vars \\ %{}) do
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

  defp read(reader) do
    line = reader.()
    {line, _} = String.split_at line, -1
    Logger.debug "AGI: read #{line}"
    case line do
      "HANGUP" <> _rest -> :eof
      _ -> line
    end
  end
end
