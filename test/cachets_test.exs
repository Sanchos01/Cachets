defmodule CachetsTest do
  use ExUnit.Case
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
    assert GenServer.whereis(Cachets.via_tuple("foo")) != nil # Customized table
    assert GenServer.whereis(Cachets.via_tuple("bar")) == nil
    Cachets.new_cache("bar")
    assert GenServer.whereis(Cachets.via_tuple("bar")) != nil
  end
end
