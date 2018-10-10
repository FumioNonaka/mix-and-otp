require Logger

defmodule KVServer do
  def accept(port) do
    # オプションの機能はつぎのとおり:
    #
    # 1. `:binary` - データをバイナリとして受け取る(リストでなく)
    # 2. `packet: :line` - データを1行ずつ受け取る
    # 3. `active: false` - データが受け取れるようになるまで`:gen_tcp.recv/2`を待たせる
    # 4. `reuseaddr: true` - リスナーが落ちたときアドレスを再利用できるようにする
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    # serve(client)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)  # 追加
    :ok = :gen_tcp.controlling_process(client, pid)  # 追加
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
