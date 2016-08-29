require 'active_support/inflector'
require_relative 'collection'
require_relative 'method'

class Metybur::Client
  attr_writer :websocket

  def initialize(credentials)
    @credentials = credentials.freeze
    @subscription_messages = []
    @collections = []
  end

  def subscribe(record_set_name, *params)
    message = {
      msg: 'sub',
      id: 'cde',
      name: record_set_name,
      params: params
    }.to_json
    @subscription_messages << message
    @websocket.send message
  end

  def collection(name)
    Metybur::Collection.new(name, @websocket).tap do |collection|
      @collections << collection
    end
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

  def resubscribe
    @subscription_messages.each { |message| @websocket.send(message) }
    @collections.each { |collection| collection.websocket = @websocket }
  end

  def connect
    connect_message = {
      msg: 'connect',
      version: '1',
      support: ['1']
    }
    @websocket.send(connect_message.to_json)

    credentials = @credentials.dup
    password = credentials.delete(:password)
    if password
      this = self
      login(user: credentials, password: password) { this.resubscribe }
    else
      resubscribe
    end
  end
end
