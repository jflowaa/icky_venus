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

config :logger, :default_handler,
  config: [
    file: ~c"/root/logs/icky_venus.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]
