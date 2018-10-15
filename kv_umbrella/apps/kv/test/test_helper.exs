exclude =
  if Node.alive?, do: [], else: [distributed: true]  # 追加

# ExUnit.start()
ExUnit.start(exclude: exclude)
