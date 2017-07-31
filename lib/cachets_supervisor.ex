defmodule Cachets.Supervisor do
  use Supervisor
  require Logger
  @common_genserver Application.get_env(:cachets, :common_genserver)

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      supervisor(Cachets.Worker.Supervisor, []),
      supervisor(Registry, [:unique, Cachets.Worker.Registry]),
      worker(Cachets.Saver, []),
      worker(Cachets.Common, [@common_genserver])
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    supervise(children, opts)
  end
end