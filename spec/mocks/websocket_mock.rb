class WebsocketMock
  class << self
    attr_accessor :instance
  end

  MessageEvent = Struct.new(:data)

  attr_reader :url, :sent
  
  def initialize(url)
    WebsocketMock.instance = self
    @url = url
    @sent = []
    @message_handlers = []
  end

  def on(event, &handler)
    if event == :message
      @message_handlers << handler
    end
  end

  def send(string_data)
    @sent << string_data
  end

  def receive(string_data)
    event = MessageEvent.new(string_data)
    @message_handlers.each { |handler| handler.call(event) }
  end
end
