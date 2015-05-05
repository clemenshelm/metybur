require 'active_support/inflector'
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

  def call(method, params)
    message = {
      msg: 'method',
      id: 'efg',
      method: method,
      params: params
    }.to_json
    @websocket.send message
  end

  def method_missing(method, *params)
    method = method.to_s.camelize(:lower)
    params.map! do |param|
      case param
      when Hash
        param.map { |k, v| [k.to_s.camelize(:lower), v] }.to_h
      else
        param
      end
    end
    call(method, params)
  end
end
