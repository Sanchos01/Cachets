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

  def name_for_table(name) do
    String.to_atom("__Common__" <> name <> "__")
  end
  
  def new_cache(name) when is_bitstring(name) do
    table_name = name_for_table(name)
    via_name = {:via, Registry, {Cachets.Worker.Registry, name}}
    with nil <- GenServer.whereis(via_name),
         _ets <- :ets.new(table_name, @ets_preset),
         do: {:ok, _pid} = Supervisor.start_child(__MODULE__, [via_name, [t_name: table_name]])
  end
  def new_cache(_), do: {:error, "name must be string"}
end