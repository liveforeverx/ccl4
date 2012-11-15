defmodule AzureClient do

  def azreq(path, path2, payload, method // :post, headers // []) do
    azreqcl(:undefined, path, path2, payload, method, headers)
  end

  def azreqcl(client, path, path2, payload, method // :post, headers // []) do
    headersToSign = [{'x-ms-date', :httpd_util.rfc1123_date},
                     {'Content-Type', 'application/atom+xml'}] ++ headers
    authorization = auth_header(path, method, headersToSign, key)
    headers = [{"Authorization", 'SharedKey ' ++ account ++ ':' ++ authorization},
               {"Content-Length", size_of(payload)}] ++ headersToSign
    request client, method, headers, payload, build_url, path ++ path2
  end

  def request(client, method // :get, headers // [], payload // '', url // '', path // '') do
    options = []
    headers = lc {headerKey, value} inlist headers, do: {tobin(headerKey), value}
    :hackney_dev.call client, method, url, path, headers, payload, options
  end

  defp auth_header(path, httpMethod, headersToSign, key,  contentType // 'application/atom+xml') do
    {'x-ms-date', date} = :lists.keyfind('x-ms-date', 1, headersToSign)
    method = :string.to_upper(:erlang.atom_to_list (httpMethod))
    stringToSign = method ++ '\n\n' ++ contentType ++ '\n' ++ date ++ '\n/' ++ account ++ '/' ++ path
    # IO.puts "string to sign: #{inspect(stringToSign)}"

    decodedKey = :base64.decode key
    :erlang.binary_to_list(:base64.encode(:hmac256.digest(:erlang.binary_to_list(decodedKey), stringToSign)))
  end

  defp build_url table // '' do
    'http://' ++ account ++'.table.core.windows.net/' ++ table
  end

  defp account do
    {:ok, account} = :application.get_env(:ccl4, :account)
    account
  end

  defp key do
    {:ok, key} = :application.get_env(:ccl4, :azure_key)
    key
  end

  defp tobin(list) when is_list(list) do
    :erlang.list_to_binary list
  end

  defp tobin bin do
    bin
  end

  defp size_of(list) when is_list(list) do
    :erlang.length(list)
  end

  defp size_of(bin) when is_binary(bin) do
    :erlang.size(bin)
  end
end
