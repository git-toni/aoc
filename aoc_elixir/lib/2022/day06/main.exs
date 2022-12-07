defmodule Parser do
  use Agent
  @marker_size 14

  def start_link(_opts) do
    initial = %{marker: [], count: 0}
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

    #File.stream!(filename)  
    #|> Stream.each(& parse_line(agent, &1))
    #|> Enum.to_list

    #get(agent, :piles)
    #|> tap(fn x ->
    #  m = x |> Enum.map(& Enum.at(&1, 0))
    #  IO.inspect(m)
    #  IO.inspect(m |> Enum.join())
    #end)
    #|> tap(&IO.inspect(&1, label: "final"))

    read_file = File.open!(filename, [:read, :binary])
    IO.puts("readfile")
    read_char(agent, read_file)
  end
  def is_marker?(marker) do
    marker 
    |> Enum.uniq
    |> Kernel.length
    |> Kernel.==(@marker_size)
  end
  def expected_length?(marker) do
    marker 
    |> Kernel.length
    |> Kernel.==(@marker_size)
  end
  def read_char(agent, file) do 
    marker = get(agent, :marker)
    count = get(agent, :count)
    char = IO.binread(file, 1)
    cond do
      length(marker) < @marker_size ->
        new_marker = marker ++ [char]
        put(agent, :count, count + 1)
        put(agent, :marker, new_marker)
        read_char(agent, file)
      expected_length?(marker) and not is_marker?(marker) ->
        [_ | tail] = marker
        new_marker = tail ++ [char]
        put(agent, :count, count + 1)
        put(agent, :marker, new_marker)
        read_char(agent, file)
      true ->
        IO.puts("It is a marrrrker #{marker} count #{count}")
    end
  end
end

#file_url = Path.expand(__ENV__.file <>"/../input-test.txt")
file_url = Path.expand(__ENV__.file <>"/../input.txt")
Parser.start(file_url)

