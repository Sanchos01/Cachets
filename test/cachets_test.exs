defmodule CachetsTest do
  require Logger
  use ExUnit.Case
  import Cachets.Utils, only: [via_tuple: 1, name_for_table: 1]
  @worker_table_protection Application.get_env(:cachets, :worker_table_protection)
  doctest Cachets

  setup_all do
    Cachets.new_cache("foo")
    pid = GenServer.whereis(:'Elixir.Cachets.Common')
    Process.exit(pid, :kill)
    :timer.sleep(100)
  end

  setup context do
    if num = context[:num] do
      Logger.debug("start test #{inspect num}")
      on_exit fn ->
        Logger.debug("end test #{inspect num}")
      end
    else
      :ok
    end
  end

  @tag num: 1
  test "App have worker and table, preassigned in config" do
    assert [_|_] = :ets.info(:__Cachets__qwerty__)
    assert GenServer.whereis(via_tuple("qwerty"))
  end

  @tag num: 2
  test "Record self-delete from common-server" do
    Cachets.adds(:key, 123, ttl: 20)
    assert [key: 123] == Cachets.gets(:key)
    :timer.sleep(40)
    assert [] = Cachets.gets(:key)
  end

  @tag num: 3
  test "Record self-delete from worker" do
    assert GenServer.whereis(via_tuple("foo"))
    Cachets.add("foo", :key, 123, ttl: 20)
    assert [key: 123] == Cachets.get("foo", :key)
    :timer.sleep(40)
    assert [] = Cachets.get("foo", :key)
  end

  @tag num: 4
  test "Creating new ETS-cache" do
    assert GenServer.whereis(via_tuple("foo")) # Customized table
    refute GenServer.whereis(via_tuple("bar"))
    assert :ok = Cachets.new_cache("bar")
    assert GenServer.whereis(via_tuple("bar"))
  end

  @tag num: 5
  test "Creating new ETS-cache with timeout" do
    assert :ok = Cachets.new_cache("bar2", timeout: 1000)
    assert GenServer.whereis(via_tuple("bar2"))
  end

  @tag num: 6
  test "Creating new ETS-cache from worker-supervisor" do
    assert :ok = Cachets.Worker.Supervisor.new_cache("bar3")
    assert GenServer.whereis(via_tuple("bar3"))
  end

  @tag num: 7
  test "Destroing ETS-cache" do
    Cachets.new_cache("bar4")
    pid = GenServer.whereis(via_tuple("bar4"))
    ref = Process.monitor(pid)
    Cachets.destroy_cache("bar4")
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 5_000
  end

  @tag num: 8
  test "ETS-cache don't crash after receiving unpredicted messages" do
    pid = GenServer.whereis(via_tuple("foo"))
    ref = Process.monitor(pid)
    GenServer.call(pid, :unpredicted_call)
    GenServer.cast(pid, :unpredicted_cast)
    send(pid, :unpredicted_message)
    refute_receive {:DOWN, ^ref, _, ^pid, _}, 20
  end

  @tag num: 9
  test "Common ETS-cache don't crash after receiving unpredicted messages" do
    pid = GenServer.whereis(:'Elixir.Cachets.Common')
    ref = Process.monitor(pid)
    GenServer.call(pid, :unpredicted_call)
    GenServer.cast(pid, :unpredicted_cast)
    send(pid, :unpredicted_message)
    refute_receive {:DOWN, ^ref, _, ^pid, _}, 20
  end

  @tag num: 10
  test "Add_new to common-server" do
    assert :ok = Cachets.adds_new(:uniqal, 123)
    assert [_|_] = Cachets.gets(:uniqal)
    assert {:error, "this key already exist"} = Cachets.adds_new(:uniqal, 123)
  end

  @tag num: 11
  test "Add_new to worker" do
    assert :ok = Cachets.add_new("foo", :uniqal, 123)
    assert [_|_] = Cachets.get("foo", :uniqal)
    assert {:error, "this key already exist"} = Cachets.add_new("foo", :uniqal, 123)
  end

  @tag num: 12
  test "Add_new to common-server with self-delete option" do
    assert :ok = Cachets.adds_new(:super_uniqal, 123, ttl: 20)
    assert [super_uniqal: 123] == Cachets.gets(:super_uniqal)
    :timer.sleep(40)
    assert [] = Cachets.gets(:super_uniqal)
  end

  @tag num: 13
  test "Add_new to worker with self-delete option" do
    assert :ok = Cachets.add_new("foo", :super_uniqal, 123, ttl: 20)
    assert [super_uniqal: 123] == Cachets.get("foo", :super_uniqal)
    :timer.sleep(40)
    assert [] = Cachets.gets("foo", :super_uniqal)
  end

  @tag num: 14
  test "Registry module" do
    assert GenServer.whereis(:'Elixir.Cachets.Worker.Registry')
    assert {:error, _} = Cachets.Worker.Registry.start_link()
  end

  @tag num: 15
  test "Creating ETS-cache with normal options" do
    assert :ok = Cachets.new_cache("true", [protection: :public])
    assert :public = :ets.info(name_for_table("true"))[:protection]
  end

  @tag num: 16
  test "Creating ETS-cache with wrong options" do
    assert :ok = Cachets.new_cache("wrong", [protection: 123])
    assert @worker_table_protection = :ets.info(name_for_table("wrong"))[:protection]
  end

  @tag num: 17
  test "Killing caches don't destroy ETS-tab" do
    assert :ok = Cachets.new_cache("123")
    pid = GenServer.whereis(via_tuple("123"))
    Process.exit(pid, :kill)
    :timer.sleep(20)
    assert [_|_] = :ets.info(name_for_table("123"))
  end

  @tag num: 18
  test "Saver don't crash after receiving unpredicted messages" do
    pid = GenServer.whereis(:'Elixir.Cachets.Saver')
    ref = Process.monitor(pid)
    GenServer.call(pid, :unpredicted_call)
    GenServer.cast(pid, :unpredicted_cast)
    send(pid, :unpredicted_message)
    refute_receive {:DOWN, ^ref, _, ^pid, _}, 20
  end

  @tag num: 19
  test "Create ETS-cache, while table with such name already exists" do
    saver_pid = GenServer.whereis(:'Elixir.Cachets.Saver')
    :ets.new(name_for_table("baz1"), [:set, :public, :named_table, {:heir, saver_pid, "hi"}])
    :ets.new(name_for_table("baz2"), [:set, :public, :named_table, {:heir, saver_pid, "hi"}])
    :ets.give_away(name_for_table("baz2"), saver_pid, "hi")
    try do
      Cachets.new_cache("baz1")
    rescue
      MatchError -> :ok
    end
    try do
      Cachets.new_cache("baz2")
    rescue
      MatchError -> :ok
    end
  end
end
