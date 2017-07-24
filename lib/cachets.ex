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
    case Application.get_env(:cachets, :add_caches) do
      lst = [_|_] -> Enum.map(lst, fn x -> case x do
            [name, opts] -> Cachets.new_cache(name, opts)
            name -> Cachets.new_cache(name)
          end
        end)
      _ -> :ok
    end
    {:ok, pid}
  end
  @doc """
  Add the key and value to default storage
  Options: [ttl: num], ttl mean lifetime

  ## Examples

      iex> Cachets.adds(:foo1, "bar")
      :ok
      iex> Cachets.adds(:foo1, "bar", ttl: 20)
      :ok
  """
  def adds(key, value, opts \\ []), do: Cachets.Common.add(@common_genserver, key, value, opts)
  @doc """
  Add the key and value to created before storage (in test pre-created "foo")
  Options: [ttl: num], ttl mean lifetime

  ## Examples

      iex> Cachets.add("foo", :bar1, "baz")
      :ok
      iex> Cachets.add("foo", :bar1, "baz", ttl: 20)
      :ok
  """
  def add(name, key, value, opts \\ []), do: Cachets.Worker.add(via_tuple(name), key, value, opts)
  @doc """
  Add the key and value to default storage, but don't rewrite if such key already exists
  Options: [ttl: num], ttl mean lifetime

  ## Examples

      iex> Cachets.adds_new(:foo2, "bar", ttl: 20)
      :ok
      iex> Cachets.adds_new(:foo2, "bar")
      {:error, "this key already exist"}
      iex> :timer.sleep(50)
      :ok
      iex> Cachets.adds_new(:foo2, "bar")
      :ok
  """
  def adds_new(key, value, opts \\ []), do: Cachets.Common.add_new(@common_genserver, key, value, opts)
  @doc """
  Add the key and value to created before storage, but don't rewrite if such key already exists (in test pre-created "foo")
  Options: [ttl: num], ttl mean lifetime

  ## Examples

      iex> Cachets.add_new("foo", :bar2, "baz", ttl: 20)
      :ok
      iex> Cachets.add_new("foo", :bar2, "baz")
      {:error, "this key already exist"}
      iex> :timer.sleep(50)
      :ok
      iex> Cachets.add_new("foo", :bar2, "baz")
      :ok
  """
  def add_new(name, key, value, opts \\ []), do: Cachets.Worker.add_new(via_tuple(name), key, value, opts)
  @doc """
  Get the key and value from default storage

  ## Examples

      iex> Cachets.adds(:foo3, "bar")
      :ok
      iex> Cachets.gets(:foo3)
      [foo3: "bar"]
  """
  def gets(key, opts \\ []), do: Cachets.Common.get(@common_genserver, key, opts)
  @doc """
  Get the key and value from created before storage (in test pre-created "foo")

  ## Examples

      iex> Cachets.add("foo", :bar3, "baz")
      :ok
      iex> Cachets.get("foo", :bar3)
      [bar3: "baz"]
  """
  def get(name, key, opts \\ []), do: Cachets.Worker.get(via_tuple(name), key, opts)
  @doc """
  Delete the key and value from default storage

  ## Examples

      iex> Cachets.adds(:foo4, "bar")
      :ok
      iex> Cachets.deletes(:foo4)
      :ok
      iex> Cachets.gets(:foo4)
      []
  """
  def deletes(key, opts \\ []), do: Cachets.Common.delete(@common_genserver, key, opts)
  @doc """
  Delete the key and value from created before storage (in test pre-created "foo")

  ## Examples

      iex> Cachets.add("foo", :bar4, "baz")
      :ok
      iex> Cachets.delete("foo", :bar4)
      :ok
      iex> Cachets.get("foo", :bar4)
      []
  """
  def delete(name, key, opts \\ []), do: Cachets.Worker.delete(via_tuple(name), key, opts)
end