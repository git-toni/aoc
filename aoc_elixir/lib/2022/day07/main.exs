#defmodule FsElement do
#  defstruct type: nil, size: 0, children: [], name: nil, parent: nil, path: []
#end

defmodule Parser do
  use Agent
  @less_than 100_000
  @total_fd 70_000_000
  @required_fd 30_000_000

  def start_link() do
    initial = %{
      #fs: %{_meta: %{size: 0, path: [""], parent: [""]}},
      fs: %{},
      cwd: [],
      less_than: [],
      dir_sizes: []
    }
    Agent.start_link(fn -> initial end)
  end

  def get(agent, key) do
    Agent.get(agent, &Map.get(&1, key))
  end
  def filesystem(agent) do
    get(agent, :fs)
  end
  def pwd(agent) do
    get(agent, :cwd)
  end
  def update_size(agent, path, new_size) do
    fs = filesystem(agent)
    size_path = path ++ [:_meta, :size]
    new_fs = fs |> put_in(size_path, new_size)
    put(agent, :fs, new_fs) 
  end
  def add_less_than(agent, new_size) do
    less_than = 
      get(agent, :less_than)
      |> Kernel.++([new_size])
    put(agent, :less_than, less_than) 
  end
  def put(agent, key, value) do
    Agent.update(agent, &Map.put(&1, key, value))
  end
  
  def register_dir_size(agent, new_size) do
    dir_sizes = 
      get(agent, :dir_sizes)
      |> Kernel.++([new_size])
    put(agent, :dir_sizes, dir_sizes) 
  end
  def process_cmd(agent, ["cd", ".."]) do
    cwd = pwd(agent)
    new_cwd = cwd |> List.delete_at(-1)
    put(agent, :cwd, new_cwd)
  end
  def process_cmd(agent, ["cd", arg]) do
    cwd = pwd(agent)
    fs = filesystem(agent)
    new_cwd = cwd ++ [arg]
    new_dir = %{_meta: %{ type: :dir, size: 0, name: arg }}
    new_fs = fs |> put_in(new_cwd, new_dir)
    
    put(agent, :fs, new_fs)
    put(agent, :cwd, new_cwd)
  end
  def process_cmd(agent, ["ls"]), do: nil
  def read_command(agent, line) do
    line = line |> String.replace_prefix("$ ", "")
    cmd = line |> String.split(" ")
    process_cmd(agent, cmd)
  end
  def read_ls_item(agent, line) do
    cwd = pwd(agent)
    fs = filesystem(agent)
    [dir_or_size, name] = line |> String.split(" ")
    new_cwd = cwd ++ [name]
    new_element = 
      case dir_or_size do
        "dir" ->
          %{_meta: %{ type: :dir, size: 0, name: name }}
        filesize ->
          %{_meta: %{ type: :file, size: String.to_integer(filesize), name: name }}
      end
    new_fs = fs |> put_in(new_cwd, new_element)

    put(agent, :fs, new_fs)
  end
  def directory_size(agent, path) do
    fs = filesystem(agent)
    element = fs |> Kernel.get_in(path)
    children = 
      element 
      |> Map.drop([:_meta]) 
      |> Map.to_list

    dir_size = 
      children 
      |> Enum.map(fn {_elname, child} ->
        #IO.inspect(child, label: "ENum map child")
        case child do
          %{_meta: %{type: :file, size: filesize}} ->
            filesize
          %{_meta: %{type: :dir, name: dirname}} ->
            new_path = path ++ [dirname]
            directory_size(agent, new_path)
        end
      end)
      |> Enum.sum
    #IO.inspect(dir_size, label: "diiiiiii")
    update_size(agent, path, dir_size)
    if dir_size <= @less_than do
      add_less_than(agent, dir_size)
    end
    if length(path) > 1, do: register_dir_size(agent, dir_size)
    dir_size
    #IO.inspect(path, label: "dirosizo")
    #IO.inspect(dir_size, label: "dirosizzzzz")
  end
  def smallest_delete(agent) do
    fs_size = filesystem(agent) |> Kernel.get_in(["/", :_meta, :size])
    dir_sizes = get(agent, :dir_sizes)
    needed_fd =  fs_size - (@total_fd - @required_fd)
    filtered_dirs =
      dir_sizes
      |> Enum.filter(& &1 >= needed_fd)
      |> Enum.sort
    IO.inspect([fs_size, needed_fd], label: "FDSS")
    IO.inspect(filtered_dirs)
    #element = fs |> Kernel.get_in(path)
  end
  def start(filename) do
    {:ok, agent} = start_link()

    fifi =
      File.stream!(filename) 
      |> Enum.each(fn line ->
        line = String.trim_trailing(line)
        cond do
          String.starts_with?(line, "$") ->
            read_command(agent, line)
          true ->
            read_ls_item(agent, line)
        end
      end)
    directory_size(agent, ["/"])
    #update_size(agent, ["/", "a"], 444)
    filesystem(agent)
    |> IO.inspect(label: "the fs")


    get(agent, :less_than)
    |> tap(&IO.inspect(&1, label: "less than list"))
    |> Enum.sum
    |> IO.inspect(label: "less than")

    get(agent, :dir_sizes)
    |> IO.inspect(label: "dir sizes")

    smallest_delete(agent)
  end
end

#file_url = Path.expand(__ENV__.file <>"/../input-test.txt")
file_url = Path.expand(__ENV__.file <>"/../input.txt")
Parser.start(file_url)

