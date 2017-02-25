defmodule BookSearch.Ndl do
  import SweetXml
  alias BookSearch.Result
  require Logger

  @http Application.get_env(:book_search, :ndl)[:http_client] || HTTPoison

  def start_link(query, query_ref, owner, limit) do
    Logger.debug("NDL start: owner: #{inspect owner}, query_ref: #{inspect query_ref}")
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
    Logger.debug("NDL send_result: owner: #{inspect owner}, bibs: #{inspect bibs}, query_ref: #{inspect query_ref}")
    results =
      bibs
      |> Enum.map(fn (result) ->
        Map.merge(%Result{backend: "ndl"}, result) end)
    send(owner, {:results, query_ref, results})
  end

  defp fetch_xml(query_str) do
    q = %{
      "operation" => "searchRetrieve",
      "recordPacking" => "xml",
      "recordSchema" => "dcndl_simple",
      "maximumRecords" => "10",
      "query" => "anywhere=\"#{query_str}\" AND dpid=\"iss-ndl-opac\""
    }
    encoded_query = q |> URI.encode_query() |> String.replace(~r/\+/, "%20")
    url = "http://iss.ndl.go.jp/api/sru?#{encoded_query}"
    case @http.get url do
      {:ok, %HTTPoison.Response{status_code: 200, body: xml}} ->
        xml
        |> xpath(
          ~x"//searchRetrieveResponse/records/record/recordData/dcndl_simple:dc"l,
          title: ~x"./dc:title/text()"s,
          url: ~x"./rdfs:seeAlso/@rdf:resource"sl,
          author: ~x"./dc:creator/text()"sl,
          publisher: ~x"./dc:publisher/text()"sl,
          date: ~x"./dcterms:issued/text()"s,
          isbn: ~x"./dc:identifier[@xsi:type='dcndl:ISBN']/text()"sl
        )
        |> Enum.map(fn (m) -> Map.update!(m, :url, &Enum.at(&1, 0))end)
        |> Enum.map(fn (m) -> Map.update!(m, :author, &Enum.at(&1, 0))end)
        |> Enum.map(fn (m) -> Map.update!(m, :publisher, &Enum.at(&1, 0))end)
        |> Enum.map(fn (m) -> Map.update!(m, :isbn, &Enum.at(&1, 0))end)
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.warn("HTTP Status: #{code}")
        []
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warn("HTTP Error: #{reason}")
        []
    end
  end

end
