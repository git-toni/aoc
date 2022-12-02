defmodule Parser do
  use Agent

  @opponent_codes %{
    "A" => :Rock,
    "B" => :Paper,
    "C" => :Scissor,
  }
  @my_codes %{
    "X" => :Rock,
    "Y" => :Paper,
    "Z" => :Scissor,
  }
  @my_codes_part2 %{
    "X" => :loose,
    "Y" => :draw,
    "Z" => :win
  }
  @rules %{
    Rock: %{ wins: :Scissor, shape_point: 1, loses: :Paper},
    Paper: %{ wins: :Rock, shape_point: 2, loses: :Scissor},
    Scissor: %{ wins: :Paper, shape_point: 3, loses: :Rock},
  }

  def start_link(_opts) do
    initial = %{count: 0}
    Agent.start_link(fn -> initial end)
  end

  def get(agent, key) do
    Agent.get(agent, &Map.get(&1, key))
  end

  def put(agent, key, value) do
    Agent.update(agent, &Map.put(&1, key, value))
  end

  def start(filename, :part2) do
    {:ok, agent} = start_link(nil)

    File.stream!(filename)  
    |> Stream.each(& parse_line_part2(agent, &1))
    |> Enum.to_list

    
    IO.inspect(get(agent, :count))
  end
  def start(filename) do
    {:ok, agent} = start_link(nil)

    File.stream!(filename)  
    |> Stream.each(& parse_line(agent, &1))
    |> Enum.to_list

    
    IO.inspect(get(agent, :count))
  end

  def extract_moves(game) do
    game 
    |> String.replace_suffix("\n", "") 
    |> String.split(" ")
  end
  def parse_line(agent, game) do 
    [opponent_game, my_game] = extract_moves(game)

    opponent = @opponent_codes |> Map.fetch!(opponent_game)
    me = @my_codes |> Map.fetch!(my_game)

    opponent_features = @rules |> Map.fetch!(opponent)
    my_features = @rules |> Map.fetch!(me)

    game_points = 
      cond do
        my_features.wins == opponent -> 
          6
        opponent_features.wins == me -> 
          0
        true -> 
          3
      end
    
    new_points =  game_points + @rules[me].shape_point
    count = get(agent, :count)
    put(agent, :count, count + new_points) 
  end
  def parse_line_part2(agent, game) do 
    [opponent_game, my_game] = extract_moves(game)

    opponent = @opponent_codes |> Map.fetch!(opponent_game)
    opponent_features = @rules |> Map.fetch!(opponent)

    my_intention = @my_codes_part2 |> Map.fetch!(my_game)

    {my_move, game_points} =
      case my_intention do
        :loose ->
          {opponent_features.wins, 0}
        :draw ->
          {opponent, 3}
        :win ->
          {opponent_features.loses, 6}
      end
    new_points =  game_points + @rules[my_move].shape_point
    count = get(agent, :count)
    put(agent, :count, count + new_points) 
  end
end


file_url = Path.expand(__ENV__.file <>"/../input.txt")
Parser.start(file_url)
Parser.start(file_url, :part2)

