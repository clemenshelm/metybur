require "metybur/version"
require 'faye/websocket'
require 'json'
require 'logger'
require_relative 'metybur/client'

module Metybur
  CONFIG = {
    websocket_client_class: Faye::WebSocket::Client,
    log_level: Logger::INFO,
    log_stream: STDOUT
  }

  def self.connect(url, credentials = {})
    websocket = CONFIG[:websocket_client_class].new(url)
    client = Metybur::Client.new(websocket)

    logger = Logger.new(CONFIG[:log_stream])
    logger.level = CONFIG[:log_level]
    websocket.on(:open) do |event|
      logger.debug 'connection open'
    end
    websocket.on(:message) do |message|
      logger.debug "received message #{message.data}"
    end
    websocket.on(:close) do |event|
      logger.debug "connection closed (code #{event.code}). #{event.reason}"
      EM.stop_event_loop
    end

    websocket.on(:message) do |event|
      message = JSON.parse(event.data, symbolize_names: true)
      if message[:msg] == 'ping'
        websocket.send({msg: 'pong'}.to_json)
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

    login_message = {
      msg: 'method',
      id: 'abc',
      method: 'login',
      params: [
        {
          user: credentials,
          password: password
        }
      ]
    }

    websocket.send(login_message.to_json)

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
