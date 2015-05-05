class Metybur::Collection
  def initialize(collection_name, websocket)
    websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      if attributes[:msg] == 'added' && attributes[:collection] == collection_name
        @added_callback.call(attributes[:id], attributes[:fields])
      end
    end
  end

  def on(event, &block)
    @added_callback = block 
  end
end
