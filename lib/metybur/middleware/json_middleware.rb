class Metybur::JSONMiddleware
  def open(event)
    event
  end

  def message(event)
    JSON.parse(event.data, symbolize_names: true)
  end

  def close(event)
    event
  end
end
