defmodule Cachets.Saver do
  use ExActor.GenServer
  require Logger
  @common_table Application.get_env(:cachets, :common_table)

  defstart start_link, links: true, gen_server_opts: [name: __MODULE__] do
    initial_state([])
  end

  defhandleinfo {:"ETS-TRANSFER", table_name, _pid, "transfered from worker"} do
    Logger.debug("got table from worker")
    receive do
      {:return_table_for_worker, pid} -> :ets.give_away(table_name, pid, "return back worker_table")
                                         noreply
    after
      100 -> noreply
    end
  end

  defhandleinfo {:"ETS-TRANSFER", @common_table, _pid, "transfered from common"} do
    Logger.debug("got table from common")
    receive do
      {:return_table_for_common, pid} -> :ets.give_away(@common_table, pid, "return back common_table")
                                         noreply
    after
      100 -> noreply
    end
  end

  defhandleinfo {:"ETS-TRANSFER", _table, _pid, _msg} do
    noreply
  end

  defhandleinfo msg, do: (Logger.debug("Unpredicted msg: #{inspect msg}, for Saver}"); noreply)
end