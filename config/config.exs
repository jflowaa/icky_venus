import Config

config :icky_venus,
  server_port: 4000,
  product_name: "Bluesky Metrics"

config :number,
  delimit: [
    precision: 0,
    delimiter: ",",
    separator: "."
  ]

# config :logger,
#   handle_otp_reports: true,
#   handle_sasl_reports: true
