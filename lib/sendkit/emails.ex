defmodule SendKit.Emails do
  @moduledoc """
  Send emails through the SendKit API.
  """

  @doc """
  Send a structured email.

  ## Parameters

    * `client` - A `SendKit` client
    * `params` - A map with email parameters:
      * `:from` (required) - Sender email address
      * `:to` (required) - Recipient email address (string) or list of addresses. Supports display name format (e.g. "Bob <bob@example.com>")
      * `:subject` (required) - Email subject
      * `:html` - HTML body
      * `:text` - Plain text body
      * `:cc` - List of CC addresses
      * `:bcc` - List of BCC addresses
      * `:reply_to` - Reply-to address
      * `:headers` - Map of custom headers
      * `:tags` - List of tags
      * `:scheduled_at` - Schedule send time (ISO 8601)
      * `:attachments` - List of attachment maps with `:filename`, `:content`, and optional `:content_type`

  ## Returns

    * `{:ok, %{"id" => id}}` on success
    * `{:error, %SendKit.Error{}}` on failure
  """
  @spec send(SendKit.t(), map()) :: {:ok, map()} | {:error, SendKit.Error.t()}
  def send(%SendKit{} = client, params) when is_map(params) do
    body =
      params
      |> Map.take([
        :from,
        :to,
        :subject,
        :html,
        :text,
        :cc,
        :bcc,
        :reply_to,
        :headers,
        :tags,
        :scheduled_at,
        :attachments
      ])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    case Req.post(client.req, url: "/emails", json: body) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{body: body}} ->
        {:error,
         %SendKit.Error{
           name: body["name"] || "application_error",
           message: body["message"] || "Unknown error",
           status_code: body["statusCode"]
         }}

      {:error, reason} ->
        {:error,
         %SendKit.Error{
           name: "http_error",
           message: "HTTP request failed: #{inspect(reason)}"
         }}
    end
  end

  @doc """
  Send a raw MIME email.

  ## Parameters

    * `client` - A `SendKit` client
    * `params` - A map with:
      * `:envelope_from` (required) - Sender address
      * `:envelope_to` (required) - Recipient address
      * `:raw_message` (required) - Raw MIME message string

  ## Returns

    * `{:ok, %{"id" => id}}` on success
    * `{:error, %SendKit.Error{}}` on failure
  """
  @spec send_mime(SendKit.t(), map()) :: {:ok, map()} | {:error, SendKit.Error.t()}
  def send_mime(%SendKit{} = client, params) when is_map(params) do
    body = Map.take(params, [:envelope_from, :envelope_to, :raw_message])

    case Req.post(client.req, url: "/emails/mime", json: body) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{body: body}} ->
        {:error,
         %SendKit.Error{
           name: body["name"] || "application_error",
           message: body["message"] || "Unknown error",
           status_code: body["statusCode"]
         }}

      {:error, reason} ->
        {:error,
         %SendKit.Error{
           name: "http_error",
           message: "HTTP request failed: #{inspect(reason)}"
         }}
    end
  end
end
