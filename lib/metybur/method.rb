Metybur::MethodError = Class.new(Exception)

class Metybur::Method
  class Result
    def initialize(attributes, callback)
      @attributes = attributes
      @callback = callback
    end

    def publish
      instance_eval(&@callback) if @callback
    end

    def result
      error = @attributes[:error]
      if error
        fail(
          Metybur::MethodError,
          "error: #{error[:error]}, reason: #{error[:reason]}, details: #{error[:details]}"
        )
      else
        @attributes[:result]
      end
    end
    alias_method :raise_errors, :result
  end

  def initialize(name, websocket)
    require 'securerandom'

    @name = name
    @websocket = websocket
    @callbacks = {}

    @websocket.on(:message) do |event|
      attributes = JSON.parse(event.data, symbolize_names: true)
      handle_message(attributes) if attributes[:msg] == 'result'
    end

    @logger = Logger.new(Metybur::CONFIG[:log_stream])
    @logger.level = Metybur::CONFIG[:log_level]
  end

  def call(params, &block)
    @logger.debug("calling method #{@name} with params #{params}")
    id = SecureRandom.uuid
    message = {
      msg: 'method',
      id: id,
      method: @name,
      params: params
    }.to_json
    @logger.debug("sending message #{message}")
    @websocket.send message
    @callbacks[id] = block
  end

  private

  def handle_message(attributes)
    id = attributes[:id]
    result = Result.new(attributes, @callbacks[id])
    result.publish
  end
end
