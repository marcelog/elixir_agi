# AsyncAGI AGI Application

You can also use AsyncAGI if you setup a dialplan like:

```
[my_context]
exten => _X.,n,AGI(agi:asyncagi)
same => n, Hangup
```

And then in your elixir node, if you use [elixir_ami](https://github.com/marcelog/elixir_ami),
you can start a listener like:

```elixir
  ElixirAmi.Connection.async_agi(
    :my_connection,
    AsyncAgiApp,
    :run,
    true,                # debug = true/false
  )
```

This will start listening for [AsyncAGIStart](https://wiki.asterisk.org/wiki/display/AST/Asterisk+13+ManagerEvent_AsyncAGIStart) events
on the given connection and launch the AGI App with a spawned process:

```elixir
AsyncAgiApp.run(agi)
```

Where `agi` is an [agi struct](https://github.com/marcelog/elixir_agi/blob/master/lib/elixir_agi/agi.ex).

Note that this will listen for AsyncAGIStart events for **all channels**. You can specify a channel name with the
optional ending argument:

```elixir
ElixirAmi.Connection.async_agi :my_connection, TestAgiApp, %{}, "SIP/trunk-234132423"
```

