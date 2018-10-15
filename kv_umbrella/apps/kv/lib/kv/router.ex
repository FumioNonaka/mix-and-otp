defmodule KV.Router do
  @doc """
  与えられた`mod`の`fun`に`args`が渡された要求を
  プロセス`bucket`にもとづいて適切なノードに送る。
  """
  def route(bucket, mod, fun, args) do
    # バイナリの最初のバイトを得る
    first = :binary.first(bucket)

    # table()からエントリーを探してなければエラー
    entry =
      Enum.find(table(), fn {enum, _node} ->
        first in enum
      end) || no_entry_error(bucket)

    # エントリーが現ノードの場合
    if elem(entry, 1) == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect bucket} in table #{inspect table()}"
  end

  @doc """
  ルーティングテーブル
  """
  def table do
    # [{?a..?m, :"foo@computer-name"}, {?n..?z, :"bar@computer-name"}]
    Application.fetch_env!(:kv, :routing_table)
  end
end
