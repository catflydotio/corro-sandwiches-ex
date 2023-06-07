defmodule CorrodemoWeb.PageController do
  use CorrodemoWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout. (changed that-CAN)
    render(conn, :home)
  end
end
