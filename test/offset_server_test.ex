defmodule KafkaConsumer.OffsetServerTest do
  use ExUnit.Case, async: false
  import Mock

  @the_topic_string "the.topic"
  @the_topic_atom :the_topic

  def mock_lastest_offset do
    fn(_topic, _partition) -> [%{partition_offsets: [%{offset: [0]}]}] end
  end

  describe "when start_link/1 is called with a string" do
    test "it starts a GenServer" do
      with_mock KafkaEx, [latest_offset: mock_lastest_offset] do
        {:ok, pid} = KafkaConsumer.TestOffsetServer.start_link(@the_topic_string)

        assert pid
      end
    end

    test "it registers the GenServer under the topic" do
      with_mock KafkaEx, [latest_offset: mock_lastest_offset] do
        {:ok, pid} = KafkaConsumer.TestOffsetServer.start_link(@the_topic_string)

        assert Process.whereis(@the_topic_atom) == pid
      end
    end
  end

  describe "behaviour" do
    setup do
      with_mock KafkaEx, [latest_offset: mock_lastest_offset] do
        KafkaConsumer.TestOffsetServer.start_link(@the_topic_string)
      end

      {:ok, []}
    end


    test "it increments the offset" do
      KafkaConsumer.TestOffsetServer.increment(@the_topic_string)

      assert KafkaConsumer.TestOffsetServer.get(@the_topic_string) == 1
    end

    test "it decrements the offset" do
      KafkaConsumer.TestOffsetServer.decrement(@the_topic_string)

      assert KafkaConsumer.TestOffsetServer.get(@the_topic_string) == -1
    end

    test "it gets the offset" do
      assert KafkaConsumer.TestOffsetServer.get(@the_topic_string)
    end
  end
end
