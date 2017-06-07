defmodule Cachets.Worker do
  @callback add(key :: term, value :: term, opts :: [key: value :: integer | atom] | none) :: true
  @callback get(key :: term, opts :: [key: value :: integer | atom] | none) :: [key: term] | []
  @callback delete(key :: term, opts :: [key: value :: integer | atom] | none) :: true
end