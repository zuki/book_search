defmodule BookSearch.BookTest do
  use BookSearch.ModelCase

  alias BookSearch.Book

  @valid_attrs %{author: "some content", backend: "some content", title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Book.changeset(%Book{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Book.changeset(%Book{}, @invalid_attrs)
    refute changeset.valid?
  end
end
