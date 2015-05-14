class Metybur::LoggingMiddleware
  def initialize
    @logger = Logger.new(Metybur::CONFIG[:log_stream])
    @logger.level = Metybur::CONFIG[:log_level]
  end

  def open(event)
    @logger.debug 'connection open'
  end

  def message(event)
    @logger.debug "received message #{event.data}"
  end

  def close(event)
    @logger.debug "connection closed (code #{event.code}). #{event.reason}"
    EM.stop_event_loop
  end
end
