defmodule Cachets.Utils do
  def nowstamp do
    with {a,b,c} <- :os.timestamp,
      do: a * 1000000000 + b * 1000 + div(c, 1000)
  end

  def name_for_table(name) do
    String.to_atom("__Cachets__" <> name <> "__")
  end

  def via_tuple(name) do
    {:via, Registry, {Cachets.Worker.Registry, name}}
  end
end