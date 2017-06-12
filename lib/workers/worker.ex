defmodule Cachets.Worker do
  require Logger
  use ExActor.GenServer
  import Cachets.Utils, only: [nowstamp: 0]

  def start_link(name, opts \\ [])
  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    timeout_after(opts[:timeout] || Application.get_env(:cachets, :timeout))
    {:via, Registry, {Cachets.Worker.Registry, string_name}} = name
    Logger.debug("start #{inspect string_name}")
    initial_state([name_of_attached_table: String.to_atom(string_name)])
  end
  
  defhandleinfo :timeout, state: [name_of_attached_table: _], do: noreply()
  defhandleinfo :timeout, state: state do
    {olds, newstate} = Enum.split_with(state, fn
      {_key, ttl} when is_integer(ttl) -> ttl < nowstamp()
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
    if (ttl = opts[:ttl]) |> is_integer do
      new_state([{key, nowstamp() + ttl}|Enum.reject(state, fn {el, _ttl} -> el == key end)])
    else
      new_state([{key, :inf}|Enum.reject(state, fn {el, _ttl} -> el == key end)])
    end
  end

  defcall get(key, _opts), state: state do
    reply(:ets.lookup(state[:name_of_attached_table], key))
  end
  
  defcast delete(key, _opts), state: state do
    :ets.delete(state[:name_of_attached_table], key)
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
  end
end