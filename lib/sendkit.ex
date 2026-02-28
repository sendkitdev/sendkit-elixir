defmodule SendKit do
  @moduledoc """
  Official Elixir SDK for the SendKit email API.

  ## Usage

      client = SendKit.new("sk_your_api_key")
      {:ok, %{"id" => id}} = SendKit.Emails.send(client, %{
        from: "you@example.com",
        to: ["recipient@example.com"],
        subject: "Hello",
        html: "<h1>Welcome!</h1>"
      })
  """

  @default_base_url "https://api.sendkit.dev"

  defstruct [:api_key, :base_url, :req]

  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          req: Req.Request.t()
        }

  @doc """
  Create a new SendKit client.

  If `api_key` is an empty string or `nil`, reads from the `SENDKIT_API_KEY` environment variable.
  """
  @spec new(String.t() | nil, keyword()) :: t()
  def new(api_key \\ nil, opts \\ []) do
    key =
      case api_key do
        nil -> System.get_env("SENDKIT_API_KEY") || ""
        "" -> System.get_env("SENDKIT_API_KEY") || ""
        key -> key
      end

    if key == "" do
      raise SendKit.Error, message: "Missing API key", name: "missing_api_key"
    end

    base_url = Keyword.get(opts, :base_url, @default_base_url)

    req =
      Req.new(
        base_url: base_url,
        headers: [{"authorization", "Bearer #{key}"}]
      )

    %__MODULE__{api_key: key, base_url: base_url, req: req}
  end
end
