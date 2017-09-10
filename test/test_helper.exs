defmodule WebsocketHandler do
  @behaviour :cowboy_websocket  
  
  def init(req, state) do
    :erlang.start_timer(1000, self(), [])
    {:cowboy_websocket, req, state}
  end        

  def websocket_handle({:text, msg}, req, state) do
    reply =  
      case Poison.decode(msg) do
        {:ok, %{"data_type" => "greeting", "data" => "hola"}} -> 
          %{"data_type" => "greeting", "source" => "server", "data" => "adios"}
        {:ok, %{"data_type" => "message", "data" => data}} -> 
          %{"data_type" => "message", "source" => "server", "data" => "Server received: " <> data}
        {:ok, %{"data_type" => "increment", "data" => data}} -> 
          %{"data_type" => "increment", "source" => "server", "data" => data + 1}
        _ -> :no_matter
      end
    if reply == :no_matter do
      {:ok, req, state}
    else
      {:reply, {:text, Poison.encode!(reply)}, req, state}
    end
  end

  def websocket_handle({:binary, msg}, req, state) do
    {:reply, {:binary, msg}, req, state}
  end

  def websocket_handle(msg, req, state), do: {:reply, msg, req, state}

  def websocket_info({_timeout, _ref, msg}, req, state), do: { :reply, {:text, msg}, req, state}  
  def terminate(_reason, _req, _state), do: :ok
end

defmodule Server do
    require Logger
    def start() do
      Logger.info("Server starts ...")  
      dispatch_config = :cowboy_router.compile([{ :_, [{"/websocket", WebsocketHandler, []}]}])      
      { :ok, _ } = 
        :cowboy.start_http(:http, 100, [{:port, 8888}], 
          [{ :env, [{:dispatch, dispatch_config}]}])  
    end
end

Server.start()

ExUnit.start()
