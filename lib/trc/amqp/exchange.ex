defmodule Trc.AMQP.Exchange do
  @moduledoc """
    Receives messages from Producer and pushes to the Queues
  """

  # Typespecs
  @type channel :: %AMQP.Channel{}
  @type exchange_name :: String.t()
  @type payload :: String.t()
  @type queue_name :: String.t()

  @doc """
    Declares an Exchange and binds it to a Queue
  """
  @callback declare_and_bind(channel(), exchange_name(), queue_name()) :: :ok
  @spec declare_and_bind(channel(), exchange_name(), queue_name(), opts :: list()) :: :ok
  def declare_and_bind(channel, exchange_name, queue_name, opts \\ []) do
    # Select fanout as the message sending type
    type = Keyword.get(opts, :type, :fanout)

    AMQP.Exchange.declare(channel, exchange_name, type)
    AMQP.Queue.bind(channel, queue_name, exchange_name)
  end

  @doc """
    Publishes a message to an exchange. The message will be routed to queues as defined by the
    exchange configuration and distributed to any subscribers.
  """
  @callback publish(channel(), exchange_name(), payload()) :: :ok
  @spec publish(channel(), exchange_name(), payload(), routing_key :: String.t()) :: :ok
  def publish(channel, exchange_name, payload, routing_key \\ "") do
    AMQP.Basic.publish(channel, exchange_name, routing_key, payload)
  end

  @spec get_name(String.t()) :: String.t()
  def get_name(dataset_name), do: "#{dataset_name}_ex"
end
