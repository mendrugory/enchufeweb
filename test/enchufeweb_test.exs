defmodule EnchufewebTest do
  use ExUnit.Case
  doctest Enchufeweb

  test "send/receive message" do
    Process.register(self(), :test1)

    defmodule Client1 do
      use Enchufeweb
      require Logger
      def handle_message("", state), do: {:ok, state}
      def handle_message(data, state) do 
        send(:test1, Poison.decode!(data))
        {:ok, state}
      end
      def handle_connection(_, state), do: {:ok, state}
      def handle_disconnection(_, state), do: {:close, "end", state}
    end

    {:ok, client} = Client1.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}])
    Process.sleep 100
    Client1.ws_send(client, Poison.encode!(%{"data_type" => "greeting", "data" => "hola"}))
    
    receive do
      msg  ->
        assert msg == %{"data_type" => "greeting", "source" => "server", "data" => "adios"}
    after
      100 -> 
        assert false
    end
  end


  test "ping" do
    Process.register(self(), :test2)

    defmodule Client2 do
      use Enchufeweb
      require Logger
      def handle_message(msg, state) do 
        send(:test2, msg)
        {:ok, state}
      end
      def handle_connection(_req, state), do: {:ok, state}
      def handle_disconnection(_req, state), do: {:close, "end", state}
    end

    {:ok, client} = Client2.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}])
    Process.sleep 100
    Client2.ws_send(client, :ping)
    
    
    receive do
      msg ->
        assert msg == :pong
    after
      100 -> 
        assert false
    end
  end

  test "send and receive binary data" do
    Process.register(self(), :test3)

    defmodule Client3 do
      use Enchufeweb
      require Logger
      def handle_message("", state), do: {:ok, state}
      def handle_message(data, state) do 
        send(:test3, data)
        {:ok, state}
      end
      def handle_connection(_req, state), do: {:ok, state}
      def handle_disconnection(_req, state), do: {:close, "end", state}
    end

    {:ok, client} = Client3.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}])
    Process.sleep 100
    Client3.ws_send(client, <<0xFFFF :: 16 >>)
    
    
    receive do
      msg ->
        assert msg == <<0xFFFF :: 16>>
    after
      100 -> 
        assert false
    end
  end

  test "close" do
    Process.register(self(), :test4)

    defmodule Client4 do
      use Enchufeweb
      require Logger
      def handle_message(_, state), do: {:ok, state}
      def handle_connection(_req, state), do: {:ok, state}
      def handle_disconnection(req, state) do 
        send(:test4, req)
        Process.sleep(100)
        {:close, "end", state}
      end 
    end

    {:ok, client} = Client4.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}])
    Process.sleep 100
    Client4.ws_send(client, :close)
    
    receive do
      msg ->
        assert msg == {:remote, :closed}
    after
      100 -> 
        assert false
    end
  end

  test "pong" do
    Process.register(self(), :test5)

    defmodule Client5 do
      use Enchufeweb
      require Logger
      def handle_message(msg, state) do 
        send(:test5, msg)
        {:ok, state}
      end
      def handle_connection(_req, state), do: {:ok, state}
      def handle_disconnection(_req, state), do: {:close, "end", state}
    end

    {:ok, client} = Client5.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}])
    Process.sleep 100
    Client5.ws_send(client, :pong)
    
    
    receive do
      msg ->
        assert msg == :pong
    after
      100 -> 
        assert false
    end
  end

  test "send/receive message just after connection" do
    Process.register(self(), :test6)

    defmodule Client6 do
      use Enchufeweb
      require Logger
      def handle_message("", state), do: {:ok, state}
      def handle_message(data, state) do 
        send(:test6, Poison.decode!(data))
        {:ok, state}
      end
      def handle_connection(_, state) do
        {:reply, Poison.encode!(%{"data_type" => "greeting", "data" => "hola"}), state}
      end
      def handle_disconnection(_, state), do: {:close, "end", state}
    end

    {:ok, _client} = Client6.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}])
    Process.sleep 100
    
    receive do
      msg ->
        assert msg == %{"data_type" => "greeting", "source" => "server", "data" => "adios"}
    after
      100 -> 
        assert false
    end
  end

end
