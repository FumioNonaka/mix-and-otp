defmodule KV.Bucket do
  use Agent
  @doc """
  新たな`Bbucket`をつくる。
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end
  @doc """
  `bucket`から`key`で値を得る。
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end
  @doc """
  `bucket`の`key`に`value`を与える。
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end
  @doc """
  `bucket`から`key`を除きます。`key`が存在していたら、その値を返します。
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
end
