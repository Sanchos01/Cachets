defmodule Cachets do
  require Logger
  use Application

  @moduledoc """
  Simple implemintation of ETS-storage with following features:
  - Entry with lifetime
  - Using default storage or creating your own ETS-table

  ## Examples

      iex> Cachets.adds(:foo, "bar")
      :ok
      iex> Cachets.gets(:foo)
      [foo: "bar"]
  """
  @common_genserver Application.get_env(:cachets, :common_genserver)
  defdelegate new_cache(name, opts \\ []), to: Cachets.Worker.Supervisor
  defdelegate destroy_cache(name, opts \\ []), to: Cachets.Worker.Supervisor
  import Cachets.Utils, only: [via_tuple: 1]

  def start(_type, _args) do
    {:ok, pid} = Cachets.Supervisor.start_link()
    case Application.get_env(:cachets, :add_caches) do
      lst = [_|_] -> Enum.map(lst, fn x ->
              case x do
                [name, opts] -> Cachets.new_cache(name, opts)
                name -> Cachets.new_cache(name)
              end
            end)
      _ -> :ok
    end
    {:ok, pid}
  end

  @doc ~S"""
  Add the key and value to default storage.

  Options: [ttl: num], ttl mean lifetime.

  ## Examples

      iex> Cachets.adds(:foo1, "bar")
      :ok
      iex> Cachets.adds(:foo1, "bar", ttl: 20)
      :ok
  """
  def adds(key, value, opts \\ []), do: Cachets.Common.add(@common_genserver, key, value, opts)

  @doc ~S"""
  Add the key and value to created before storage (in test pre-created "foo").

  Options: [ttl: num], ttl mean lifetime.

  ## Examples

      iex> Cachets.add("foo", :bar1, "baz")
      :ok
      iex> Cachets.add("foo", :bar1, "baz", ttl: 20)
      :ok
  """
  def add(name, key, value, opts \\ []), do: Cachets.Worker.add(via_tuple(name), key, value, opts)

  @doc ~S"""
  Add the key and value to default storage, but don't rewrite if such key already exists.

  Options: [ttl: num], ttl mean lifetime.

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

  @doc ~S"""
  Add the key and value to created before storage, but don't rewrite if such key already exists (in test pre-created "foo").

  Options: [ttl: num], ttl mean lifetime.

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

  @doc ~S"""
  Get the key and value from default storage

  ## Examples

      iex> Cachets.adds(:foo3, "bar")
      :ok
      iex> Cachets.gets(:foo3)
      [foo3: "bar"]
  """
  def gets(key), do: Cachets.Common.get(@common_genserver, key)

  @doc ~S"""
  Get the key and value from created before storage (in test pre-created "foo").

  ## Examples

      iex> Cachets.add("foo", :bar3, "baz")
      :ok
      iex> Cachets.get("foo", :bar3)
      [bar3: "baz"]
  """
  def get(name, key), do: Cachets.Worker.get(via_tuple(name), key)

  @doc ~S"""
  Delete the key and value from default storage.

  ## Examples

      iex> Cachets.adds(:foo4, "bar")
      :ok
      iex> Cachets.deletes(:foo4)
      :ok
      iex> Cachets.gets(:foo4)
      []
  """
  def deletes(key), do: Cachets.Common.delete(@common_genserver, key)

  @doc ~S"""
  Delete the key and value from created before storage (in test pre-created "foo").

  ## Examples

      iex> Cachets.add("foo", :bar4, "baz")
      :ok
      iex> Cachets.delete("foo", :bar4)
      :ok
      iex> Cachets.get("foo", :bar4)
      []
  """
  def delete(name, key), do: Cachets.Worker.delete(via_tuple(name), key)

  @doc ~S"""
  Update value from default storage without changing lifetime, can put new value or use function

  Options: [ttl: num], ttl mean lifetime, used when such key not exists, default ttl = :inf

  ## Examples

      iex> Cachets.adds(:foo5, 3, ttl: 20)
      :ok
      iex> Cachets.updates(:foo5, 7)
      :ok
      iex> Cachets.updates(:foo5, 7, ttl: 100_000)
      :ok
      iex> Cachets.gets(:foo5)
      [foo5: 7]
      iex> :timer.sleep(30)
      :ok
      iex> Cachets.gets(:foo5)
      []
      iex> Cachets.updates(:foo5, &(&1 + 1), ttl: 20)
      :ok
      iex> Cachets.updates(:foo5, &(&1 / 2))
      :ok
      iex> Cachets.gets(:foo5)
      [foo5: 0.5]
      iex> :timer.sleep(30)
      :ok
      iex> Cachets.gets(:foo5)
      []
  """
  def updates(key, term, opts \\ []), do: Cachets.Common.update(@common_genserver, key, term, opts)

  @doc ~S"""
  Update value from created before storage (in test pre-created "foo") without changing lifetime, can put new value or use function

  Options: [ttl: num], ttl mean lifetime, used when such key not exists, default ttl = :inf

  ## Examples

      iex> Cachets.add("foo", :bar4, 3, ttl: 20)
      :ok
      iex> Cachets.update("foo", :bar4, 7)
      :ok
      iex> Cachets.update("foo", :bar4, 7, ttl: 100_000)
      :ok
      iex> Cachets.get("foo", :bar4)
      [bar4: 7]
      iex> :timer.sleep(30)
      :ok
      iex> Cachets.get("foo", :bar4)
      []
      iex> Cachets.update("foo", :bar4, &(&1 + 1), ttl: 20)
      :ok
      iex> Cachets.update("foo", :bar4, &(&1 / 2))
      :ok
      iex> Cachets.get("foo", :bar4)
      [bar4: 0.5]
      iex> :timer.sleep(30)
      :ok
      iex> Cachets.get("foo", :bar4)
      []
  """
  def update(name, key, term, opts \\ []), do: Cachets.Worker.update(via_tuple(name), key, term, opts)
end