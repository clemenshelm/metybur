class WebsocketMock
  class << self
    attr_accessor :instance
  end

  attr_reader :url, :sent
  
  def initialize(url)
    WebsocketMock.instance = self
    @url = url
    @sent = []
  end

  def on(event)
    # Just a stub so far
  end

  def send(string_data)
    @sent << string_data
  end
end
