defmodule Cachets do
  require Logger
  use Application
  @moduledoc """
  Simple implemintation of ETS-storage with following features:
  - Entry with lifetime
  - Using default storage or creating your own ETS-table

  Example:
    Cachets.adds(:foo, "bar")
    Cachets.gets(:foo) # "bar"
  """
  @common_genserver Application.get_env(:cachets, :common_genserver)
  defdelegate new_cache(name, opts \\ []), to: Cachets.Worker.Supervisor
  defdelegate destroy_cache(name), to: Cachets.Worker.Supervisor
  import Cachets.Utils, only: [via_tuple: 1]

  def start(_type, _args) do
    {:ok, pid} = Cachets.Supervisor.start_link()
    Logger.info("supervisor - #{inspect pid}")
    case Application.get_env(:cachets, :add_caches) do
        lst = [_|_] -> Enum.map(lst, &(new_cache(&1)))
        _ -> :ok
    end
    {:ok, pid}
  end
  @doc """
  Add the key and value to default storage

  ## Examples

      iex> Cachets.adds(:foo, "bar")
      :ok
  """
  def adds(key, value, opts \\ []), do: Cachets.Common.add(@common_genserver, key, value, opts)
  @doc """
  Add the key and value to created before storage (in test pre-created "foo")

  ## Examples

      iex> Cachets.add("foo", :bar, "baz")
      :ok
  """
  def add(name, key, value, opts \\ []), do: Cachets.Worker.add(via_tuple(name), key, value, opts)
  @doc """
  Add the key and value to default storage (but don't rewrite)

  ## Examples

      iex> Cachets.adds(:foo, "bar")
      :ok
      iex> Cachets.adds_new(:foo, "bar")
      {:error, "this key already exist"}
  """
  def adds_new(key, value, opts \\ []), do: Cachets.Common.add_new(@common_genserver, key, value, opts)
  @doc """
  Add the key and value to created before storage (in test pre-created "foo") (but don't rewrite)

  ## Examples

      iex> Cachets.add("foo", :bar, "baz")
      :ok
      iex> Cachets.add_new("foo", :bar, "baz")
      {:error, "this key already exist"}
  """
  def add_new(name, key, value, opts \\ []), do: Cachets.Worker.add_new(via_tuple(name), key, value, opts)
  @doc """
  Get the key and value from default storage

  ## Examples

      iex> Cachets.adds(:foo, "bar")
      :ok
      iex> Cachets.gets(:foo)
      [foo: "bar"]
  """
  def gets(key, opts \\ []), do: Cachets.Common.get(@common_genserver, key, opts)
  @doc """
  Get the key and value from created before storage (in test pre-created "foo")

  ## Examples

      iex> Cachets.add("foo", :bar, "baz")
      :ok
      iex> Cachets.get("foo", :bar)
      [bar: "baz"]
  """
  def get(name, key, opts \\ []), do: Cachets.Worker.get(via_tuple(name), key, opts)
  @doc """
  Delete the key and value from default storage

  ## Examples

      iex> Cachets.adds(:foo, "bar")
      :ok
      iex> Cachets.deletes(:foo)
      :ok
      iex> Cachets.gets(:foo)
      []
  """
  def deletes(key, opts \\ []), do: Cachets.Common.delete(@common_genserver, key, opts)
  @doc """
  Delete the key and value from created before storage (in test pre-created "foo")

  ## Examples

      iex> Cachets.add("foo", :bar, "baz")
      :ok
      iex> Cachets.delete("foo", :bar)
      :ok
      iex> Cachets.get("foo", :bar)
      []
  """
  def delete(name, key, opts \\ []), do: Cachets.Worker.delete(via_tuple(name), key, opts)
end