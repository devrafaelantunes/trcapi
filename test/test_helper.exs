ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Trc.Repo, :manual)

Mox.defmock(Trc.Publisher.FileIOMock, for: Trc.Publisher.FileIO)
Mox.defmock(Trc.AMQP.ExchangeMock, for: Trc.AMQP.Exchange)
Mox.defmock(Trc.AMQP.QueueMock, for: Trc.AMQP.Queue)
