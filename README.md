# Websockex

[![hex.pm](https://img.shields.io/hexpm/v/websockex.svg?style=flat-square)](https://hex.pm/packages/websockex) [![hexdocs.pm](https://img.shields.io/badge/docs-latest-green.svg?style=flat-square)](https://hexdocs.pm/websockex/) [![Build Status](https://travis-ci.org/mendrugory/websockex.svg?branch=master)](https://travis-ci.org/mendrugory/websockex)


  Websockex is a websocket client library written in Elixir and based on 
  the Erlang library [websocket_client](https://hex.pm/packages/websocket_client).

  ## Installation
  Add `websockex` to your list of dependencies in `mix.exs`:
  ```elixir
  def deps do
    [{:websockex, "~> 0.1.0"}]
  end
  ```
  ## How to use it

  * Definition of the Websocket Client
  ```elixir
    defmodule Client do
      use Websockex
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
      use Websockex
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
  """

