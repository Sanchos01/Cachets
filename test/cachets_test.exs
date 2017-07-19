defmodule CachetsTest do
  use ExUnit.Case
  import Cachets.Utils, only: [via_tuple: 1, name_for_table: 1]
  @worker_table_protection Application.get_env(:cachets, :worker_table_protection)
  doctest Cachets

  setup_all do
    Cachets.new_cache("foo")
    pid = GenServer.whereis(:'Elixir.Cachets.Common')
    Process.exit(pid, :kill)
    :timer.sleep(300)
  end

  test "App have worker and table, preassigned in config" do
    assert [_|_] = :ets.info(:__Cachets__qwerty__)
    assert GenServer.whereis(via_tuple("qwerty"))
  end

  test "Record self-delete from common-server" do
    Cachets.adds(:key, 123, ttl: 50)
    :timer.sleep(20)
    assert [key: 123] == Cachets.gets(:key)
    :timer.sleep(100)
    assert [] = Cachets.gets(:key)
  end

  test "Record self-delete from worker" do
    assert GenServer.whereis(via_tuple("foo"))
    Cachets.add("foo", :key, 123, ttl: 50)
    :timer.sleep(20)
    assert [key: 123] == Cachets.get("foo", :key)
    :timer.sleep(100)
    assert [] = Cachets.get("foo", :key)
  end

  test "Creating new ETS-cache" do
    assert GenServer.whereis(via_tuple("foo")) # Customized table
    refute GenServer.whereis(via_tuple("bar"))
    Cachets.new_cache("bar")
    assert GenServer.whereis(via_tuple("bar"))
    Cachets.new_cache("bar2", timeout: 1000)
    assert GenServer.whereis(via_tuple("bar2"))
    assert :ok = Cachets.Worker.Supervisor.new_cache("bar3")
    assert GenServer.whereis(via_tuple("bar3"))
  end

  test "Destroing ETS-cache" do
    Cachets.new_cache("baz")
    pid = GenServer.whereis(via_tuple("baz"))
    ref = Process.monitor(pid)
    Cachets.destroy_cache("baz")
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 5_000
  end

  test "ETS-cache don't crash after receiving unpredicted messages" do
    pid = GenServer.whereis(via_tuple("foo"))
    ref = Process.monitor(pid)
    GenServer.call(pid, :unpredicted_call)
    GenServer.cast(pid, :unpredicted_cast)
    send(pid, :unpredicted_message)
    refute_receive {:DOWN, ^ref, _, ^pid, _}, 100
  end

  test "Common ETS-cache don't crash after receiving unpredicted messages" do
    pid = GenServer.whereis(:'Elixir.Cachets.Common')
    ref = Process.monitor(pid)
    GenServer.call(pid, :unpredicted_call)
    GenServer.cast(pid, :unpredicted_cast)
    send(pid, :unpredicted_message)
    refute_receive {:DOWN, ^ref, _, ^pid, _}, 100
  end

  test "Add_new to common-server" do
    assert :ok = Cachets.adds_new(:uniqal, 123)
    assert [_|_] = Cachets.gets(:uniqal)
    assert {:error, "this key already exist"} = Cachets.adds_new(:uniqal, 123)
  end

  test "Add_new to worker" do
    assert :ok = Cachets.add_new("foo", :uniqal, 123)
    assert [_|_] = Cachets.get("foo", :uniqal)
    assert {:error, "this key already exist"} = Cachets.add_new("foo", :uniqal, 123)
  end

  test "Add_new to common-server with self-delete option" do
    assert :ok = Cachets.adds_new(:super_uniqal, 123, ttl: 50)
    :timer.sleep(20)
    assert [super_uniqal: 123] == Cachets.gets(:super_uniqal)
    :timer.sleep(100)
    assert [] = Cachets.gets(:super_uniqal)
  end

  test "Add_new to worker with self-delete option" do
    assert :ok = Cachets.add_new("foo", :super_uniqal, 123, ttl: 50)
    :timer.sleep(20)
    assert [super_uniqal: 123] == Cachets.get("foo", :super_uniqal)
    :timer.sleep(100)
    assert [] = Cachets.gets("foo", :super_uniqal)
  end

  test "Registry module" do
    assert GenServer.whereis(:'Elixir.Cachets.Worker.Registry')
    assert {:error, _} = Cachets.Worker.Registry.start_link()
  end

  test "Start worker with wrong options" do
    assert :ok = Cachets.new_cache("true", [protection: :public])
    assert :ok = Cachets.new_cache("wrong1", [protection: 123])
    assert :ok = Cachets.new_cache("wrong2", [protection: :foo])
    assert :public = :ets.info(name_for_table("true"))[:protection]
    assert @worker_table_protection = :ets.info(name_for_table("wrong1"))[:protection]
    assert @worker_table_protection = :ets.info(name_for_table("wrong2"))[:protection]
  end

  test "Killing caches don't destroy ETS-tab" do
    assert :ok = Cachets.new_cache("123")
    pid = GenServer.whereis(via_tuple("123"))
    Process.exit(pid, :kill)
    :timer.sleep(100)
    assert [_|_] = :ets.info(name_for_table("123"))
  end
end
