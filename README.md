# ElixirAgi

An [Asterisk](http://www.asterisk.org/) client for the [AGI](https://wiki.asterisk.org/wiki/display/AST/AGI+Commands)
protocol written in [Elixir](http://elixir-lang.org/). For a quick introduction to AGI you can read [this](http://marcelog.github.io/articles/php_asterisk_agi_protocol_tutorial.html).

This is similar to [PAGI](https://github.com/marcelog/PAGI) for PHP, and
[erlagi](https://github.com/marcelog/erlagi) for Erlang.

----

# Using it with Mix

To use it in your Mix projects, first add it as a dependency:

```elixir
def deps do
  [{:elixir_agi, "~> 0.0.1"}]
end
```
Then run mix deps.get to install it.

Also add the app in your mix.exs file:
```elixir
  [
    applications: [:logger, :elixir_agi],
    ...
  ]
```

----

# FastAGI

elixir_erlagi provides a FastAGI server, so you can run your AGI applications
through TCP in a different host, providing scalability. To use it, you have to
setup in your dialplan something like this:

```
[dialer]
exten => _X.,1,Answer
exten => _X.,n,AGI(agi://192.168.1.22:4444)
```

And then in your elixir node, you can start the listener like this:

```elixir
  ElixirAgi.Supervisor.FastAgi.new MyAppModule, :my_server_name, "0.0.0.0", 4444
```

`MyAppModule` must have a `start_link` function, and must return `{:ok, pid}` so
it will be linked to the AGI process that is handling the connection.

----

# Sample AGI Application

```
defmodule MyAppModule do
  use GenServer
  alias ElixirAgi.Agi, as: Agi
  require Logger

  def start_link(agi) do
    GenServer.start_link __MODULE__, agi
  end

  def init(agi) do
    {:ok, %{agi: agi}, 0}
  end

  def handle_info(:timeout, state) do
    Logger.debug "Starting APP"
    Logger.debug "AA: #{inspect Agi.answer(state.agi)}"
    :timer.sleep 1000
    Logger.debug "AA: #{inspect Agi.hangup(state.agi)}"
    Agi.close state.agi
    {:noreply, state}
  end

end
```

----

# AGI Commands

You can find the available AGI commands in the [AGI](https://github.com/marcelog/elixir_agi/blob/master/lib/elixir_agi/agi.ex) module.
Feel free to open a pull request to include new ones :) If you want to use a command that is not supported yet, you can
use the `exec/3` function of the AGI module.

----

# Documentation

Feel free to take a look at the [documentation](http://hexdocs.pm/elixir_agi/)
served by hex.pm or the source itself to find more.

----

# License
The source code is released under Apache 2 License.

Check [LICENSE](https://github.com/marcelog/elixir_agi/blob/master/LICENSE) file for more information.

----
