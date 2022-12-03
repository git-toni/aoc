defmodule Parser do
  use Agent

  @lower_range 97..122
  @upper_range 65..90

  def start_link(_opts) do
    initial = %{count: 0}
    Agent.start_link(fn -> initial end)
  end

  def current_count(agent) do
    get(agent, :count)
  end
  def set_count(agent, count) do
    put(agent, :count, count)
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

    IO.inspect(get(agent, :count))
  end

  def start_part2(filename) do
    {:ok, agent} = start_link(nil)

    File.stream!(filename)  
    |> Stream.chunk_every(3)
    |> Stream.each(& parse_line_part2(agent, &1))
    |> Enum.to_list

    IO.inspect(get(agent, :count))
  end
  def parse_line_part2(agent, entries) do 
    [entry1, entry2, entry3] = 
      entries 
      |> Enum.map(& 
        String.replace_suffix(&1, "\n", "") 
        |> String.codepoints
        |> Enum.uniq
      )
    common = 
      entry1
      |> Enum.filter(& Enum.member?(entry2, &1) and Enum.member?(entry3, &1))
      |> Enum.at(0)

    count = current_count(agent)
    new_points = priority_points(common)
    set_count(agent, count + new_points)
    IO.puts("---- #{current_count(agent)}")
  end
  def priority_points(item) do
    lower_index = @lower_range |> Enum.find_index(& &1 == :binary.first(item) )
    upper_index = @upper_range |> Enum.find_index(& &1 == :binary.first(item) )
    cond do
      is_integer lower_index -> # belongs to the lower range
        lower_index + 1

      is_integer upper_index ->
        upper_index + 27
    end
  end
  def parse_line(agent, line) do 
    line = line |> String.replace_suffix("\n","")
    compartment_size = String.length(line)/2 |> trunc
    {left, right} = line |> String.split_at(compartment_size)
    left = String.codepoints(left) |> Enum.uniq
    right = String.codepoints(right) |> Enum.uniq

    # Find only common items
    common = 
      (left -- ( left -- right ) )
      |> Enum.at(0)
    count = current_count(agent)
    new_points = priority_points(common)
    set_count(agent, count + new_points)

    IO.puts("---- #{current_count(agent)}")
  end
end

# Part1
#file_url = Path.expand(__ENV__.file <>"/../input.txt")
#Parser.start(file_url)

# Part2
file_url = Path.expand(__ENV__.file <>"/../input-part2.txt")
Parser.start_part2(file_url)
