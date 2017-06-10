defmodule Cachets do
  use Application
  @ets_preset [:set, :public, :named_table]
  defdelegate new_cache(name), to: Cachets.Worker.Supervisor

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :ets.new(Application.get_env(:cachets, :common_table), @ets_preset)

    children = [
      worker(Cachets.Common, [Application.get_env(:cachets, :common_genserver)]),
      supervisor(Cachets.Worker.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Cachets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def add(worker, key, value, opts \\ [])
  def add(worker, key, value, []), do: GenServer.cast(worker, {:add, key, value})
  def add(worker, key, value, opts), do: GenServer.cast(worker, {:add, key, value, opts})
end