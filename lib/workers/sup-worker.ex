defmodule Cachets.Worker.Supervisor do
  use Supervisor
  @def_timeout Application.get_env(:cachets, :timeout)
  @worker_table_protection Application.get_env(:cachets, :worker_table_protection)
  import Cachets.Utils, only: [name_for_table: 1]

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Cachets.Worker, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def new_cache(name, opts) when is_bitstring(name) do
    table_name = name_for_table(name)
    via_name = {:via, Registry, {Cachets.Worker.Registry, name}}
    timeout = case opts[:timeout] do
      int when is_integer(int) -> int
      _ -> @def_timeout
    end
    protection = case opts[:protection] do
      atom when atom in ~w(protected public private)a -> atom
      _ -> @worker_table_protection
    end
    nil = GenServer.whereis(via_name)
    {:ok, _pid} = Supervisor.start_child(__MODULE__, [via_name, [table_name: table_name, protection: protection, timeout: timeout]])
    :ok
  end
  def new_cache(_, _), do: {:error, "name must be string"}

  def destroy_cache(name, opts) when is_bitstring(name) do
    via_name = {:via, Registry, {Cachets.Worker.Registry, name}}
    with_ets = case opts[:with_ets] do
      false -> false
      _ -> true
    end
    case GenServer.whereis(via_name) do
      nil -> {:error, "This cache is not exists"}
      pid -> ref = Process.monitor(pid)
             Cachets.Worker.stop(via_name, with_ets: with_ets)
             receive do
               {:DOWN, ^ref, :process, ^pid, :normal} -> :ok
             after
               5_000 -> {:error, "Can't stop cache #{inspect via_name}"}
             end
    end
  end
  def destroy_cache(_, _), do: {:error, "name must be string"}
end