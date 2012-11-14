defmodule User do

  def gen_user j do
    [Adress: :azure_helplib.simple_id,
     Name: :azure_helplib.simple_id,
     Salary: :crypto.rand_uniform(20000, 100000),
     Timestamp: :azure_helplib.timestamp,
     RowKey: :erlang.integer_to_list(j),
     Position: position( :crypto.rand_uniform(0, 100)),
     PartitionKey: part_key j]
  end

  def part_key(j) when j < 1500 do
    'USA' ++ '_PLZ' ++ :erlang.integer_to_list( :crypto.rand_uniform(10000, 99999) )
  end
  def part_key(j) when j > 3000 do
    'Germany' ++ '_PLZ' ++ :erlang.integer_to_list( :crypto.rand_uniform(10000, 99999) )
  end
  def part_key _ do
    'UK' ++ '_PLZ' ++ :erlang.integer_to_list( :crypto.rand_uniform(10000, 99999) )
  end

  def position(i) when i < 50 do
    'Developer'
  end
  def position(i) when i > 90 do
    'Manager'
  end
  def position _ do
    'Tester'
  end
end
