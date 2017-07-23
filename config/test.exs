use Mix.Config

config :logger,
  level: :debug

config :cachets,
  timeout: 10,
  add_caches: [
    "qwerty",
    ["qwe", [timeout: 10000, protection: :public]]
  ]