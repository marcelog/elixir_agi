# FastAGI AGI Application

elixir_erlagi provides a FastAGI server, so you can run your AGI applications
through TCP in a different host, providing scalability. To use it, you have to
setup in your dialplan something like this:

```
[my_context]
exten => _X.,n,AGI(agi://127.0.0.1:4444)
same => n, Hangup
```

And then in your elixir node, you can start the listener like this:

```elixir
  ElixirAgi.Supervisor.FastAgi.new(
    MyAppModule,
    :my_function,
    :my_server_name,
    "0.0.0.0",
    4444,
    10
  )
```

For every incoming connection a process will be spawned that will call
```elixir
MyAppModule:my_function(agi)
```

Where `agi` is an [agi struct](https://github.com/marcelog/elixir_agi/blob/master/lib/elixir_agi/agi.ex).
