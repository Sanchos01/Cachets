defmodule Cachets.Worker do
  use ExActor.GenServer
  @callback add(term, term, opts :: [key: integer | atom] | none) :: :ok | {:error, term}
  @callback get(term, opts :: [key: integer | atom] | none) :: [key: term] | []
  @callback delete(term, opts :: [key: integer | atom] | none) :: true
  import Cachets.Utils

  def start_link(name, opts \\ [])
  defstart start_link(name, opts), links: true, gen_server_opts: [name: name] do
    timeout_after(opts[:timeout] || Application.get_env(:cachets, :timeout))
    initial_state([])
  end

  defcast add_to_state(key, ttl), state: state, do: new_state([{key, ttl}|state])
  defcast delete_from_state(key), state: state do
    new_state(Enum.reject(state, fn {el, _ttl} -> el == key end))
  end
  
  defhandleinfo :timeout, state: [], do: noreply()
  # defhandleinfo :timeout, state: state do
  #   with olds <- Enum.filter(state, fn {_key, ttl} -> ttl < nowstamp() end) |> Keyword.keys() do
  #     Enum.each(olds, &delete/1)
  #     noreply()
  #   end
  # end
end