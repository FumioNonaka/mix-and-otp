defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do  # setupを追加
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  # test "stores values by key" do
  test "stores values by key", %{bucket: bucket} do
    {:ok, bucket} = KV.Bucket.start_link([])
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end
