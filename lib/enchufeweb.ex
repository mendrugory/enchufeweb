defmodule Enchufeweb do
  @moduledoc """
  Enchufeweb is a websocket client library written in Elixir and based on 
  the Erlang library [websocket_client](https://hex.pm/packages/websocket_client).

  ## Installation
  Add `enchufeweb` to your list of dependencies in `mix.exs`:
  ```elixir
  def deps do
    [{:enchufeweb, "~> 0.1.0"}]
  end
  ```
  ## How to use it

  * Implementation of the Websocket Client
  ```elixir
    defmodule Client do
      use Enchufeweb
      def handle_message(data, state) do 
        IO.inspect data
        {:ok, state}
      end
      def handle_connection(_, state), do: {:ok, state}
      def handle_disconnection(_, state), do: {:close, "end", state}
    end
  ```

  * Connect the client and send a message
  ```bash
  iex> {:ok, client} = Client.start_link([url: "ws://localhost:8888/websocket", ws_opts: %{conn_mode: :once}]) 
  iex> Client.ws_send(client, "Hola")
  ```

  * Send a `ping`
  ```bash
  iex> Client.ws_send(client, :ping)
  ```

  * Close the connection
  ```bash
  iex> Client.ws_send(client, :close)
  ```

  * Client which will send a message just after the connection
  ```elixir
    defmodule Client do
      use Enchufeweb
      def handle_message(data, state) do 
        IO.inspect data
        {:ok, state}
      end
      def handle_connection(_, state), do: {:reply, "Initial message", state}
      def handle_disconnection(_, state), do: {:close, "end", state}
    end
  ```

  ## Test
  Run the tests.
  ```bash
  mix test 
  ```
  """

  @type frame :: :close | :ping | :pong | binary
  @type conn_mode :: :disconnected | :once | :reconnect
  @type websocket_req :: map
  @type state :: any


  @doc """
  Callback which will be called when a message is received.

  The argument has to be a binary message or one of these atoms: :close, :ping or :pong

  Output:
  * {:ok, state} : nothing occurs
  * {:reply, reply, state} : It will send `reply` to the server.
  * {:close, reason, state} : It will close the connection due to `reason`.
  """
  @callback handle_message(frame, state) :: {:ok, state} 
                                            | {:reply, frame, state} 
                                            | {:close, binary, state}
  
  @doc """
  Callback which will be called when the connection has been made.

  Input:
  * Websocket request information
  * Current state

  Output:
  * {:ok, state}
  * {:ok, keepalive, state} : `keepalive` will be the interval in ms for sending pings to the server.
  * {:reply, reply, state} : It will directly send `reply` to the server.
  * {:close, reason, state} : It will close the connection due to `reason`.
  """
  @callback handle_connection(websocket_req, state) :: {:ok, state} 
                                                       | {:ok , number, state} 
                                                       | {:reply, frame, state} 
                                                       | {:close, binary, state}
  
  @doc """
  Callback which will be called when the connection is closed

  Input:
  * Websocket request information
  * Current state

  Output:
  * {:ok, state} : The process continues although the connection is closed.
  * {:reconnect, state} : It tries to reconnect.
  * {:reconnect, delay, state} : It tries to reconnect after `delay` ms.
  * {:close, reason, state} : It terminates the process.
  """
  @callback handle_disconnection(websocket_req, state) :: {:ok, state} 
                                                          | {:reconnect, state} 
                                                          | {:reconnect, integer, state} 
                                                          | {:close, binary, state}

  defmacro __using__(_) do
    quote do
      @behaviour Enchufeweb
      require Logger

      @msg_after_conn_time    10

      def start_link(args) do
        {:ok, url} = Keyword.fetch(args, :url)
        :websocket_client.start_link(url, __MODULE__, args)
      end

      def ws_send(ws, message) do 
        frame = make_frame(message)
        :websocket_client.cast(ws, frame)
      end

      def init(args) do
        conn_mode = 
          with {:ok, ws_opts} <- Keyword.fetch(args, :ws_opts),
               {:ok, conn_mode} <- Map.fetch(ws_opts, :conn_mode),
          do: conn_mode
        mode = if conn_mode == :disconnected, do: :ok, else: conn_mode
        :crypto.start()
        :ssl.start()
        {mode, args}
      end

      def onconnect(msg, state) do
        case handle_connection(msg, state) do
          {:reply, reply, new_statte} ->
            Process.send_after(self(), make_frame(reply), @msg_after_conn_time)
            {:ok, new_statte}
          response ->
            response
        end
      end

      def ondisconnect(reason, state), do: handle_disconnection(reason, state)

      def websocket_info(msg, _conn_state, state), do: {:reply, msg, state}    
    
      def websocket_terminate(_msg, _conn_state, _state), do: :ok

      def websocket_handle({type, msg}, _conn_state, state) do
        data =
          cond do
            type == :ping -> :ping
            type == :pong -> :pong
            type == :close -> :close
            msg == "" -> type
            true -> msg
          end
        case handle_message(data, state) do
          {:reply, reply, new_statte} ->
            {:reply, make_frame(reply), new_statte}
          {:close, reason, new_statte} ->
            {:close, reason, state}
          _ ->
            {:ok, state}
        end 
      end

      defp make_frame(data) do
        cond do
          is_atom(data) -> 
            data
          is_binary(data) -> 
            if String.valid?(data), do: {:text, data}, else: {:binary, data}
        end
      end
    end
  end

  @doc """
  It will start (linked) the websocket client.

  The argument will be a keyword list:
  * url: String. For instance `ws://host:port/endpoint`
  * ws_opts: It has to be a map which has to contain the connection mode (`%{conn_mode: conn_mode}`)
      * :disconnected : It will begin with the client in a disconnected mode
      * :once : It only tries one connection
      * :reconnect : It will try to reconnect until it get it
  """
  @spec start_link([url: binary, ws_opts: map]) :: {:ok, pid} | {:error, term}
  def start_link([url: url, ws_opts: ws_opts]) do
    :websocket_client.start_link(url, __MODULE__, ws_opts)
  end

  @doc """
  It will send the given message using the given websocket(pid)
  """
  @spec ws_send(pid, frame) :: :ok
  def ws_send(ws, message), do: :websocket_client.cast(ws, message)

end
