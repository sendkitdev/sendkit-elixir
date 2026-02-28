# SendKit Elixir SDK

Official Elixir SDK for the [SendKit](https://sendkit.com) email API.

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:sendkit, "~> 1.0"}
  ]
end
```

## Usage

### Create a Client

```elixir
client = SendKit.new("sk_your_api_key")
```

### Send an Email

```elixir
{:ok, %{"id" => id}} =
  SendKit.Emails.send(client, %{
    from: "you@example.com",
    to: ["recipient@example.com"],
    subject: "Hello from SendKit",
    html: "<h1>Welcome!</h1>"
  })
```

### Send a MIME Email

```elixir
{:ok, %{"id" => id}} =
  SendKit.Emails.send_mime(client, %{
    envelope_from: "you@example.com",
    envelope_to: "recipient@example.com",
    raw_message: mime_string
  })
```

### Error Handling

```elixir
case SendKit.Emails.send(client, params) do
  {:ok, %{"id" => id}} ->
    IO.puts("Sent: #{id}")

  {:error, %SendKit.Error{name: name, message: message, status_code: code}} ->
    IO.puts("API error: #{name} (#{code}): #{message}")
end
```

### Configuration

```elixir
# Read API key from SENDKIT_API_KEY environment variable
client = SendKit.new()

# Custom base URL
client = SendKit.new("sk_...", base_url: "https://custom.api.com")
```
