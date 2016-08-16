# Standard AGI Application using STDIN and STDOUT

Setup a dialplan like:

```
[my_context]
exten => _X.,1,AGI(/path/to/elixir,-pa,/path/to/your/ebins,/path/to/app.exs)
same => n, Hangup
```
