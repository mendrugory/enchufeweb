# Enchufeweb

[![hex.pm](https://img.shields.io/hexpm/v/enchufeweb.svg?style=flat-square)](https://hex.pm/packages/enchufeweb) [![hexdocs.pm](https://img.shields.io/badge/docs-latest-green.svg?style=flat-square)](https://hexdocs.pm/enchufeweb/) [![Build Status](https://travis-ci.org/mendrugory/enchufeweb.svg?branch=master)](https://travis-ci.org/mendrugory/enchufeweb)


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

  * Definition of the Websocket Client
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
    defmodule Client2 do
      use Enchufeweb
      def handle_message(data, state) do 
        IO.inspect data
        {:ok, state}
      end
      def handle_connection(_, state) do
        {:reply, "Initial message",state}
      end
      def handle_disconnection(_, state), do: {:close, "end", state}
    end
  ```

  ## Test
  Run the tests.
  ```bash
  mix test 
  ```

