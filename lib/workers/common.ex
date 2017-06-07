defmodule Cachets.Common do
  use ExActor.GenServer
  @behaviour Cachets.Worker
  @table Application.get_env(:cachets, :table_common)

  defstart start_link, do: nil

  def add(key, value, opts \\ [])
  def add(key, value, _opts) do
    :ets.insert(@table, {key, value})
  end

  def get(key, opts \\ [])
  def get(key, _opts) do
    :ets.lookup(@table, key)
  end

  def delete(key, opts \\ [])
  def delete(key, _opts) do
    :ets.delete(@table, key)
  end
end