defmodule Cachets.Utils do
  def nowstamp do
    with {a,b,c} <- :os.timestamp,
      do: a * 1000000000 + b * 1000 + div(c, 1000)
  end
end