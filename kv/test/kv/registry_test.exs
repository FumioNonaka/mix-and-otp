defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  # setup do
  setup context do
    # registry = start_supervised!(KV.Registry)
    _ = start_supervised!({KV.Registry, name: context.test})
    # %{registry: registry}
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
	end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)
    # 登録プロセスに:DOWNメッセージを遅らせるための呼び出し
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    # プロセスを正常でない理由で止める
    Agent.stop(bucket, :shutdown)
    # 登録プロセスに:DOWNメッセージを遅らせるための呼び出し
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
