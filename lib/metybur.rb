require "metybur/version"
require 'faye/websocket'
require 'json'
require 'logger'
require_relative 'metybur/client'
require_relative 'metybur/middleware/logging_middleware'
require_relative 'metybur/middleware/json_middleware'
require_relative 'metybur/middleware/ping_pong_middleware'

module Metybur
  CONFIG = {
    websocket_client_class: Faye::WebSocket::Client,
    log_level: Logger::INFO,
    log_stream: STDOUT
  }

  def self.connect(url, credentials = {})
    websocket = CONFIG[:websocket_client_class].new(url, nil, ping: 120)
    client = Metybur::Client.new(websocket)

    logging_middleware = Metybur::LoggingMiddleware.new
    json_middleware = Metybur::JSONMiddleware.new
    ping_pong_middleware = Metybur::PingPongMiddleware.new(websocket)
    middleware = [logging_middleware, json_middleware, ping_pong_middleware]

    websocket.on(:open) do |event|
      middleware.inject(event) { |e, mw| mw.open(e) }
    end
    websocket.on(:message) do |event|
      middleware.inject(event) { |e, mw| mw.message(e) }
    end
    websocket.on(:close) do |event|
      middleware.inject(event) { |e, mw| mw.close(e) }
      EM.stop_event_loop
    end

    connect_message = {
      msg: 'connect',
      version: '1',
      support: ['1']
    }
    websocket.send(connect_message.to_json)

    password = credentials.delete(:password)
    return client unless password
    client.login(user: credentials, password: password)

    client
  end

  def self.websocket_client_class=(klass)
    CONFIG[:websocket_client_class] = klass
  end
  
  def self.log_level=(level_symbol)
    upcase_symbol = level_symbol.to_s.upcase.to_sym
    CONFIG[:log_level] = Logger.const_get(upcase_symbol)
  end

  def self.log_stream=(io)
    CONFIG[:log_stream] = io
  end
end
