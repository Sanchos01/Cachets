defmodule Cachets.Supervisor do
  use Supervisor
  @common_genserver Application.get_env(:cachets, :common_genserver)
  @common_table Application.get_env(:cachets, :common_table)
  defdelegate new_cache(name, opts \\ []), to: Cachets.Worker.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      supervisor(Cachets.Worker.Supervisor, []),
      supervisor(Registry, [:unique, Cachets.Worker.Registry]),
      worker(Cachets.Common, [@common_genserver])
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)    
  end

  def handle_info {:"ETS-TRANSFER", table_name, pid, "transfered from worker"}, state: state do
    receive do
      {:return_table, ^pid} -> :ets.give_away(table_name, pid, "return back worker-table")
    after
      5_000 -> :ok
    end
  end
  def handle_info {:"ETS-TRANSFER", @common_table, pid, "transfered from common"}, state: state do
    receive do
      {:return_table, ^pid} -> :ets.give_away(@common_table, pid, "return back common-table")
    after
      5_000 -> :ok
    end
  end
end