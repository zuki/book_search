defmodule BookSearch.PageController do
  use BookSearch.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
