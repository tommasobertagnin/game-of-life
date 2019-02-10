defmodule Mix.Tasks.Start do
  use Mix.Task

  def run(_), do: GameOfLife.begin()
end