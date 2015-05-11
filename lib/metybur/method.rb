class Metybur::Method
  def initialize(name, websocket)
    require 'securerandom'

    @name = name
    @websocket = websocket
    @callbacks = {}

    @websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      handle_message(attributes) if attributes[:msg] == 'result'
    end
  end

  def call(params, &block)
    id = SecureRandom.uuid
    message = {
      msg: 'method',
      id: id,
      method: @name,
      params: params
    }.to_json
    @websocket.send message
    @callbacks[id] = block
  end

  private

  def handle_message(attributes)
    id = attributes[:id]
    @callbacks[id].call attributes[:result] if @callbacks[id]
  end
end
