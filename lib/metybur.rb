require "metybur/version"
require 'faye/websocket'
require 'json'
require 'logger'

module Metybur
  CONFIG = {
    websocket_client_class: Faye::WebSocket::Client
  }

  def self.connect(url, credentials = {})
    websocket = CONFIG[:websocket_client_class].new(url)

    logger = Logger.new(STDOUT)
    websocket.on(:open) do |event|
      logger.debug 'connection open'
    end
    websocket.on(:message) do |message|
      logger.debug "received message #{message.data}"
    end
    websocket.on(:close) do |event|
      logger.debug "connection closed (code #{event.code}). #{event.reason}"
      EM.stop
    end

    connect_message = {
      msg: 'connect',
      version: '1',
      support: ['1']
    }
    websocket.send(connect_message.to_json)

    password = credentials.delete(:password)
    return unless password

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
  end

  def self.websocket_client_class=(klass)
    CONFIG[:websocket_client_class] = klass
  end
end
