defmodule BookSearch.Delegate do
  @moduledoc false
  require Logger

  @backends [BookSearch.Cinii, BookSearch.Ndl]

  def start_link(backend, query, query_ref, owner, limit) do
    Logger.debug("BookSearch.Delegate.start_link start")
    backend.start_link(query, query_ref, owner, limit)
  end

  def compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    backends = opts[:backends] || @backends

    results =
      backends
      |> Enum.map(&spawn_query(&1, query, limit))
      |> await_results(opts)
      |> Enum.sort(&(&1.title <= &2.title))
    merge(results) |> Enum.sort(&(&1.title <= &2.title))
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(BookSearch.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    Logger.info("spawned: backend: #{backend}, pid: #{inspect pid}, monitor_ref: #{inspect monitor_ref}, query_ref: #{inspect query_ref}")
    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000
    timer = Process.send_after(self(), :timeout, timeout)
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head
    Logger.debug("await: pid: #{inspect pid}, monitor_ref: #{inspect monitor_ref}, query_ref: #{inspect query_ref}")
    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
      :timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end

  defp await_result([], acc, _) do
    acc
  end

  defp kill(pid, ref) do
    Logger.debug("kill: pid: #{inspect pid}, monitor_ref: #{inspect ref}")
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    receive do
      :timeout -> :ok
    after
      0 -> :ok
    end
  end

  defp merge(bibs), do: _merge(bibs, [])
  defp _merge([], acc), do: acc
  defp _merge([head|tail], acc) do
    unless head.isbn do
      bib = Map.put(head, :link, [%{:backend => head.backend, :url => head.url}])
          |> Map.drop([:backend, :url])
      _merge(tail, [bib|acc])
    else
      case Enum.find(acc, nil, fn(bib) -> bib.isbn == head.isbn end) do
        nil ->
          bib = Map.put(head, :link, [%{:backend => head.backend, :url => head.url}])
              |> Map.drop([:backend, :url])
          _merge(tail, [bib|acc])
        bib ->
          merged = Map.update!(bib, :link, fn(l) -> [%{:backend => head.backend, :url => head.url}|l] end)
          acc = acc |> List.delete(bib) |> List.insert_at(-1, merged)
          _merge(tail, acc)
      end
    end
  end

end
