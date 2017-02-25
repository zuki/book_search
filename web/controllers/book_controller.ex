defmodule BookSearch.BookController do
  use BookSearch.Web, :controller

  def index(conn, %{"query" => query}) do
    books = BookSearch.Delegate.compute(query)
    render(conn, "index.json", books: books)
  end
end
