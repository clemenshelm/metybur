require "metybur/version"
require 'faye/websocket'
require 'json'
require 'logger'
require_relative 'metybur/client'
require_relative 'metybur/middleware/logging_middleware'

module Metybur
  CONFIG = {
    websocket_client_class: Faye::WebSocket::Client,
    log_level: Logger::INFO,
    log_stream: STDOUT
  }

  def self.connect(url, credentials = {})
    websocket = CONFIG[:websocket_client_class].new(url)
    client = Metybur::Client.new(websocket)

    logging_middleware = Metybur::LoggingMiddleware.new
    middleware = [logging_middleware]

    websocket.on(:open) do |event|
      middleware.each { |mw| mw.open(event) }
    end
    websocket.on(:message) do |event|
      middleware.each { |mw| mw.message(event) }
    end
    websocket.on(:close) do |event|
      middleware.each { |mw| mw.close(event) }
    end

    websocket.on(:message) do |event|
      message = JSON.parse(event.data, symbolize_names: true)
      if message[:msg] == 'ping'
        pong = {msg: 'pong'}
        pong[:id] = message[:id] if message[:id]
        websocket.send(pong.to_json)
      end
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
