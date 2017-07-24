defmodule CachetsTest do
  require Logger
  use ExUnit.Case
  import Cachets.Utils, only: [via_tuple: 1, name_for_table: 1]
  @worker_table_protection Application.get_env(:cachets, :worker_table_protection)
  doctest Cachets

  setup_all do
    Cachets.new_cache("foo")
    Cachets.new_cache("foo2")
    pid = GenServer.whereis(:'Elixir.Cachets.Common')
    Process.exit(pid, :kill)
    :timer.sleep(100)
  end

  setup context do
    if tab = context[:tab] do
      on_exit fn ->
        Cachets.destroy_cache(tab)
      end
    end
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

  @tag num: 2, tab: "bar"
  test "Creating new ETS-cache" do
    refute GenServer.whereis(via_tuple("bar"))
    assert :ok = Cachets.new_cache("bar")
  end

  @tag num: 3, tab: "bar2"
  test "Creating new ETS-cache with timeout" do
    assert :ok = Cachets.new_cache("bar2", timeout: 1000)
  end

  @tag num: 4
  test "Destroing ETS-cache" do
    Cachets.new_cache("bar3")
    pid = GenServer.whereis(via_tuple("bar3"))
    ref = Process.monitor(pid)
    Cachets.destroy_cache("bar3")
    assert_receive {:DOWN, ^ref, _, _, _}, 5_000
  end

  @tag num: 5
  test "Worker and Common don't crash after receiving unpredicted messages" do
    pid1 = GenServer.whereis(via_tuple("foo2"))
    pid2 = GenServer.whereis(:'Elixir.Cachets.Common')
    ref1 = Process.monitor(pid1)
    ref2 = Process.monitor(pid2)
    send(pid1, :unpredicted_message)
    send(pid2, :unpredicted_message)
    refute_receive {:DOWN, ^ref1, _, _, _}, 20
    refute_receive {:DOWN, ^ref2, _, _, _}, 20
  end

  @tag num: 6
  test "Registry module" do
    assert GenServer.whereis(:'Elixir.Cachets.Worker.Registry')
    assert {:error, _} = Cachets.Worker.Registry.start_link()
  end

  @tag num: 7, tab: "wrong"
  test "Creating ETS-cache with wrong options" do
    assert :ok = Cachets.new_cache("wrong", [protection: 123])
    assert @worker_table_protection = :ets.info(name_for_table("wrong"))[:protection]
  end
end
