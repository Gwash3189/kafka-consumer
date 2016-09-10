# Kafka consumer

Scalable consumer for Kafka using kafka_ex, poolboy and elixir.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

* Add `kafka_consumer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:kafka_consumer, "~> 1.0"]
end
```

* Ensure `kafka_consumer` and `gproc` is started before your application:

```elixir
def application do
  [applications: [:kafka_consumer, :gproc]]
end
```

## Usage

* Set config or pass default attributes

```elixir
config :kafka_ex,
  brokers: [{"localhost", 9092}],
  consumer_group: "kafka_ex" ,
  sync_timeout: 3000,
  max_restarts: 10,
  max_seconds: 60
```

* Write your own EventHandler. Functions start_link/1 and handle_event/2 is overridable

```elixir
defmodule EventHandler do
  use KafkaConsumer.EventHandler

  def handle_cast({topic, _partition, message}, state) do
    Logger.debug "from #{topic} message: #{inspect message}"
    {:noreply, state}
  end
end
```

* Set event handlers in config.

```elixir
config :kafka_consumer,
  default_pool_size: 5,
  default_pool_max_overflow: 10,
  event_handlers: [
    {KafkaConsumer.TestEventHandler, [{"topic", 0}, {"topic2", 0}], size: 5, max_overflow: 5}
  ]
```

* Start your app.

### No Consumer Group support

If your Kafka setup does not support does not support consumer groups, then it is possible to still use KafkaConsumer. To still use KafkaConsumer you must

* Set `offset_server` to a module that `use`'s `KafkaConsumer.OffsetServer`

```elixir
# config.exs

config :kafka_ex,
  brokers: [{"localhost", 9092}],
  consumer_group: :no_consumer_group,
  sync_timeout: 3000,
  max_restarts: 10,
  max_seconds: 60


config :kafka_consumer,
  default_pool_size: 5,
  default_pool_max_overflow: 10,
  offset_server: YourModule.OffsetServer
  event_handlers: [
    {KafkaConsumer.TestEventHandler, [{"topic", 0}, {"topic2", 0}], size: 5, max_overflow: 5}
  ]

# offset_server.ex

defmodule YourModule.OffsetServer do
  use KafkaConsumer.OffsetServer
end
```

KafkaConsumer will then query this server for the current offset when appropriate.

#### Starting the OffsetServer

The OffsetServer is a `GenServer` and **must be started by you, and supervised by you**.

It is started by calling `start_link/1`. You must provide the topic when starting the server, as the server will be named after your topic

```elixir
#starts a GenServer with a name of :that_one_topic
YouModule.OffsetServer.start_link("that.one.topic")
```

#### Incrementing, Decrementing and Getting the offset

Upon startup, KafkaConsumer will get get the **latest offset** from `KafkaEx`. After that, you must increment or decrement the offset yourself. This can be done through the `increment/1` and `decrement/1` functions. They both take the topic as the first parameter.

```elixir
YourModule.OffsetServer.increment("that.one.topic") # :ok
YourModule.OffsetServer.decrement("that.one.topic") # :ok
YourModule.OffsetServer.get("that.one.topic") # offset
```

please see the the offset server [behaviour](lib/kafka_consumer/offset_server.ex) for more details on what it does and does not support.

## Configuration

`event_handlers` key in configuration accepts list of tuples `{handler_module, topics, opts}`, where you can omit options parameter and worker use default values (acceptable for pool size and max_overflow).
