defmodule CachetsTest do
  use ExUnit.Case
  doctest Cachets
  @pg2_group Application.get_env(:cachets, :pg2group_exact)

  test "add to exact" do
    Cachets.Exact.add(:key, 123)
    assert [key: 123] == Cachets.Exact.get(:key)
  end

  test "process-deleter is exist" do
    Cachets.Exact.add(:key, 123, ttl: 5)
    assert length(:pg2.get_local_members(@pg2_group)) == 1
  end

  test "record and destr-process self-destroyed" do
    Cachets.Exact.add(:key, 123, ttl: 5)
    :timer.sleep(6) # Need one more millisecond for self-destroying process
    assert Cachets.Exact.get(:key) == []
    assert length(:pg2.get_local_members(@pg2_group)) == 0
  end

  test "add to common" do
    Cachets.Common.add(:key, 123)
    assert [{:key, 123}] == Cachets.Common.get(:key)
  end

  test "delete from common" do
    Cachets.Common.add(:key, 123)
    Cachets.Common.delete(:key)
    assert Cachets.Common.get(:key) == []
  end
end
