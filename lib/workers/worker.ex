defmodule Cachets.Worker do
  require Logger
  use ExActor.GenServer
  import Cachets.Utils
  @ets_preset [:set, :named_table]

  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    table_name = opts[:table_name]
    saver_pid = GenServer.whereis(:'Elixir.Cachets.Saver')
    try do
      :ets.new(table_name, [(opts[:protection] || :protected)|[{:heir, saver_pid, "transfered from worker"}|@ets_preset]])
    rescue
      ArgumentError ->
        case :ets.info(table_name)[:owner] do
          ^saver_pid ->
            send saver_pid, {:return_table_for_worker, self()}
            receive do
              {:"ETS-TRANSFER", ^table_name, _pid, "return back worker_table"} -> :ok
            after
              300 -> raise "Table with such name already exists"
            end
          _another_pid -> raise(ArgumentError, message: "Table with such name already exists")
        end
    end
    timeout_after(opts[:timeout])
    initial_state([name_of_attached_table: table_name])
  end

  defhandleinfo :timeout, state: [name_of_attached_table: _], do: noreply()
  defhandleinfo :timeout, state: state do
    now = nowstamp()
    {olds, newstate} = Enum.split_with(state, fn
      {_key, ttl} when is_integer(ttl) -> ttl < now
      _ -> false end)
    if length(olds) > 0 do
      Logger.debug("to_delete: #{inspect olds} from #{inspect newstate[:name_of_attached_table]}, newstate: #{inspect newstate}")
      Enum.each(olds |> Keyword.keys(), &(:ets.delete(state[:name_of_attached_table], &1)))
      new_state(newstate)
    else
      noreply()
    end
  end

  defcast add(key, value, opts), state: state do
    :ets.insert(state[:name_of_attached_table], {key, value})
    Logger.debug("add value: #{inspect {key, value, opts}} to #{inspect state[:name_of_attached_table]}")
    if (ttl = opts[:ttl]) |> is_integer do
      new_state(Keyword.put(state, key, nowstamp() + ttl))
    else
      new_state(Keyword.put(state, key, :inf))
    end
  end

  defcall add_new(key, value, opts), state: state do
    case :ets.insert_new(state[:name_of_attached_table], {key, value}) do
      true -> Logger.debug("add new value: #{inspect {key, value, opts}} to #{inspect state[:name_of_attached_table]}")
              if (ttl = opts[:ttl]) |> is_integer do
                set_and_reply(Keyword.put(state, key, nowstamp() + ttl), :ok)
              else
                set_and_reply(Keyword.put(state, key, :inf), :ok)
              end
      _ -> reply({:error, "this key already exist"})
    end
  end

  defcall get(key), state: state do
    reply(:ets.lookup(state[:name_of_attached_table], key))
  end

  defcast delete(key), state: state do
    :ets.delete(state[:name_of_attached_table], key)
    new_state(Keyword.delete(state, key))
  end

  defcast stop(opts), state: state do
    table = state[:name_of_attached_table]
    case opts[:with_ets] do
      true -> :ets.delete(table)
      _ -> :ets.give_away(table, GenServer.whereis(:'Elixir.Cachets.Saver'), "save this")
    end
    stop_server(:normal)
  end

  def handle_info(msg, state), do: (Logger.debug("Unpredicted msg: #{inspect msg}, for: #{inspect self()}"); {:noreply, state})
end