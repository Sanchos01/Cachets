defmodule Cachets.Saver do
  use ExActor.GenServer
  require Logger
  @common_table Application.get_env(:cachets, :common_table)

  def start_link(name, opts \\ [])
  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    initial_state([])
  end

  def handle_info {:"ETS-TRANSFER", table_name, _pid, "transfered from worker"}, state do
    Logger.debug("got table from worker")
    receive do
      {:return_table_for_worker, pid} -> :ets.give_away(table_name, pid, "return back worker_table")
                                         {:noreply, state}
    after
      100 -> {:noreply, state}
    end
  end
  def handle_info {:"ETS-TRANSFER", @common_table, _pid, "transfered from common"}, state do
    Logger.debug("got table from common")
    receive do
      {:return_table_for_common, pid} -> :ets.give_away(@common_table, pid, "return back common_table")
                                         {:noreply, state}
    after
      100 -> {:noreply, state}
    end
  end
  def handle_info {:"ETS-TRANSFER", _table, _pid, _msg}, state do
    {:noreply, state}
  end

  def handle_info(msg, state), do: (Logger.debug("Unpredicted msg: #{inspect msg}, for Saver}"); {:noreply, state})
end