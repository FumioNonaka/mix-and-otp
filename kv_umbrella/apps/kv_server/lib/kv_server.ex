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
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg =
      # case read_line(socket) do
      #   {:ok, data} ->
      #     case KVServer.Command.parse(data) do
      #       {:ok, command} ->
      #         KVServer.Command.run(command)
      #       {:error, _} = err ->
      #         err
      #     end
      #   {:error, _} = err ->
      #     err
      # end
      with {:ok, data} <- read_line(socket),
        {:ok, command} <- KVServer.Command.parse(data),
        do: KVServer.Command.run(command)
  
    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    # {:ok, data} = 
    :gen_tcp.recv(socket, 0)
    # data
  end
  
  # defp write_line(line, socket) do
  defp write_line(socket, {:ok, text}) do
    # :gen_tcp.send(socket, line)
    :gen_tcp.send(socket, text)
  end
  
  defp write_line(socket, {:error, :unknown_command}) do
    # 予め定めたエラーはクライアントに書き込む。
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end
  
  defp write_line(_socket, {:error, :closed}) do
    # 接続が閉じたらきちんと終了する。
    exit(:shutdown)
  end
  
  defp write_line(socket, {:error, :not_found}) do
    :gen_tcp.send(socket, "NOT FOUND\r\n")
  end  
  
  defp write_line(socket, {:error, error}) do
    # 不明なエラーはクライアントに書き込んで終了する。
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end  
end
