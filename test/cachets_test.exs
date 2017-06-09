defmodule CachetsTest do
  use ExUnit.Case
  doctest Cachets

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
