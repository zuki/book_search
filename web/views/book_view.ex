defmodule BookSearch.BookView do
  use BookSearch.Web, :view

  def render("index.json", %{books: books}) do
    %{data: render_many(books, BookSearch.BookView, "book.json")}
  end

  def render("book.json", %{book: book}) do
    link = Enum.map(book.link, fn(l) -> %{url: l.url, backend: l.backend} end)
    %{title: book.title,
      author: book.author,
      publisher: book.publisher,
      date: book.date,
      isbn: book.isbn,
      link: link
    }
  end
end
