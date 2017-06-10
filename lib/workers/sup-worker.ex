defmodule Cachets.Worker.Supervisor do
  use Supervisor
  @ets_preset [:set, :public, :named_table]

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Cachets.Worker, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
  
  def new_cache(name) do
    with nil <- GenServer.whereis(name),
         _ets <- :ets.new(name, @ets_preset),
         do: {:ok, _pid} = Supervisor.start_child(__MODULE__, [name])
  end
end