require_relative '../lib/metybur'
require_relative 'mocks/websocket_mock'
require 'ffaker'
require 'json'

describe Metybur do
  before :all do
    Metybur.websocket_client_class = WebsocketMock
  end

  let(:url) { FFaker::Internet.http_url }
  let(:websocket) { WebsocketMock.instance }

  def parse(string_data)
    JSON.parse(string_data, symbolize_names: true)
  end

  it 'connects to a Meteor URL' do
    Metybur.connect url

    expect(websocket.url).to eq url
    connect_message = parse(websocket.sent.first)
    expect(connect_message)
      .to eq msg: 'connect',
             version: '1',
             support: ['1']
  end

  context 'logging in' do
    it 'calls the login method with email and password' do
      email = FFaker::Internet.email
      password = FFaker::Internet.password

      Metybur.connect url, email: email, password: password

      login_message = parse(websocket.sent.last)
      expect(login_message[:msg]).to eq 'method'
      expect(login_message).to have_key :id # we don't care about the value here
      expect(login_message[:method]).to eq 'login'
      expect(login_message[:params][0])
        .to eq user: { email: email },
               password: password
    end

    it 'calls the login method with username and password' do
      username = FFaker::Internet.user_name
      password = FFaker::Internet.password

      Metybur.connect url, username: username, password: password

      login_message = parse(websocket.sent.last)
      expect(login_message[:msg]).to eq 'method'
      expect(login_message).to have_key :id # we don't care about the value here
      expect(login_message[:method]).to eq 'login'
      expect(login_message[:params][0])
        .to eq user: { username: username },
               password: password
    end

    it 'calls the login method with user id and password' do
      userid = FFaker::Guid.guid
      password = FFaker::Internet.password

      Metybur.connect url, id: userid, password: password

      login_message = parse(websocket.sent.last)
      expect(login_message[:msg]).to eq 'method'
      expect(login_message).to have_key :id # we don't care about the value here
      expect(login_message[:method]).to eq 'login'
      expect(login_message[:params][0])
        .to eq user: { id: userid },
               password: password
    end

    it "doesn't log in without credentials" do
      Metybur.connect url

      last_message = parse(websocket.sent.last)
      expect(last_message[:msg]).to eq 'connect'
    end
  end

  context 'ping pong' do
    it 'responds with pong to a ping' do
      Metybur.connect url

      websocket.receive({msg: 'ping'}.to_json)

      last_message = parse(websocket.sent.last)
      expect(last_message[:msg]).to eq 'pong'
    end
  end


  context 'logging' do
    it "doesn't log any messages by default" do
      output = StringIO.new
      Metybur.log_stream = output
      Metybur.connect url

      websocket.receive({msg: 'logged_message'}.to_json)

      expect(output.string).to be_empty
    end

    it 'logs a message when the log level is set to debug' do
      output = StringIO.new
      Metybur.log_level = :debug
      Metybur.log_stream = output
      Metybur.connect url
      
      websocket.receive({msg: 'logged_message'}.to_json)

      expect(output.string).not_to be_empty
    end
  end
end
