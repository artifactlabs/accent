defmodule Accent.Plug.Response do
  @moduledoc """
  Transforms the keys of an HTTP response to the case requested by the client.

  A client can request what case the keys are formatted in by passing the case
  as a header in the request. By default the header key is `Accent`. If the
  client does not request a case or requests an unsupported case then no
  conversion will happen. By default the supported cases are `camel`, `pascal`
  and `snake`.

  ## Options

  * `:header` - the HTTP header used to determine the case to convert the
    response body to before sending the response (default: `Accent`)
  * `:json_encoder` - module used to encode JSON. The module is expected to
    define a `encode!/1` function for encoding the response body as JSON.
    (required)
  * `:json_decoder` - module used to decode JSON. The module is expected to
    define a `decode!/1` function for decoding JSON into a map. (required)
  * `:supported_cases` - map that defines what cases a client can request. By
    default `camel`, `pascal` and `snake` are supported.

  ## Examples

  ```
  plug Accent.Plug.Response, header: "x-accent",
                             supported_cases: %{"pascal" => Accent.Transformer.PascalCase},
                             json_encoder: Poison,
                             json_decoder: Poison
  ```
  """

  import Plug.Conn
  import Accent.Transformer

  @default_cases %{
    "camel" => Accent.Transformer.CamelCase,
    "pascal" => Accent.Transformer.PascalCase,
    "_pascal" => Accent.Transformer.PascalWithLeadingUnderscoreCase,
    "snake" => Accent.Transformer.SnakeCase
  }

  @default_accent nil
  @default_content_type "application/json"

  @doc false
  def init(opts \\ []) do
    %{
      header: Keyword.get(opts, :header, "accent"),
      json_decoder:
        opts[:json_decoder] ||
          raise(ArgumentError, "Accent.Plug.Response expects a :json_decoder option"),
      json_encoder:
        opts[:json_encoder] ||
          raise(ArgumentError, "Accent.Plug.Response expects a :json_encoder option"),
      supported_cases: opts[:supported_cases] || @default_cases,
      default_accent: opts[:default_accent] || @default_accent,
      content_type: Keyword.get(opts, :content_type, @default_content_type)
    }
  end

  @doc false
  def call(conn, opts) do
    if do_call?(conn, opts) do
      conn
      |> register_before_send(fn conn -> before_send_callback(conn, opts) end)
    else
      conn
    end
  end

  # private

  defp jsonable?(conn, opts) do
    response_content_type =
      conn
      |> get_resp_header("content-type")
      |> Enum.at(0)

    content_type =
      conn
      |> get_req_header("content-type")
      |> Enum.at(0)

      opts[:content_type] == nil or
      (String.contains?(response_content_type || "", opts[:content_type]) and
      String.contains?(content_type || "", opts[:content_type]))
  end

  defp before_send_callback(conn, opts) do
    # Note - we don't support "+json" content types, and probably shouldn't add
    # as a general feature because they may have specifications for the param
    # names - e.g. https://tools.ietf.org/html/rfc7265#page-6 that mean the
    # translation would be inappropriate
    if jsonable?(conn, opts) == true do
      json_decoder = opts[:json_decoder]
      json_encoder = opts[:json_encoder]

      resp_body =
        conn.resp_body
        |> json_decoder.decode!
        |> transform(select_transformer(conn, opts))
        |> json_encoder.encode!

      %{conn | resp_body: resp_body}
    else
      conn
    end
  end

  defp do_call?(conn, opts) do
    is_json = jsonable?(conn, opts)

    has_transformer = select_transformer(conn, opts)

    is_json && has_transformer
  end

  defp default_accent(nil, opts), do: opts[:default_accent]
  defp default_accent(accent, _), do: accent

  defp get_request_accent(_conn, nil) do
    [nil]
  end

  defp get_request_accent(conn, accent_header) do
    get_req_header(conn, accent_header)
  end

  defp select_transformer(conn, opts) do
    accent = get_request_accent(conn, opts[:header]) |> Enum.at(0) |> default_accent(opts)
    supported_cases = opts[:supported_cases]

    supported_cases[accent]
  end
end
