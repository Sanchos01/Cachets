defmodule CachetsTest do
  use ExUnit.Case
  doctest Cachets
  @pg2_group Application.get_env(:cachets, :pg2group_exact)

  test "add to exact" do
    Cachets.Exact.add(:key, 123)
    assert [{:key, 123}] == Cachets.Exact.get(:key)
  end

  test "process-deleter is exist" do
    Cachets.Exact.add(:key, 123, ttl: 7000)
    assert length(:pg2.get_local_members(@pg2_group)) == 1
  end

  test "record self-destroyed" do
    Cachets.Exact.add(:key, 123, ttl: 5)
    :timer.sleep(5)
    assert Cachets.Exact.get(:key) == []
  end
end
