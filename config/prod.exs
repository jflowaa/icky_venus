import Config

config :logger,
  handle_otp_reports: true,
  handle_sasl_reports: true

config :logger, :default_handler,
  config: [
    file: ~c"logs.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ],
  format: "$date $time $metadata[$level] $message"
