defmodule Cachets.Worker do
  require Logger
  use ExActor.GenServer
  import Cachets.Utils
  @ets_preset [:set, :named_table]

  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    table_name = opts[:table_name]
    :ets.new(table_name, [(opts[:protection] || :protected)|@ets_preset])
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
      new_state([{key, nowstamp() + ttl}|Enum.reject(state, fn {el, _ttl} -> el == key end)])
    else
      new_state([{key, :inf}|Enum.reject(state, fn {el, _ttl} -> el == key end)])
    end
  end

  defcall add_new(key, value, opts), state: state do
    case :ets.insert_new(state[:name_of_attached_table], {key, value}) do
      true -> Logger.debug("add new value: #{inspect {key, value, opts}} to #{inspect state[:name_of_attached_table]}")
              if (ttl = opts[:ttl]) |> is_integer do
                set_and_reply([{key, nowstamp() + ttl}|Enum.reject(state, fn {el, _ttl} -> el == key end)], :ok)
              else
                set_and_reply([{key, :inf}|Enum.reject(state, fn {el, _ttl} -> el == key end)], :ok)
              end
      _ -> reply({:error, "this key already exist"})
    end
  end

  defcall get(key, _opts), state: state do
    reply(:ets.lookup(state[:name_of_attached_table], key))
  end

  defcast delete(key, _opts), state: state do
    :ets.delete(state[:name_of_attached_table], key)
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
  end

  defcast stop, state: state do
    stop_server(:normal)
  end

  def handle_info(msg, state), do: (Logger.debug("Unpredicted msg: #{inspect msg}, for: #{inspect self()}"); {:noreply, state})
end