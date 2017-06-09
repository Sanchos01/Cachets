defmodule Cachets do
  use Application
  @ets_preset [:set, :public, :named_table]

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :ets.new(Application.get_env(:cachets, :common_table), @ets_preset)

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Cachets.Worker, [arg1, arg2, arg3]),
      worker(Cachets.Common, [Application.get_env(:cachets, :common_genserver)])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cachets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def nowstamp do
    with {a,b,c} <- :os.timestamp,
      do: a * 1000000000 + b * 1000 + div(c, 1000)
  end

  def new_cache(name) do
    import Supervisor.Spec, warn: false
    with nil <- GenServer.whereis(name),
         {:ok, _pid} <- Supervisor.start_child(Cachets.Supervisor, worker(Cachets.Worker, [name])),
         _ets <- :ets.new(name, @ets_preset),
         do: :ok
  end
end