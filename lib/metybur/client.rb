require_relative 'collection'

class Metybur::Client
  def initialize(websocket)
    @websocket = websocket
  end

  def subscribe(record_set_name)
    message = {
      msg: 'sub',
      id: 'cde',
      name: record_set_name
    }.to_json
    @websocket.send message
  end

  def collection(name)
    Metybur::Collection.new(name, @websocket)
  end
end
