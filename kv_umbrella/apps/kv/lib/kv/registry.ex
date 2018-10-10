defmodule KV.Registry do
  use GenServer

  ## クライアントAPI
	@doc """
	登録を始める。

	引数のオプションには`:name`が必須。
	"""
	def start_link(opts) do
		# [1]GenServerのintに名前を渡す。
		server = Keyword.fetch!(opts, :name)
		# GenServer.start_link(__MODULE__, :ok, opts)
		GenServer.start_link(__MODULE__, server, opts)
	end

	@doc """
	`server`に納められた`name`のプロセスのpidを探す。

	プロセスがあれば`{：ok、pid}`を返し、見つからないときは`：error`を返す。
	"""
	def lookup(server, name) do
		# [2]lookupはサーバーでなく、ETSで直接行う。
		# GenServer.call(server, {:lookup, name})
		case :ets.lookup(server, name) do
			[{^name, pid}] -> {:ok, pid}
			[] -> :error
		end
	end

  @doc """
  `server`に`name`の与えられたプロセスがあることを請け合う。
  """
	def create(server, name) do
		# GenServer.cast(server, {:create, name})
		GenServer.call(server, {:create, name})
	end

  ## サーバーコールバック
	# def init(:ok) do
	def init(table) do
		# [3]マップnamesをETSテーブルで置き替える。
		# names = %{}
		names = :ets.new(table, [:named_table, read_concurrency: true])
		refs = %{}
		{:ok, {names, refs}}
	end

	# [4]lookupのコールバックhandle_callは以下に置き替える。
	# def handle_call({:lookup, name}, _from, {names, _} = state) do
	# 	{:reply, Map.fetch(names, name), state}
	# end

	# def handle_cast({:create, name}, {names, refs}) do
	def handle_call({:create, name}, _from, {names, refs}) do
		# [5]マップでなくETSテーブルに読み書きする。
		case lookup(names, name) do
			# {:ok, _pid} ->
			{:ok, pid} ->
				# {:noreply, {names, refs}}
				{:reply, pid, {names, refs}}
			:error ->
				{:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
				ref = Process.monitor(pid)
				refs = Map.put(refs, ref, name)
				:ets.insert(names, {name, pid})
				# {:noreply, {names, refs}}
				{:reply, pid, {names, refs}}
		end
	end

	def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
		# [6]マップでなくETSテーブルから削除する。
		{name, refs} = Map.pop(refs, ref)
		# names = Map.delete(names, name)
		:ets.delete(names, name)
		{:noreply, {names, refs}}
	end

	def handle_info(_msg, state) do
		{:noreply, state}
	end
end
