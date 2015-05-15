class Metybur::PingPongMiddleware
  def initialize(websocket)
    # TODO: This dependency is dowdy. Get rid of it.
    @websocket = websocket
  end

  def open(event)
    event
  end

  def message(message)
    return message unless message[:msg] == 'ping'
    pong = {msg: 'pong'}
    pong[:id] = message[:id] if message[:id]
    @websocket.send(pong.to_json)
    message
  end

  def close(event)
    event
  end
end
