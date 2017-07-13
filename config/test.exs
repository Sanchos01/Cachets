use Mix.Config

config :logger,
  level: :info

config :cachets,
  timeout: 10,
  add_caches: ["qwerty"]