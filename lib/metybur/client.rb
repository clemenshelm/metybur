require 'active_support/inflector'
require_relative 'collection'
require_relative 'method'

class Metybur::Client
  def initialize(websocket)
    @websocket = websocket
  end

  def subscribe(record_set_name, *params)
    message = {
      msg: 'sub',
      id: 'cde',
      name: record_set_name,
      params: params
    }.to_json
    @websocket.send message
  end

  def collection(name)
    Metybur::Collection.new(name, @websocket)
  end

  def method(name)
    Metybur::Method.new(name, @websocket)
  end

  def call(method_name, params, &block)
    method(method_name).call(params, &block)
  end

  def method_missing(method, *params, &block)
    method = method.to_s.camelize(:lower)
    params.map! do |param|
      case param
      when Hash
        param_array = param.map { |k, v| [k.to_s.camelize(:lower), v] }
        Hash[param_array]
      else
        param
      end
    end
    call(method, params, &block)
  end
end
