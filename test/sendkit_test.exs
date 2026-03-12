defmodule SendKitTest do
  use ExUnit.Case

  test "new client with api key" do
    client = SendKit.new("sk_test_123")
    assert client.api_key == "sk_test_123"
    assert client.base_url == "https://api.sendkit.dev"
  end

  test "new client with custom base url" do
    client = SendKit.new("sk_test_123", base_url: "https://custom.api.com")
    assert client.base_url == "https://custom.api.com"
  end

  test "missing api key raises error" do
    System.delete_env("SENDKIT_API_KEY")

    assert_raise SendKit.Error, ~r/Missing API key/, fn ->
      SendKit.new("")
    end
  end

  test "client from env variable" do
    System.put_env("SENDKIT_API_KEY", "sk_from_env")
    client = SendKit.new()
    assert client.api_key == "sk_from_env"
    System.delete_env("SENDKIT_API_KEY")
  end

  test "send email" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["from"] == "sender@example.com"
      assert params["to"] == ["recipient@example.com"]
      assert params["subject"] == "Test Email"
      assert params["html"] == "<p>Hello</p>"

      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer sk_test_123"]

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "email-uuid-123"}))
    end)

    assert {:ok, %{"id" => "email-uuid-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>"
             })
  end

  test "send email with single string to" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["to"] == "recipient@example.com"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "single-to-123"}))
    end)

    assert {:ok, %{"id" => "single-to-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: "recipient@example.com",
               subject: "Test Email",
               html: "<p>Hello</p>"
             })
  end

  test "send email with display name format" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["to"] == "Bob <recipient@example.com>"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "display-name-123"}))
    end)

    assert {:ok, %{"id" => "display-name-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: "Bob <recipient@example.com>",
               subject: "Test Email",
               html: "<p>Hello</p>"
             })
  end

  test "send email with optional fields" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["reply_to"] == "reply@example.com"
      assert params["scheduled_at"] == "2026-03-01T10:00:00Z"
      refute Map.has_key?(params, "cc")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "email-uuid-456"}))
    end)

    assert {:ok, _} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test",
               html: "<p>Hi</p>",
               reply_to: "reply@example.com",
               scheduled_at: "2026-03-01T10:00:00Z",
               cc: nil
             })
  end

  test "send mime email" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails/mime", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["envelope_from"] == "sender@example.com"
      assert params["envelope_to"] == "recipient@example.com"
      assert params["raw_message"] =~ "From: sender@example.com"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "mime-uuid-789"}))
    end)

    assert {:ok, %{"id" => "mime-uuid-789"}} =
             SendKit.Emails.send_mime(client, %{
               envelope_from: "sender@example.com",
               envelope_to: "recipient@example.com",
               raw_message: "From: sender@example.com\r\nTo: recipient@example.com\r\n\r\nHello"
             })
  end

  test "send email with multiple to recipients" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["to"] == ["alice@example.com", "bob@example.com"]

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "multi-to-123"}))
    end)

    assert {:ok, %{"id" => "multi-to-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["alice@example.com", "bob@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>"
             })
  end

  test "send email with cc and bcc" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["cc"] == ["cc@example.com"]
      assert params["bcc"] == ["bcc@example.com"]

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "cc-bcc-123"}))
    end)

    assert {:ok, %{"id" => "cc-bcc-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>",
               cc: ["cc@example.com"],
               bcc: ["bcc@example.com"]
             })
  end

  test "send email with reply_to" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["reply_to"] == "replies@example.com"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "reply-to-123"}))
    end)

    assert {:ok, %{"id" => "reply-to-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>",
               reply_to: "replies@example.com"
             })
  end

  test "send email with text instead of html" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["text"] == "Hello, plain text"
      refute Map.has_key?(params, "html")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "text-only-123"}))
    end)

    assert {:ok, %{"id" => "text-only-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               text: "Hello, plain text"
             })
  end

  test "send email with headers" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["headers"] == %{"X-Custom" => "value", "X-Track" => "123"}

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "headers-123"}))
    end)

    assert {:ok, %{"id" => "headers-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>",
               headers: %{"X-Custom" => "value", "X-Track" => "123"}
             })
  end

  test "send email with tags" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert params["tags"] == ["welcome", "onboarding"]

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "tags-123"}))
    end)

    assert {:ok, %{"id" => "tags-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>",
               tags: ["welcome", "onboarding"]
             })
  end

  test "send email with attachments" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = Jason.decode!(body)

      assert [attachment] = params["attachments"]
      assert attachment["filename"] == "test.pdf"
      assert attachment["content"] == "base64data"
      assert attachment["content_type"] == "application/pdf"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "attachments-123"}))
    end)

    assert {:ok, %{"id" => "attachments-123"}} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: ["recipient@example.com"],
               subject: "Test Email",
               html: "<p>Hello</p>",
               attachments: [%{filename: "test.pdf", content: "base64data", content_type: "application/pdf"}]
             })
  end

  test "api error" do
    bypass = Bypass.open()
    client = SendKit.new("sk_test_123", base_url: "http://localhost:#{bypass.port}")

    Bypass.expect_once(bypass, "POST", "/emails", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        422,
        Jason.encode!(%{
          "name" => "validation_error",
          "message" => "The to field is required.",
          "statusCode" => 422
        })
      )
    end)

    assert {:error, %SendKit.Error{} = error} =
             SendKit.Emails.send(client, %{
               from: "sender@example.com",
               to: [],
               subject: "Test",
               html: "<p>Hi</p>"
             })

    assert error.name == "validation_error"
    assert error.message == "The to field is required."
    assert error.status_code == 422
  end
end
