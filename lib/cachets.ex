defmodule Cachets do
  use Application
  @common_genserver Application.get_env(:cachets, :common_genserver)
  @ets_preset [:set, :public, :named_table]
  defdelegate new_cache(name, opts \\ []), to: Cachets.Worker.Supervisor

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    :ets.new(Application.get_env(:cachets, :common_table), @ets_preset)

    children = [
      worker(Cachets.Common, [Application.get_env(:cachets, :common_genserver)]),
      supervisor(Cachets.Worker.Supervisor, []),
      supervisor(Registry, [:unique, Cachets.Worker.Registry])
    ]

    opts = [strategy: :one_for_one, name: Cachets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def via_tuple(name) do
    {:via, Registry, {Cachets.Worker.Registry, name}}
  end

  def add(worker, key, value, opts \\ []), do: GenServer.cast(via_tuple(worker), {:add, key, value, opts})
  def adds(key, value, opts \\ []), do: GenServer.cast(@common_genserver, {:add, key, value, opts})

  def get(worker, key, opts \\ []), do: GenServer.call(via_tuple(worker), {:get, key, opts})
  def gets(key, opts \\ []), do: GenServer.call(@common_genserver, {:get, key, opts})

  def delete(worker, key, opts \\ []), do: GenServer.cast(via_tuple(worker), {:delete, key, opts})
  def deletes(key, opts \\ []), do: GenServer.cast(@common_genserver, {:delete, key, opts})
end