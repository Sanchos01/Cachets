defmodule CachetsTest do
  use ExUnit.Case
  import Cachets.Utils, only: [via_tuple: 1]
  doctest Cachets

  setup_all do
    Cachets.new_cache("foo")
  end
  test "add to common" do
    Cachets.adds(:key, 123)
    assert [{:key, 123}] == Cachets.gets(:key)
  end

  test "delete from common" do
    Cachets.adds(:key, 123)
    Cachets.deletes(:key)
    assert Cachets.gets(:key) == []
  end

  test "record self-delete" do
    Cachets.adds(:key, 123, ttl: 10)
    :timer.sleep(200)
    assert Cachets.gets(:key) == []
  end

  test "creating new ETS-cache" do
    assert GenServer.whereis(via_tuple("foo")) != nil # Customized table
    assert GenServer.whereis(via_tuple("bar")) == nil
    Cachets.new_cache("bar")
    assert GenServer.whereis(via_tuple("bar")) != nil
  end

  test "destroing ETS-cache" do
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

  test "Registry module" do
    assert GenServer.whereis(:'Elixir.Cachets.Worker.Registry')
    assert {:error, _} = Cachets.Worker.Registry.start_link()
  end
end
