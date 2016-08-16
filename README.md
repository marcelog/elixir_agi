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
  [{:elixir_agi, "~> 0.0.10"}]
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

# Examples
See the [examples directory](https://github.com/marcelog/elixir_agi/tree/master/examples)

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
