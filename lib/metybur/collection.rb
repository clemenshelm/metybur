class Metybur::Collection
  def initialize(name, websocket)
    websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      if attributes[:msg] == 'added'
        @added_callback.call(attributes[:id], attributes[:fields])
      end
    end
  end

  def on(event, &block)
    @added_callback = block 
  end
end
