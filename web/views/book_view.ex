defmodule BookSearch.BookView do
  use BookSearch.Web, :view

  def render("index.json", %{books: books}) do
    %{data: render_many(books, BookSearch.BookView, "book.json")}
  end

  def render("book.json", %{book: book}) do
    %{title: book.title,
      author: book.author,
      url: book.url,
      backend: book.backend}
  end
end
