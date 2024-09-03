# IckyVenus

This project was created to experiment using HTMX with Bandit server on Elixir. I wanted to experiment with web sockets and page updates without using Phoenix.

Currently this starts a GenServer to read from [Bluesky's firehose](https://docs.bsky.app/docs/advanced-guides/firehose) and update a page to have a counter of new posts created since page load.

To run this do:

```bash
mix deps.get
mix run --no-halt
```

Then visit http://localhost:4000/
