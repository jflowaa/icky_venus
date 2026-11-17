import Config

if config_env() == :prod do
  config :icky_venus,
    server_port: String.to_integer(System.get_env("PORT") || "4000")
end
