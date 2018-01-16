
require 'qpid_proton'
require 'fluent/input'


module Fluent
  class AMQPInput < Input
    NAME = 'amq'
    Plugin.register_input(NAME, self)

    def initialize
      super
      require 'fluent/parser'
    end

    config_param :url, :string
    config_param :tag, :string
    config_param :reconnect_min, :float, :default => 0.1
    config_param :reconnect_max, :float, :default => 3
    config_param :queue, :string
    config_param :cert, :string
    config_param :private_key, :string
    config_param :key_pass, :string, :default => ''

    def configure(conf)
      super
      raise ConfigError, "#{NAME}: 'tag' is required" unless @tag
      raise ConfigError, "#{NAME}: 'url' is required" unless @url
      raise ConfigError, "#{NAME}: 'cert' is required" unless @cert
      raise ConfigError, "#{NAME}: 'private_key' is required" unless @private_key
      @ssl_domain = Qpid::Proton::SSLDomain.new(Qpid::Proton::SSLDomain::MODE_CLIENT)
      @ssl_domain.credentials(@cert, @private_key, @key_pass)
      begin
        @url = Qpid::Proton::uri @url
      rescue Exception => e
        raise ConfigError, "#{NAME}: 'url' is invalid: #{e}"
      end
    end

    def start
      super
      log.debug "#{NAME}: connecting on #{@url}"
      @thread = Thread.new do
        while !@stop
          begin
            h = Handler.new log, @url, @tag, @router, @ssl_domain, @queue
            @container = Qpid::Proton::Container.new(h)
            @container.run
          rescue => e
            log.error "Error connecting to the AMQP bus #{e.message}"
          end
        end
      end
    end

    def shutdown
      super
      @stop = true
      @driver.io.close
      @thread.join
    rescue
    end

    class Handler < Qpid::Proton::MessagingHandler

      def initialize(log, url, tag, router, ssl_domain, queue)
        super()
        @log, @url, @tag, @router, @ssl_domain, @queue = log, url, tag, router, ssl_domain, queue
      end

      attr_reader :engine

      def on_container_start(container)
        begin
          c = container.connect(@url, { :ssl_domain => @ssl_domain })
          @log.debug "Opening connection to the address: #{@queue}"
          c.open_receiver(@queue)
        rescue => e
          @log.error "Error connecting to the message queue. #{e.message}"
          @log.error "Backtrace: #{e.backtrace}"
        end

      end

      def on_connection_open(c)
        raise "No security!"  unless c.transport.ssl?
        @log.debug "Connection secured with #{c.transport.ssl.protocol_name.inspect}"
      end

      def build_record(message)
        record = {
          body: JSON.parse(message.body),
          address: message.address,
          msg_id: message.id
        }
        record[:properties] = message.properties if (message.properties and message.properties.size > 0)
        record[:annotations] = message.annotations if (message.annotations and message.annotations.size > 0)
        record[:instructions] = message.instructions if (message.instructions and message.instructions.size > 0)
        record[:subject] = message.subject if (message.subject and message.subject.size > 0)
        record[:priority] = message.priority if (message.priority and message.priority.size > 0)
        record[:user_id] = message.user_id if (message.user_id and message.user_id.size > 0)
        record[:correlation_id] = message.correlation_id if (message.correlation_id and message.correlation_id.size > 0)
        record[:creation_time] = message.creation_time if (message.creation_time and message.creation_time > 0)
        record
      end

      def on_message(delivery, message)
        record = build_record(message)
        time = Engine.now

        tag = (message.address and message.address.size > 0) ? "#{@tag}.#{message.address.sub("topic://","")}" : @tag
        @router.emit(tag, time, record)
      end

      def on_disconnect event
        puts "FIMXE #{NAME}: disconnected, re-connecting"
      end
    end
  end
end
