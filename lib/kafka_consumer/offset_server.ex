defmodule KafkaConsumer.OffsetServer do
  @type offset :: number
  @type noreply :: {:noreply, offset}
  @type reply :: {:reply, offset, offset}
  @type topic :: String.t

  @callback increment(topic) :: noreply
  @callback decrement(topic) :: noreply
  @callback get(topic) :: reply
  @callback save(topic) :: reply
  @callback start_link(topic) :: {:ok, pid}


  defmacro __using__(_) do
    quote do
      @type offset :: number
      @type noreply :: {:noreply, offset}
      @type reply :: {:reply, offset, offset}
      @type topic :: String.t

      @moduledoc """
      Holds the last processed offset
      All servers are registerd with an atom of the topic

      `start_link("that.one.topic")` will register a server under `:that_one_topic`
      """
      use GenServer

      @behaviour KafkaConsumer.OffsetServer

      def start_link(topic) do
        name = make_server_name(topic)
        GenServer.start_link(
          __MODULE__,
          get_latest_offset(topic),
          name: name,
          id: name
        )
      end

      @doc """
      increments the offset
      """
      @spec increment(topic) :: noreply
      def increment(topic) do
        GenServer.cast(make_server_name(topic), :increment)
      end

      @doc """
      decrements the offset
      """
      @spec decrement(topic) :: noreply
      def decrement(topic) do
        GenServer.cast(make_server_name(topic), :decrement)
      end

      @doc """
      saves the offset
      """
      @spec increment(topic) :: noreply
      def save(topic) do
        GenServer.cast(make_server_name(topic), :save)
      end

      @doc """
      gets the offset
      """
      @spec get(topic) :: reply
      def get(topic) do
        GenServer.call(make_server_name(topic), :get)
      end

      @doc """
      handles the increment of the offset
      """
      @spec handle_cast(atom, offset) :: noreply
      def handle_cast(:increment, offset) do
        {:noreply, offset + 1}
      end

      @doc """
      handles the decrement of the offset
      """
      @spec handle_cast(:decrement, offset) :: noreply
      def handle_cast(:decrement, offset) do
        {:noreply, offset - 1}
      end
      @doc """
      handles the saving of the offset
      """
      @spec handle_cast(:save, offset) :: noreply
      def handle_cast(:save, offset) do
        {:noreply, offset}
      end

      @doc """
      handles the getting of the offset
      """
      @spec handle_call(:get, any, offset) :: reply
      def handle_call(:get, _, offset) do
        {:reply, offset, offset}
      end


      @doc """
      gets the offset from the kafka topic.
      Defaults to the latest_offset
      """
      @spec get_latest_offset(topic) :: offset
      def get_latest_offset(topic) do
        response = KafkaEx.latest_offset(topic, 0)

        response
          |> Enum.at(0)
          |> Map.get(:partition_offsets)
          |> Enum.at(0)
          |> Map.get(:offset)
          |> Enum.at(0)
      end

      @doc """
      makes the server name from a topic
      """
      @spec make_server_name(topic) :: atom
      defp make_server_name(topic) do
        String.to_atom(String.replace(topic, ".", "_"))
      end

      defoverridable [
        start_link: 1,
        handle_cast: 2,
        handle_call: 3,
        get: 1,
        save: 1,
        decrement: 1,
        increment: 1,
        make_server_name: 1,
        get_latest_offset: 1
      ]
    end
  end
end
