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
  
  def new_cache(name) when is_bitstring(name) do
    a_name = name |> String.to_atom()
    with nil <- GenServer.whereis(a_name),
         _ets <- :ets.new(a_name, @ets_preset),
         via_name = {:via, Registry, {Cachets.Worker.Registry, name}},
         do: {:ok, _pid} = Supervisor.start_child(__MODULE__, [via_name])
  end
  def new_cache(_), do: {:error, "name must be string"}
end