defmodule Parser do
  use Agent


  @doc """
  Starts a new Parser
  """
  def start_link(_opts) do
    initial = %{max: 0, acc: 0}
    Agent.start_link(fn -> initial end)
  end

  def get(agent, key) do
    Agent.get(agent, &Map.get(&1, key))
  end

  def put(agent, key, value) do
    Agent.update(agent, &Map.put(&1, key, value))
  end

  def start(filename) do
    {:ok, agent} = start_link(nil)

    File.stream!(filename)  
    |> Stream.each(& parse_line(agent, &1))
    |> Enum.to_list
    
    IO.inspect(get(agent, :max))
  end
  def parse_line(agent, "\n") do
    max = get(agent, :max)
    acc = get(agent, :acc)
    if acc > max do
      put(agent, :max, acc) 
      put(agent, :acc, 0) 
    else
      put(agent, :acc, 0) 
    end
  end
  def parse_line(agent, calorie) do 
    acc = get(agent, :acc)
    calorie = String.replace_suffix(calorie, "\n", "")
    acc = acc + String.to_integer(calorie)
    put(agent, :acc, acc) 
  end
end


file_url = Path.expand(__ENV__.file <>"/../input.txt")
Parser.start(file_url)
