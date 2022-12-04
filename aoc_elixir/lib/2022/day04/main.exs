defmodule Parser do
  use Agent

  def start_link(_opts) do
    initial = %{count: 0, count_partial: 0}
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

    IO.inspect(get(agent, :count), label: "full overlap: ")
    IO.inspect(get(agent, :count_partial), label: "Partial overlap: ")
  end

  def parse_ranges(line) do
    [actor1, actor2] = 
      line 
      |> String.replace_suffix("\n","")
      |> String.split(",")
    [actor1_start, actor1_end] =
      actor1
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)

    [actor2_start, actor2_end] =
      actor2
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)

    a1_range = actor1_start..actor1_end |> MapSet.new
    a2_range = actor2_start..actor2_end |> MapSet.new

    [a1_range, a2_range]
  end
  def parse_line(agent, line) do 
    [a1_range, a2_range] = parse_ranges(line)
    intersection = MapSet.intersection(a1_range, a2_range) |> MapSet.to_list

    if MapSet.subset?(a1_range, a2_range) or MapSet.subset?(a2_range, a1_range) do
      count = current_count(agent)
      set_count(agent, count + 1)
    end

    if intersection != [] do
      count_partial = get(agent, :count_partial)
      put(agent, :count_partial, count_partial + 1)
    end
  end
end

file_url = Path.expand(__ENV__.file <>"/../input.txt")
Parser.start(file_url)

