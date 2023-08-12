defmodule CorrodemoWeb.APIController do
  use CorrodemoWeb, :controller

  def show(conn, _params) do
    inspect(Corrodemo.GenSandwich.get_sandwich()) |> IO.puts()
    with sandwich <- Corrodemo.GenSandwich.get_sandwich() do
      json(conn, %{status: "good", sandwich: sandwich})
    else
      _ -> json(conn, %{status: "bad", sandwich: "none"})
    end
  end

end
