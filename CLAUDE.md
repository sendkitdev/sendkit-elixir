# SendKit Elixir SDK

## Project Overview

Elixir SDK for the SendKit email API. Uses Req for HTTP, Jason for JSON.

## Architecture

```
lib/
├── sendkit.ex          # SendKit struct: new/1, holds Req client
└── sendkit/
    ├── emails.ex       # Emails module (send, send_mime)
    └── error.ex        # Error exception struct
```

- `SendKit.new("key")` creates client with Req
- `SendKit.Emails.send(client, params)` for structured emails
- `SendKit.Emails.send_mime(client, params)` for MIME emails
- Returns `{:ok, map}` or `{:error, %SendKit.Error{}}`
- `POST /v1/emails` for structured emails, `POST /v1/emails/mime` for raw MIME

## Testing

- Tests use `Bypass` for mock HTTP servers
- Run tests: `mix test`
- Tests in `test/sendkit_test.exs`

## Releasing

- Tags use numeric format: `1.0.0` (no `v` prefix)
- CI runs tests on Elixir stable + OTP
- Pushing a tag creates GitHub Release + publishes to hex.pm

## Git

- NEVER add `Co-Authored-By` lines to commit messages
