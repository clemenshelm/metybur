class Metybur::Collection
  def initialize(collection_name, websocket)
    websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      handle_message(attributes) if attributes[:collection] == collection_name
    end
  end

  def on(event, &block)
    case event
    when :added then @added_callback = block
    when :changed then @changed_callback = block
    end
  end

  private

  def handle_message(attributes)
    case attributes[:msg]
    when 'added'
      @added_callback.call(attributes[:id], attributes[:fields])
    when 'changed'
      @changed_callback.call(attributes[:id], attributes[:fields], attributes[:fields])
    end
  end
end
