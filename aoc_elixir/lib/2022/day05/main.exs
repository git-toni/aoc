defmodule Parser do
  use Agent

  def start_link(_opts) do
    initial = %{piles: []}
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

    get(agent, :piles)
    |> tap(fn x ->
      m = x |> Enum.map(& Enum.at(&1, 0))
      IO.inspect(m)
      IO.inspect(m |> Enum.join())
    end)
    |> tap(&IO.inspect(&1, label: "final"))

  end

  def parse_line(agent, line) do 
    line = line |> String.replace_suffix("\n","")

    regex_number = ~r/\s(\d)\s+(\d)\s+(\d)\s$/
    regex_pile = ~r/((?:\s\s\s)|\[(\w)\])/
    regex_move = ~r/move (\d+) from (\d+) to (\d+)/

    cond do
      Regex.match?(regex_number, line) ->
        [[_ | _matches] | _] = Regex.scan(regex_number, line)
      Regex.match?(regex_pile, line) ->
        chunks = 
          line
          |> String.codepoints 
          |> Enum.chunk_every(4) 
          |> Enum.map(fn c ->
            c
            |> Enum.join
            |> String.trim
            |> String.replace("[","")
            |> String.replace("]","")
          end)
        matches = Regex.scan(regex_pile, line)
        piles = get(agent, :piles)
        new_piles =
          chunks
          |> Enum.with_index(fn element, idx ->
            old_pile = 
              case Enum.at(piles, idx) do
                nil -> []
                found -> found
              end
            case element do
              "" ->
                old_pile
              non_empty ->
                old_pile ++ [non_empty]
            end

          end)
        put(agent, :piles, new_piles)

      line == "" ->
        get(agent, :piles)
        |> IO.inspect(label: "Empty line, game starts with")

      Regex.match?(regex_move, line) ->
        [[_ | pos]] = Regex.scan(regex_move, line)
        [quantity, init, ending] = pos

        piles = get(agent, :piles)
        init = init |> String.to_integer |> Kernel.-(1)
        ending = ending |> String.to_integer |> Kernel.-(1)
        quantity = quantity |> String.to_integer 

        {new_elements, origin} = piles |> Enum.at(init) |> Enum.split(quantity)
        pre_destination =  piles |> Enum.at(ending)
            #destination = 
            #  new_elements 
            #  |> Enum.reverse
            #  |> Kernel.++(pre_destination)
        destination =  # Part 2
          new_elements 
          |> Kernel.++(pre_destination)

        piles = 
          piles
          |> List.replace_at(init, origin)
          |> List.replace_at(ending, destination)

        put(agent, :piles, piles)

      true ->
        IO.puts("rest")

    end
  end
end

#  ZHGSWRNVR
#file_url = Path.expand(__ENV__.file <>"/../input-test.txt")
file_url = Path.expand(__ENV__.file <>"/../input.txt")
Parser.start(file_url)

