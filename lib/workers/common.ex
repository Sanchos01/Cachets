defmodule Cachets.Common do
  require Logger
  use ExActor.GenServer
  @table Application.get_env(:cachets, :common_table)
  @common_table Application.get_env(:cachets, :common_table)
  @common_table_protection Application.get_env(:cachets, :common_table_protection) || :protected
  @ets_preset [:set, :named_table]
  import Cachets.Utils, only: [nowstamp: 0]

  defstart start_link(name), links: true, gen_server_opts: [name: name] do
    saver_pid = GenServer.whereis(:'Elixir.Cachets.Saver')
    try do
      :ets.new(@common_table, [@common_table_protection|[{:heir, saver_pid, "transfered from common"}|@ets_preset]])
    rescue
      ArgumentError ->
        send saver_pid, {:return_table_for_common, self()}
          receive do
            {:"ETS-TRANSFER", @common_table, ^saver_pid, "return back common_table"} -> :ok
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
      new_state(Keyword.put(state, key, nowstamp() + ttl))
    else
      new_state(Keyword.put(state, key, :inf))
    end
  end

  defcall update(key, func, opts), state: state, when: is_function(func) do
    new_value = func.((:ets.lookup(@table, key)[key]) || 0)
    :ets.insert(@table, {key, new_value})
    Logger.debug("update value: #{inspect {key, new_value, opts}} to default storage")
    if (ttl = opts[:ttl]) |> is_integer do
      set_and_reply(Keyword.put(state, key, Keyword.get(state, key, ttl)), :ok)
    else
      set_and_reply(Keyword.put(state, key, Keyword.get(state, key, :inf)), :ok)
    end
  end

  defcall update(key, value, opts), state: state do
    :ets.insert(@table, {key, value})
    Logger.debug("update value: #{inspect {key, value, opts}} to default storage")
    if (ttl = opts[:ttl]) |> is_integer do
      set_and_reply(Keyword.put(state, key, Keyword.get(state, key, ttl)), :ok)
    else
      set_and_reply(Keyword.put(state, key, Keyword.get(state, key, :inf)), :ok)
    end
  end

  defcall add_new(key, value, opts), state: state do
    case :ets.insert_new(@table, {key, value}) do
      true -> Logger.debug("add new value: #{inspect {key, value, opts}} to default storage")
              if (ttl = opts[:ttl]) |> is_integer do
                set_and_reply(Keyword.put(state, key, nowstamp() + ttl), :ok)
              else
                set_and_reply(Keyword.put(state, key, :inf), :ok)
              end
      _ -> reply({:error, "this key already exist"})
    end
  end

  defcall get(key) do
    reply(:ets.lookup(@table, key))
  end

  defcast delete(key), state: state do
    :ets.delete(@table, key)
    new_state(Keyword.delete(state, key))
  end

  def handle_info(msg, state), do: (Logger.debug("Unpredicted msg: #{inspect msg}, for Common"); {:noreply, state})
end