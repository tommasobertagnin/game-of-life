defmodule GameOfLife do
  alias Mix.Shell.IO, as: Shell
  alias GameOfLife.{Board, Cell}
  @refresh_time 300

  # SHELL PROMPT

  def begin do
    Shell.info(render_intro())

    Shell.prompt("Type the game size (eg. '3 3') then press 'enter' to watch it come alive:")
    |> String.trim()
    |> String.split(" ")
    |> Enum.take(2)
    |> Enum.map(&String.to_integer/1)
    |> initialize_game()
  end

  # GAME

  def initialize_game([w, h]) do
    create_board(w, h)
    |> game_loop()
  end

  def create_board(w, h) do
    cells =
      0..w*h-1
      |> Enum.map(fn i ->
        [x, y] = index_to_xy(w, i)
        %Cell{alive?: Enum.random([true, false]), x: x, y: y}
      end)

    %Board{cells: cells, w: w, h: h}
  end

  def game_loop(board) do
    render_game(board)
    :timer.sleep(@refresh_time)

    update_game_state(board)
    |> game_loop()
  end

  def get_cell(%Board{w: w, h: h} = board, x, y) do
    cell_inside_gameboard? =
      x >= 0 && x < w &&
      y >= 0 && y < h

    case cell_inside_gameboard? do
      true ->
        board.cells
        |> Enum.at(xy_to_index(board.w, x, y))

      false ->
        %Cell{alive?: false}
    end
  end

  def update_game_state(%Board{cells: cells} = board) do
    updated_cells =
      cells
      |> Enum.map(&update_cell_state(board, &1))

    %{ board | cells: updated_cells, iterations: board.iterations + 1 }
  end

  def update_cell_state(board, %Cell{x: x, y: y} = cell) do
    g = fn neighbor_x, neighbor_y -> get_cell(board, neighbor_x, neighbor_y) end

    live_neighbors_count =
      [ g.(x-1, y-1), g.(x, y-1), g.(x+1, y-1),
        g.(x-1, y),               g.(x+1, y),
        g.(x-1, y+1), g.(x, y+1), g.(x+1, y+1) ]
      |> Enum.filter(fn c -> c.alive? end)
      |> Enum.count()
    
    %{ cell | alive?: next_alive_state(live_neighbors_count, cell) }
  end

  def next_alive_state(live_neighbors_count, %Cell{alive?: curr_state}) do
    cond do
      live_neighbors_count == 2 -> curr_state
      live_neighbors_count == 3 -> true
      live_neighbors_count < 2 -> false
      live_neighbors_count > 3 -> false
    end
  end

  # RENDERING FUNCTIONS

  def render_intro do
    """

      +--------------------+
      |    GAME OF LIFE    |
      +--------------------+

      A shell version of the famous Game Of Life by John Conway
      entirely written in Elixir.

      To begin you need to choose the grid size, to get something
      like the example below (a 3x3 grid) just type width and height
      separated by a space '3 3'

      +---+---+---+
       ||| |||
               |||
       |||
      +---+---+---+

    """
  end

  def render_game(board) do
    board_string = 
      board.cells
      |> Enum.chunk_every(board.w)
      |> Enum.map(&render_row/1)
      |> Enum.join("\n\n")
    
    Shell.cmd("clear")
    Shell.info(render_h_line(board))
    Shell.info(board_string)
    Shell.info(render_h_line(board))
    Shell.info("\nw: #{board.w}, h: #{board.h}, iterations: #{board.iterations}\n")
  end

  def render_row(cells) do
    cells
    |> Enum.map(&render_cell/1)
    |> Enum.join(" ")
  end

  def render_cell(cell) do
    if cell.alive? do "|||" else "   " end
  end

  def render_h_line(board) do
    1..board.w
    |> Enum.map(fn _ -> "---" end)
    |> Enum.join("+")
  end

  # UTILITY FUNCTIONS

  def index_to_xy(w, i) do
    [rem(i, w), div(i, w)]
  end

  def xy_to_index(w, x, y) do
    y*w+x
  end
end
