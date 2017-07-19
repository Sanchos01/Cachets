defmodule Cachets.Common do
  require Logger
  use ExActor.GenServer
  @table Application.get_env(:cachets, :common_table)
  @common_table Application.get_env(:cachets, :common_table)
  @common_table_protection Application.get_env(:cachets, :common_table_protection) || :protected
  @ets_preset [:set, :named_table]
  import Cachets.Utils, only: [nowstamp: 0]

  def start_link(name, opts \\ [])
  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    saver_pid = GenServer.whereis(:'Elixir.Cachets.Saver')
    try do
      :ets.new(@common_table, [@common_table_protection|[{:heir, saver_pid, "transfered from common"}|@ets_preset]])
    rescue
      _error in ArgumentError ->
        case :ets.info(@common_table)[:owner] do
          ^saver_pid ->
            send saver_pid, {:return_table_for_common, self()}
            receive do
              {:"ETS-TRANSFER", @common_table, ^saver_pid, "return back common_table"} -> :ok
            after
              300 -> Logger.error("Table not exists"); raise "Table with such name already exists"
            end
          _another_pid -> raise "Table with such name already exists"
        end
    end
    timeout_after(Application.get_env(:cachets, :timeout))
    initial_state([])
  end

  defhandleinfo :timeout, state: [], do: noreply()
  defhandleinfo :timeout, state: state do
    {olds, newstate} = Enum.split_with(state, fn
      {_key, ttl} when is_integer(ttl) -> ttl < nowstamp()
      _ -> false end)
    if length(olds) > 0 do
      Logger.debug("to_delete: #{inspect olds} from #{inspect @table}, newstate: #{inspect newstate}")
      Enum.each(olds |> Keyword.keys(), &(:ets.delete(@table, &1)))
      new_state(newstate)
    else
      noreply()
    end
  end

  defcast add(key, value, opts), state: state do
    :ets.insert(@table, {key, value})
    Logger.debug("add value: #{inspect {key, value, opts}} to default storage")
    if (ttl = opts[:ttl]) |> is_integer do
      new_state([{key, nowstamp() + ttl}|Enum.reject(state, fn {el, _ttl} -> el == key end)])
    else
      new_state([{key, :inf}|Enum.reject(state, fn {el, _ttl} -> el == key end)])
    end
  end

  defcall add_new(key, value, opts), state: state do
    case :ets.insert_new(@table, {key, value}) do
      true -> Logger.debug("add new value: #{inspect {key, value, opts}} to default storage")
              if (ttl = opts[:ttl]) |> is_integer do
                set_and_reply([{key, nowstamp() + ttl}|Enum.reject(state, fn {el, _ttl} -> el == key end)], :ok)
              else
                set_and_reply([{key, :inf}|Enum.reject(state, fn {el, _ttl} -> el == key end)], :ok)
              end
      _ -> reply({:error, "this key already exist"})
    end
  end

  defcall get(key, _opts) do
    reply(:ets.lookup(@table, key))
  end

  defcast delete(key, _opts), state: state do
    :ets.delete(@table, key)
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
  end

  def handle_info(msg, state), do: (Logger.debug("Unpredicted msg: #{inspect msg}, for: #{inspect self()}"); {:noreply, state})
  def handle_call(request, from, state), do: (Logger.debug("Unpredicted gen-call: #{inspect request}, from: #{inspect from}, for: #{inspect self()}"); {:reply, nil, state})
  def handle_cast(request, state), do: (Logger.debug("Unpredicted gen-cast: #{inspect request}, for: #{inspect self()}"); {:noreply, state})
end