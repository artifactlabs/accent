defmodule Accent.Plug.ResponseTest do
  use ExUnit.Case
  use Plug.Test

  @default_opts [json_decoder: Poison, json_encoder: Poison]

  @opts Accent.Plug.Response.init(json_decoder: Poison, json_encoder: Poison)
  @opts_nil_content Accent.Plug.Response.init(
                      json_decoder: Poison,
                      json_encoder: Poison,
                      content_type: nil
                    )
  @opts_text_content Accent.Plug.Response.init(
                       json_decoder: Poison,
                       json_encoder: Poison,
                       content_type: "text/html"
                     )
  @opts_text_content_and_jason Accent.Plug.Response.init(
                                 json_decoder: Jason,
                                 json_encoder: Jason,
                                 content_type: "text/html"
                               )
  @opts_with_default_accent Accent.Plug.Response.init(
                              json_decoder: Poison,
                              json_encoder: Poison,
                              default_accent: "pascal"
                            )
  @opts_with_default_accent_and_a_nil_header Accent.Plug.Response.init(
                                               json_decoder: Poison,
                                               json_encoder: Poison,
                                               default_accent: "pascal",
                                               header: nil
                                             )

  describe "init/1" do
    test "sets the \"header\" option to the value passed in" do
      opts = Accent.Plug.Response.init(@default_opts ++ [header: "x-accent"])

      assert %{header: "x-accent"} = opts
    end

    test "defaults the \"header\" option to \"accent\"" do
      opts = Accent.Plug.Response.init(@default_opts)

      assert %{header: "accent"} = opts
    end

    test "sets the \"json_decoder\" option to the value passed in" do
      opts = Accent.Plug.Response.init(@default_opts)

      assert %{json_decoder: Poison} = opts
    end

    test "raises ArgumentError if \"json_decoder\" is not defined" do
      assert_raise ArgumentError, fn ->
        Accent.Plug.Response.init(json_encoder: Poison)
      end
    end

    test "sets the \"json_encoder\" option to the value passed in" do
      opts = Accent.Plug.Response.init(@default_opts)

      assert %{json_encoder: Poison} = opts
    end

    test "raises ArgumentError if \"json_encoder\" is not defined" do
      assert_raise ArgumentError, fn ->
        Accent.Plug.Response.init(json_decoder: Poison)
      end
    end

    test "sets the \"supported_cases\" option to the value passed in" do
      opts =
        Accent.Plug.Response.init(
          @default_opts ++ [supported_cases: %{"test" => "some transformer"}]
        )

      assert %{supported_cases: %{"test" => "some transformer"}} = opts
    end

    test "defaults the \"supported_cases\" option" do
      opts = Accent.Plug.Response.init(@default_opts)

      assert %{
               supported_cases: %{
                 "camel" => Accent.Transformer.CamelCase,
                 "pascal" => Accent.Transformer.PascalCase,
                 "_pascal" => Accent.Transformer.PascalWithLeadingUnderscoreCase,
                 "snake" => Accent.Transformer.SnakeCase
               }
             } = opts
    end
  end

  describe "call/2" do
    test "converts keys based on value passed to header" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"helloWorld\":\"value\"}"
    end

    test "converts _id to camel" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "camel")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"_id\":\"_id\",\"_mongo_id\":\"_mongo_id\",\"normal_test\":\"normal_test\",\"single\":\"single\"}")

      assert conn.resp_body == "{\"Single\":\"single\",\"NormalTest\":\"normal_test\",\"MongoId\":\"_mongo_id\",\"Id\":\"_id\"}"
    end

    test "converts _id to pascal" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"_id\":\"_id\",\"_mongo_id\":\"_mongo_id\",\"normal_test\":\"normal_test\",\"single\":\"single\"}")

      assert conn.resp_body == "{\"single\":\"single\",\"normalTest\":\"normal_test\",\"mongoId\":\"_mongo_id\",\"id\":\"_id\"}"
    end

    test "converts _id to snake" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"_id\":\"_id\",\"_mongo_id\":\"_mongo_id\",\"normal_test\":\"normal_test\",\"single\":\"single\"}")

      assert conn.resp_body == "{\"single\":\"single\",\"normalTest\":\"normal_test\",\"mongoId\":\"_mongo_id\",\"id\":\"_id\"}"
    end

    test "converts _id to _pascal" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "_pascal")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"_id\":\"_id\",\"_mongo_id\":\"_mongo_id\",\"normal_test\":\"normal_test\",\"single\":\"single\"}")

        assert conn.resp_body == "{\"single\":\"single\",\"normalTest\":\"normal_test\",\"_mongoId\":\"_mongo_id\",\"_id\":\"_id\"}"
    end

    test "deals with content-type having a charset" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "application/json; charset=utf-8")
        |> put_resp_header("content-type", "application/json; charset=utf-8")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"helloWorld\":\"value\"}"
    end

    test "uses the default conversion if one is provided" do
      conn =
        conn(:post, "/")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts_with_default_accent)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"helloWorld\":\"value\"}"
    end

    test "uses the header conversion if its present ignoring the default conversion" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "camel")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts_with_default_accent)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"HelloWorld\":\"value\"}"
    end

    test "ignores header conversion if it was initialized to nil" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "camel")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts_with_default_accent_and_a_nil_header)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"helloWorld\":\"value\"}"
    end

    test "skips conversion if no header and no default is provided" do
      conn =
        conn(:post, "/")
        |> put_req_header("content-type", "application/json")
        |> put_resp_header("content-type", "application/json")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"hello_world\":\"value\"}"
    end

    test "skips conversion if content type is not JSON" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "text/html")
        |> put_resp_header("content-type", "text/html")
        |> Accent.Plug.Response.call(@opts)
        |> Plug.Conn.send_resp(200, "<p>This is not JSON, but it includes some hello_world</p>")

      assert conn.resp_body == "<p>This is not JSON, but it includes some hello_world</p>"
    end

    test "can be initialized with a different content convention" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "text/html")
        |> put_resp_header("content-type", "text/html")
        |> Accent.Plug.Response.call(@opts_text_content)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"helloWorld\":\"value\"}"
    end

    test "errors if response is not JSON (Poison)" do
      assert_raise Poison.ParseError, fn ->
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "text/html")
        |> put_resp_header("content-type", "text/html")
        |> Accent.Plug.Response.call(@opts_text_content)
        |> Plug.Conn.send_resp(200, "<p>This is not JSON, but it includes some hello_world</p>")
      end
    end

    test "errors if response is not JSON (Jason)" do
      assert_raise Jason.DecodeError, fn ->
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> put_req_header("content-type", "text/html")
        |> put_resp_header("content-type", "text/html")
        |> Accent.Plug.Response.call(@opts_text_content_and_jason)
        |> Plug.Conn.send_resp(200, "<p>This is not JSON, but it includes some hello_world</p>")
        end
      end

    test "can be initialized to ignore content convention" do
      conn =
        conn(:post, "/")
        |> put_req_header("accent", "pascal")
        |> Accent.Plug.Response.call(@opts_nil_content)
        |> Plug.Conn.send_resp(200, "{\"hello_world\":\"value\"}")

      assert conn.resp_body == "{\"helloWorld\":\"value\"}"
    end
  end
end
