defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {KV.Registry, name: KV.Registry}  # 順序変更
    ]
    # Supervisor.init(children, strategy: :one_for_one)
    Supervisor.init(children, strategy: :one_for_all)
  end
end
