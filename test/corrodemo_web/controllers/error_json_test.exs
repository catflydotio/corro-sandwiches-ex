defmodule CorrodemoWeb.ErrorJSONTest do
  use CorrodemoWeb.ConnCase, async: true

  test "renders 404" do
    assert CorrodemoWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert CorrodemoWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
