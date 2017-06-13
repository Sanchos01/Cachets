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
  
  def new_cache(name, opts \\ []) when is_bitstring(name) do
    table_name = name_for_table(name)
    via_name = {:via, Registry, {Cachets.Worker.Registry, name}}
    if (t_out = opts[:timeout]) |> is_integer() do
      send_opts = [t_name: table_name, timeout: t_out]
    else
      send_opts = [t_name: table_name, timeout: (Application.get_env(:cachets, :timeout))]
    end
    with nil <- GenServer.whereis(via_name),
         _ets <- :ets.new(table_name, @ets_preset),
         do: {:ok, _pid} = Supervisor.start_child(__MODULE__, [via_name, send_opts])
  end
  def new_cache(_, _), do: {:error, "name must be string"}
end