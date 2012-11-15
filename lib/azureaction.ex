defmodule AzureAction do

  def ex4 do
    filters = ['?$filter=PartitionKey%20gt%20\'Germany_PLX\'%20and%20PartitionKey%20lt%20\'Germany_ZZZ\'%20and%20Position%20eq%20\'Developer\'',
               '?$filter=PartitionKey%20gt%20\'UK_PLX\'%20and%20PartitionKey%20lt%20\'UK_ZZZ\'%20and%20Position%20eq%20\'Developer\'',
               '?$filter=PartitionKey%20gt%20\'USA_PLX\'%20and%20PartitionKey%20lt%20\'USA_ZZZ\'%20and%20Position%20eq%20\'Developer\'']
    list = Enum.map filters, fn(filter) ->
      {_, headers, data, client} = AzureClient.azreq('contacttable', filter, '', :get)
      user = get_continuation client, headers, data
      {n, salary} = List.foldl(user, {0, 0}, fn({user}, {n, acc}) ->
                                                 {_, salary} = :lists.keyfind(:"Salary", 1, user)
                                                 salary = :erlang.list_to_integer salary
                                                 {n + 1, acc + salary}
                                             end
                               )
                      end
      lc {land, {n, salary}} inlist :lists.zip(["Germany", "UK", "USA"], list) do
        IO.puts "#{land}: #{inspect(salary / n)}"
      end
      :ok
  end

  def ex5 do
    filter = '?$filter=PartitionKey%20gt%20\'Germany_PLZ30000\'%20and%20PartitionKey%20lt%20\'Germany_PLZ80000\'%20and%20Position%20eq%20\'Manager\''
    {_, headers, data, client} = AzureClient.azreq('contacttable', filter, '', :get)
    user = get_continuation client, headers, data
    :erlang.length(user)
  end

  def create_table do
    AzureClient.azreq('Tables', '', :azure_helplib.create_table 'contacttable')
  end

  def delete_table do
    AzureClient.azreq('Tables(\'contacttable\')', '', '', :delete)
  end

  def get_all_user do
    {_, headers, data, client} = AzureClient.azreq('contacttable()', '', '', :get)
    user = get_continuation client, headers, data
    IO.puts "#{inspect(:erlang.length(user))}"
    File.write("users", "#{inspect(user)}", [:append])
  end

  defp get_continuation client, headers, data do
    all_data = get_all_user client, headers, [data]
    data = :lists.reverse all_data
    :lists.flatten( lc body inlist data do
      decoded = :xmlsimple_dec.decode(body)
      decode_user_cont decoded, []
    end)
  end

  defp get_all_user client, headers, datas do
    :hackney.close client
    case :lists.keyfind("x-ms-continuation-NextPartitionKey", 1, headers) do
      {_, hash} ->
        path = 'NextPartitionKey=' ++ :erlang.binary_to_list hash
        case :lists.keyfind("x-ms-continuation-NextRowKey", 1, headers) do
          {_, hash2} -> path = path ++ '&NextRowKey=' ++ :erlang.binary_to_list hash2
          _ -> :ok
        end
        {_, headers, data, client} = AzureClient.azreq('contacttable', '?' ++ path, '', :get)
        IO.puts "get continuation"
        get_all_user client, headers, [data | datas]
      _ ->
        IO.puts "ready"
        datas
     end
  end

  def get_user_by row do
    {200, _, body, _} = lookup_row row
    decbody = :xmlsimple_dec.decode(body)
    to_user decbody
  end

  defp decode_user_cont [], result do
    result
  end
  defp decode_user_cont decbody, result do
    {resultnew, next} = :xmlsimple_dec.extract_cont('m:properties', '/m:properties', decbody)
    if resultnew != [] do
      decode_user_cont next, [{to_user(resultnew)} | result]
    else
      decode_user_cont next, result
    end
  end

  defp to_user decbody do
    dec = fn(id) -> :xmlsimple_dec.extract(id, decbody) end
    [Adress: dec.('d:Adress'),
     Name: dec.('d:Name'),
     Salary: dec.('d:Salary'),
     Timestamp: dec.('d:Timestamp'),
     RowKey: dec.('d:RowKey'),
     Position: dec.('d:Position'),
     PartitionKey: dec.('d:PartitionKey')]
  end

  defp lookup_row row do
    path = 'contacttable()'
    path2 = '?$filter=RowKey%20eq%20\'' ++ :erlang.integer_to_list(row) ++ '\''
    AzureClient.azreq(path, path2, "", :get)
  end

  def user_to_table i do
    spawn_client i
  end
  def user_to_table(i, n) do
    IO.puts "start #{inspect(self)}"
    user_to_table(i, n, :undefined)
  end
  def user_to_table(i, _, _client) when i < 1 do
   # :hackney.close(client)
    :ok
  end
  def user_to_table(i, n, client) do
    user_to_table i, n, client, gen_user i
  end
  def user_to_table(i, n, client, xml) do
    try do
      {code, _, _, client} = AzureClient.azreqcl(client, 'contacttable', '', xml)
      :hackney.close client
      if (code == 201) or (code == 409) do
        IO.puts "create: #{inspect(i)} with code: #{inspect(code)}"
        user_to_table(i - n, n, :undefined)
      else
        :hackney.close(client)
        IO.puts "error: #{inspect(code)} identity #{inspect(i)}         "
        :timer.sleep(5000)
        user_to_table(i, n, :undefined, xml)
      end
    rescue
      error ->
        IO.puts "raised error #{inspect(error)} identity #{inspect(i)}     "
        :timer.sleep(15000)
        user_to_table(i, n, :undefined, xml)
    end
  end

  def spawn_client(n) when n < 1 do
    :ok
  end
  def spawn_client n do
    IO.puts "start client"
    Process.spawn(fn -> user_to_table(4501 - n, n) end)
    spawn_client(n - 1)
  end

  def toprop key do
    key = :erlang.atom_to_list(key)
    :erlang.list_to_atom('d:' ++ key)
  end

  def gen_user i do
    user = User.gen_user i
    f = function do
          {key, value} when is_integer(value) -> {key, [{:"m:type", "Edm.Int64"}], [:erlang.integer_to_list value]}
          {:Timestamp, value} -> {:Timestamp, [{:"m:type", "Edm.DateTime"}], [:erlang.binary_to_list value]}
          {key, value} when is_binary(value) -> {key, [:erlang.binary_to_list(value)]}
          {key, value} -> {key, [value]}
        end
    user = Enum.map user, f
    user = lc tuple inlist user, do: setelem(tuple, 0, toprop(elem(tuple, 0)))
    Xmltrans.to_xml [{:"m:properties", user}]
  end
end
