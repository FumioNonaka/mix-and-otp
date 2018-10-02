defmodule KV.Registry do
  use GenServer

  ## クライアントAPI
  @doc """
  登録を始める。
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  `server`に納められた`name`のプロセスのpidを探す。

  プロセスがあれば`{：ok、pid}`を返し、見つからないときは`：error`を返す。
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  `server`に`name`の与えられたプロセスがあることを請け合う。
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## サーバーコールバック
	def init(:ok) do
		names = %{}
		refs = %{}
		{:ok, {names, refs}}
	end
	
	def handle_call({:lookup, name}, _from, {names, _} = state) do
		{:reply, Map.fetch(names, name), state}
	end

	def handle_cast({:create, name}, {names, refs}) do
		if Map.has_key?(names, name) do
			{:noreply, {names, refs}}
		else
			# {:ok, pid} = KV.Bucket.start_link([])
			{:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
			ref = Process.monitor(pid)
			refs = Map.put(refs, ref, name)
			names = Map.put(names, name, pid)
			{:noreply, {names, refs}}
		end
	end

	def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
		{name, refs} = Map.pop(refs, ref)
		names = Map.delete(names, name)
		{:noreply, {names, refs}}
	end

	def handle_info(_msg, state) do
		{:noreply, state}
	end
end
