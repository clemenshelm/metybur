class Metybur::Collection
  def initialize(collection_name, websocket)
    @collection_name = collection_name
    @callbacks = {}
    self.websocket = websocket
  end

  def websocket=(websocket)
    return if websocket == @websocket
    @websocket = websocket

    websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      handle_message(attributes) if attributes[:collection] == @collection_name
    end
  end

  def on(event, &block)
    callbacks_for(event) << block
    self
  end

  private

  def handle_message(attributes)
    event = attributes[:msg].to_sym
    arguments = attributes.slice(:id, :fields, :cleared).values
    callbacks_for(event).each { |callback| callback.call(*arguments) }
  end

  def callbacks_for(event)
    @callbacks[event] ||= []
  end
end
