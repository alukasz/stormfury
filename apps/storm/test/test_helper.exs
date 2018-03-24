{:ok, _} = Node.start(:"storm_test@#{Application.fetch_env!(:storm, :host)}")

:erlang.set_cookie(node(), :stormcookie)

ExUnit.start()
