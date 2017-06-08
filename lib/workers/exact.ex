defmodule Cachets.Exact do
  use ExActor.GenServer
  @behaviour Cachets.Worker
  @table Application.get_env(:cachets, :table_exact)
  @pg2_group Application.get_env(:cachets, :pg2group_exact)

  defstart start_link, do: nil

  def add(key, value, opts \\ [])
  def add(key, value, opts) do
    :ets.insert(@table, {key, value})
    if (ttl = opts[:ttl]) |> is_integer() do
      Enum.map(:pg2.get_local_members(@pg2_group), fn(pid) ->
        send pid, {key}
      end)
      pid = spawn(__MODULE__, :deleter, [key, ttl])
      :pg2.join(@pg2_group, pid)
    end
    :ok
  end

  def get(key, opts \\ [])
  def get(key, _opts) do
    :ets.lookup(@table, key)
  end

  def delete(key, opts \\ [])
  def delete(key, _opts) do
    :ets.delete(@table, key)
    Enum.map(:pg2.get_members(@pg2_group), fn(pid) ->
      send pid, {key}
    end)
  end

  @spec deleter(term, integer) :: true
  def deleter(key, ttl) do
    receive do
      {^key} -> {:stop, :normal}
    after
      ttl -> :ets.delete(@table, key)
    end
  end
end