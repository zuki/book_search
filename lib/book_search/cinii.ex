defmodule BookSearch.Cinii do
  import SweetXml
  #alias BookSearch.Result
  require Logger

  @http Application.get_env(:book_search, :cinii)[:http_client] || HTTPoison

  def start_link(query, query_ref, owner, limit) do
    Logger.debug("CiNii start: owner: #{inspect owner}, query_ref: #{inspect query_ref}")
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    query_str
    |> fetch_xml()
    |> send_results(query_ref, owner)
  end

  defp send_results([], query_ref, owner) do
    send(owner, {:results, query_ref, []})
  end

  defp send_results(bibs, query_ref, owner) do
    Logger.debug("CiNii send_result: owner: #{inspect owner}, bibs: #{inspect bibs}, query_ref: #{inspect query_ref}")
    results =
      bibs
      |> Enum.map(fn (result) ->
        Map.merge(%{backend: "CiNii"}, result) end)
    send(owner, {:results, query_ref, results})
  end

  defp fetch_xml(query_str) do
    url = "http://ci.nii.ac.jp/books/opensearch/search?q=#{URI.encode(query_str)}"
       <> "&format=atom&count=10&appid=#{token()}"
    case @http.get url do
      {:ok, %HTTPoison.Response{status_code: 200, body: xml}} ->
        xml
        |> xpath(
          ~x"//feed/entry"l,
          title: ~x"./title/text()"s,
          url: ~x"./id/text()"s,
          author: ~x"./author/name/text()"sl,
          publisher: ~x"./dc:publisher/text()"s,
          date: ~x"./prism:publicationDate/text()"s,
          isbn: ~x"./dcterms:hasPart/text()"sl
        )
        |> Enum.map(fn (m) -> Map.update!(m, :author, &Enum.join(&1, ", ")) end)
        |> Enum.map(fn (m) -> Map.update!(m, :isbn, &Enum.at(&1, 0))end)
        |> Enum.map(fn (m) -> Map.update!(m, :isbn, fn(v) -> unless v, do: "", else: String.slice(v, 9..-1)end)end)
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.warn("HTTP Status: #{code}")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warn("HTTP Error: #{reason}")
        []
    end
  end

  defp token, do: Application.get_env(:book_search, :cinii)[:token]
end
