class Metybur::Collection
  def initialize(collection_name, websocket)
    @callbacks = {}

    websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      handle_message(attributes) if attributes[:collection] == collection_name
    end
  end

  def on(event, &block)
    callback_for(event: event) << block
    self
  end

  private

  def handle_message(attributes)
    event = attributes[:msg].to_sym
    arguments = attributes.slice(:id, :fields, :cleared).values
    callback_for(event: event).each { |callback| callback.call(*arguments) }
  end

  def callback_for(event:)
    @callbacks[event] ||= []
  end
end
