defmodule Cachets.Worker.Supervisor do
  use Supervisor
  @def_timeout Application.get_env(:cachets, :timeout)
  import Cachets.Utils, only: [name_for_table: 1]

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Cachets.Worker, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
  
  def new_cache(name, opts \\ [])
  def new_cache(name, opts) when is_bitstring(name) do
    table_name = name_for_table(name)
    via_name = {:via, Registry, {Cachets.Worker.Registry, name}}
    send_opts =
      case (t_out = opts[:timeout]) |> is_integer() do
        true -> [t_name: table_name, timeout: t_out]
        _ -> [t_name: table_name, timeout: @def_timeout]
      end
    with nil <- GenServer.whereis(via_name),
         :undefined <- :ets.info(table_name),
         {:ok, _pid} = Supervisor.start_child(__MODULE__, [via_name, send_opts]),
         do: :ok
  end
  def new_cache(_, _), do: {:error, "name must be string"}

  def destroy_cache(name, opts \\ [])
  def destroy_cache(name, opts) when is_bitstring(name) do
    table_name = name_for_table(name)
    via_name = {:via, Registry, {Cachets.Worker.Registry, name}}
    if GenServer.whereis(via_name) == nil
    do
      {:error, "This cache is not exists"}
    else
      Cachets.Worker.stop(via_name)
      :ets.delete(table_name)
      :ok
    end
  end
  def destroy_cache(_, _), do: {:error, "name must be string"}
end