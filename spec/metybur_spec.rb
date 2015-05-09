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
  let(:last_sent_message) { parse(websocket.sent.last) }

  def parse(string_data)
    JSON.parse(string_data, symbolize_names: true)
  end

  it 'connects to a Meteor URL' do
    Metybur.connect(url)

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

      Metybur.connect(url, email: email, password: password)

      expect(last_sent_message[:msg]).to eq 'method'
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:method]).to eq 'login'
      expect(last_sent_message[:params][0])
        .to eq user: { email: email },
               password: password
    end

    it 'calls the login method with username and password' do
      username = FFaker::Internet.user_name
      password = FFaker::Internet.password

      Metybur.connect(url, username: username, password: password)

      expect(last_sent_message[:msg]).to eq 'method'
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:method]).to eq 'login'
      expect(last_sent_message[:params][0])
        .to eq user: { username: username },
               password: password
    end

    it 'calls the login method with user id and password' do
      userid = FFaker::Guid.guid
      password = FFaker::Internet.password

      Metybur.connect(url, id: userid, password: password)

      expect(last_sent_message[:msg]).to eq 'method'
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:method]).to eq 'login'
      expect(last_sent_message[:params][0])
        .to eq user: { id: userid },
               password: password
    end

    it "doesn't log in without credentials" do
      Metybur.connect(url)

      expect(last_sent_message[:msg]).to eq 'connect'
    end
  end

  context 'ping pong' do
    it 'responds with pong to a ping' do
      Metybur.connect(url)

      websocket.receive({msg: 'ping'}.to_json)

      expect(last_sent_message[:msg]).to eq 'pong'
    end
  end


  context 'logging' do
    it "doesn't log any messages by default" do
      output = StringIO.new
      Metybur.log_stream = output
      Metybur.connect(url)

      websocket.receive({msg: 'logged_message'}.to_json)

      expect(output.string).to be_empty
    end

    it 'logs a message when the log level is set to debug' do
      output = StringIO.new
      Metybur.log_level = :debug
      Metybur.log_stream = output
      Metybur.connect(url)
      
      websocket.receive({msg: 'logged_message'}.to_json)

      expect(output.string).not_to be_empty
    end
  end

  context 'subscription' do
    it 'subscribes to a published record set' do
      record_set = FFaker::Internet.user_name

      meteor = Metybur.connect(url)
      meteor.subscribe(record_set)

      expect(last_sent_message[:msg]).to eq 'sub'
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:name]).to eq record_set
    end
  end

  context 'collections' do
    def wait_for_callback(options = {})
      calls = options[:calls] || 1 # No keyword arguments in Ruby 1.9.3
      times_called = 0
      done = -> { times_called += 1 }
      yield done
      fail("Callback only got called #{times_called} time(s).") if times_called < calls
    end

    it 'gets notified when a record is added' do
      collection = FFaker::Internet.user_name
      id = FFaker::Guid.guid
      fields = {city: FFaker::Address.city}

      meteor = Metybur.connect(url)

      wait_for_callback do |done|
        meteor.collection(collection)
          .on(:added) do |added_id, added_fields|
            done.call()
            expect(added_id).to eq id
            expect(added_fields).to eq fields
          end

        message = {
          msg: 'added',
          collection: collection,
          id: id,
          fields: fields
        }.to_json
        websocket.receive message
      end
    end

    it 'gets notified when a record is changed' do
      collection = FFaker::Internet.user_name
      id = FFaker::Guid.guid
      fields = {city: FFaker::Address.city}
      cleared = [FFaker::Guid.guid]

      meteor = Metybur.connect(url)

      wait_for_callback do |done|
        meteor.collection(collection)
          .on(:changed) do |changed_id, changed_fields, cleared_fields|
            done.call()
            expect(changed_id).to eq id
            expect(changed_fields).to eq fields
            expect(cleared_fields).to eq cleared
          end

        message = {
          msg: 'changed',
          collection: collection,
          id: id,
          fields: fields,
          cleared: cleared
        }.to_json
        websocket.receive message
      end
    end

    it 'gets notified when a record is removed' do
      collection = FFaker::Internet.user_name
      id = FFaker::Guid.guid

      meteor = Metybur.connect(url)

      wait_for_callback do |done|
        meteor.collection(collection)
          .on(:removed) do |removed_id|
            done.call()
            expect(removed_id).to eq id
          end

        message = {
          msg: 'removed',
          collection: collection,
          id: id
        }.to_json
        websocket.receive message
      end
    end

    it 'lets the `on` method be chainable' do
      meteor = Metybur.connect(url)
      meteor.collection('my-collection')
        .on(:added) { anything }
        .on(:changed) { anything }
        .on(:removed) { anything }

      # Succeeds if there is no error
    end

    it 'registers multiple added callbacks' do
      collection = FFaker::Internet.user_name
      id = FFaker::Guid.guid
      fields = {city: FFaker::Address.city}

      meteor = Metybur.connect(url)

      wait_for_callback(calls: 2) do |done|
        meteor.collection(collection)
          .on(:added) { |added_id, added_fields| done.call() }
          .on(:added) { |added_id, added_fields| done.call() }

        message = {
          msg: 'added',
          collection: collection,
          id: id,
          fields: fields
        }.to_json
        websocket.receive message
      end
    end

    it "doesn't get notified of a ping message" do
      meteor = Metybur.connect(url)
      meteor.collection('my-collection')
        .on(:added) { fail('Callback got called') }

      websocket.receive({msg: 'ping'}.to_json)
    end
  
    it "doesn't get notified of a record from another collection" do
      meteor = Metybur.connect(url)
      meteor.collection('my-collection')
        .on(:added) { fail('Callback got called') }

      message = {
        msg: 'added',
        collection: 'another-collection',
        id: 'xyz',
        fields: {country: 'Belarus'}
      }.to_json
      websocket.receive message
    end
  end

  context 'methods' do
    it 'calls a method through the call method' do
      method = %w(postChatMessage sendEmail submitOrder).sample
      params = %w(35 Vienna true).sample(2)
      hashParams = {emailAddress: 'myemail@example.com', myMessage: 'Alright!', userId: 'rtnilctrniae'}
        .to_a.sample(2)
      params << Hash[hashParams]

      meteor = Metybur.connect(url)
      meteor.call(method, params)

      expect(last_sent_message[:msg]).to eq 'method'
      expect(last_sent_message[:method]).to eq method
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:params]).to eq params
    end

    it 'calls a method called on the client directly' do
      meteor = Metybur.connect(url)
      meteor.activate('user', id: 'utrtrvlc')

      expect(last_sent_message[:msg]).to eq 'method'
      expect(last_sent_message[:method]).to eq 'activate'
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:params]).to eq ['user', {id: 'utrtrvlc'}]
    end

    it 'camel-cases methods and parameters called on the client directly' do
      meteor = Metybur.connect(url)
      meteor.activate_user('Hans', user_id: 'utrtrvlc', is_admin: false)

      expect(last_sent_message[:msg]).to eq 'method'
      expect(last_sent_message[:method]).to eq 'activateUser'
      expect(last_sent_message).to have_key :id # we don't care about the value here
      expect(last_sent_message[:params]).to eq ['Hans', {userId: 'utrtrvlc', isAdmin: false}]
    end
  end
end
