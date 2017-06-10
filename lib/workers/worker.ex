defmodule Cachets.Worker do
  require Logger
  use ExActor.GenServer
  import Cachets.Utils, only: [nowstamp: 0]

  def start_link(name, opts \\ [])
  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    timeout_after(opts[:timeout] || Application.get_env(:cachets, :timeout))
    initial_state([name_of_attached_table: name])
  end

  defcast delete_from_state(key), state: state do
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
  end
  
  defhandleinfo :timeout, state: [name_of_attached_table: _], do: noreply()
  defhandleinfo :timeout, state: state do
    {olds, newstate} = Enum.split_with(state, fn
      {_key, ttl} when is_integer(ttl) -> ttl < nowstamp()
      _ -> false end)
    if length(olds) > 0 do
      Logger.debug("to_delete: #{inspect olds}; newstate: #{inspect newstate}")
      Enum.each(olds |> Keyword.keys(), &(:ets.delete(state[:name_of_attached_table], &1)))
      new_state(newstate)
    else
      noreply()
    end
  end

  defcast add(key, value), state: state do
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
    :ets.insert(state[:name_of_attached_table], {key, value})
    new_state([{key, :inf}|state])
  end
  defcast add(key, value, opts), state: state do
    if (ttl = opts[:ttl]) |> is_integer do
      :ets.insert(state[:name_of_attached_table], {key, value})
      new_state([{key, nowstamp() + ttl}|state])
    end
  end
end