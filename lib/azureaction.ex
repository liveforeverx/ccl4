defmodule AzureAction do

  def create_table do
    AzureClient.azreq(:undefined, 'Tables', '', :azure_helplib.create_table 'contacttable')
  end

  def delete_table do
    AzureClient.azreq(:undefined, 'Tables(\'contacttable\')', '', '', :delete)
  end

  def lookup_row row do
    path = 'contacttable'
    path2 = '()?$filter=RowKey%20eq%20\'' ++ :erlang.integer_to_list(row) ++ '\''
    AzureClient.azreq(:undefined, path, "", :get, path2)
  end

  def user_to_table do
    spawn_client(1)
  end
  def user_to_table(i, _) when i < 1 do
    :ok
  end
  def user_to_table(i, n, client // :undefined) do
    user_to_table i, n, client, gen_user i
  end
  def user_to_table(i, n, client, xml) do
    try do
      {code, _, _, client} = AzureClient.azreq(client, 'contacttable', '', xml)
      if code == 201 do
        IO.puts "create: #{inspect(i)}"
        :timer.sleep(1000)
        user_to_table(i - n, n)
      else
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
