defmodule Cachets.Common do
  use ExActor.GenServer
  @table Application.get_env(:cachets, :common_table)
  import Cachets.Utils, only: [nowstamp: 0]

  def start_link(name, opts \\ [])
  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    timeout_after(Application.get_env(:cachets, :timeout))
    initial_state([])
  end

  defcast add_to_state(key, ttl), state: state, do: new_state([{key, ttl}|state])
  defcast delete_from_state(key), state: state do
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
  end

  defhandleinfo :timeout, state: [], do: noreply()
  defhandleinfo :timeout, state: state do
    with olds <- Enum.filter(state, fn {_key, ttl} -> ttl < nowstamp() end) |> Keyword.keys() do
      Enum.each(olds, &delete/1)
      noreply()
    end
  end

  def add(key, value, opts \\ [])
  def add(key, value, opts) do
    delete_from_state(Cachets.Common, key)
    cond do
      (ttl = opts[:ttl]) |> is_integer -> add_to_state(Cachets.Common, key, nowstamp() + ttl)
      true -> add_to_state(Cachets.Common, key, :inf)
    end
    :ets.insert(@table, {key, value})
    :ok
  end

  def get(key, opts \\ [])
  def get(key, _opts) do
    :ets.lookup(@table, key)
  end

  def delete(key, opts \\ [])
  def delete(key, _opts) do
    :ets.delete(@table, key)
    delete_from_state(Cachets.Common, key)
  end
end