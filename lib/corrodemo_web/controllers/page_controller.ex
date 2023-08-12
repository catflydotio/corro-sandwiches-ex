defmodule CorrodemoWeb.PageController do
  use CorrodemoWeb, :controller

  def sandwich(conn, _params) do
    inspect(Corrodemo.GenSandwich.get_sandwich()) |> IO.puts()
    with sandwich <- Corrodemo.GenSandwich.get_sandwich() do

      render(conn, :sandwich, sandwich: sandwich)
    else
      _ -> render(conn, :sandwich, sandwich: "default")
    end
  end

end
