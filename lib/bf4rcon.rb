require "bf4rcon/version"
require "bindata"

module Bf4rcon
  # Your code goes here...
  ##include BinData

  class Bf4RconInvalidArgumentType < StandardError; end
  class Bf4RconCommandFailed < StandardError; end

  class Bf4Word < BinData::Record
    endian :little
    uint32 :len, :value => lambda { content.length }
    stringz  :content
  end

  class Bf4RconHdr < BinData::Record
    endian :little
    uint32 :sequence
    uint32 :packet_size, :value => lambda { num_bytes }
    uint32 :numofwords, :value => lambda { bf4_word.size }
    array  :bf4_word, :type => :bf4_word, :initial_length => lambda { numofwords }

    def is_response?
      if (self.sequence >> 30) & 1
        return true
      else
        return false
      end
    end

    def is_ok?
      if self.bf4_word[0].content == "OK"
        return true
      else
        return false
      end
    end

    def response
      self.bf4_word.map{|x| x.content}
    end

    def remove_hdr_and_state
      t = self.bf4_word.map{|x| x.content} ## removes packet header
      return t[1..-1] ## removes state info from packet
    end

    def to_a
      return self.response
    end
    
  end # end of BF4RconHdr 

  class Bf4PlayersInfo
    attr_accessor :numofplayers, :labels, :playerlist

    def initialize(bf4rconpacket)    
      raise Bf4RconInvalidArgumentType if not bf4rconpacket.kind_of?(Bf4RconHdr)
      
      @labels       = []
      @playerlist   = []
      @numofplayers = 0   
      
      rawary = bf4rconpacket.remove_hdr_and_state
      
      ## first, parse labels
      numoflabels = rawary.slice!(0, 1)[0].to_i
      numoflabels.times{|i| 
        @labels << rawary.slice!(0, 1)[0].to_sym
      }    
      
      ## second, parse playerlist
      tmpplayerary = []
      @numofplayers = rawary.slice!(0, 1)[0].to_i    
      @numofplayers.times{|i|      
        tmpplayerary << rawary.slice(i * @labels.length, @labels.length)
      }

      ## generate hash
      tmpplayerary.each{|p|
        @playerlist << Hash[*@labels.zip(p).flatten]
      }
    end

    def find(options = {})
      case options
      when :all then
        return @playerlist
      else
        return @playerlist.find{|e| e[options.first[0]] == options.first[1] }
      end
    end
    
  end

  class Bf4Rcon
    attr_accessor :host, :port, :password, :sock

    def initialize(host, port, password, sock) 
      @sock     = sock
      @login    = 0
      @host     = host
      @port     = port
      @password = password
      @events_enabled = false

      @functable = [
                    ["listPlayers", lambda {|x| Bf4Rcon.parse_playernames(x)} ], 
                    ["admin__listPlayers", lambda {|x| Bf4Rcon.parse_playernames(x)} ]
                   ]
    end

    def self.build_rconpacket(cmd_array, request = 0, from_client = 1, seqnum = 0)
      sequence = 0
      sequence |= (from_client & 1) << 31
      sequence |= (request & 1) << 30
      sequence |= seqnum & 0x3fffffff

      ary = cmd_array.map{|v| Bf4Word.new(:content => v) }
      packet = Bf4RconHdr.new(:sequence   => sequence,
                              :numofwords => ary.length,
                              :bf4_word   => ary)
      
      return packet
    end
    
    def self.open(host, port, password = nil)
      begin
        sock = TCPSocket.open(host, port)
      rescue => err
        raise err
      end

      bf4srv = new(host, port, password, sock)

      if password
        bf4srv.do_login()
      end
      
      if block_given?
        begin
          yield bf4srv
        ensure
          bf4srv.close()
        end
      else
        return bf4srv
      end    
    end # end of self.open
    
    def self.parse_playernames(bf4rconpacket)
      players = Bf4PlayersInfo.new(bf4rconpacket)
      return players
    end

    def do_login
      packet = Bf4Rcon.build_rconpacket(["login.plainText", @password])
      begin
        packet.write(@sock)
        recv_packet = Bf4RconHdr.read(@sock)
      rescue => err
        raise err
      end
      ret = recv_packet.is_response? and recv_packet.is_ok?
      if ret
        @login = 1    
      else
        @login = 0
      end
      return ret
    end

    def close
      @sock.close
      @login = 0
      @events_enabled = false
    end
    
    def wait_event(options = {})
      if not @events_enabled
        ret = self.bf4_admin__eventsEnabled("true")
        if ret.is_ok?
          @events_enabled = true
        else
          @events_enabled = false
          raise Bf4RconCommandFailed, "Could not execute admin.eventsEnable"
        end
      end      
      
      begin
        recv_packet = Bf4RconHdr.read(@sock)      
      rescue => err
        raise err
      end
      return recv_packet
    end # end of wait_event
    
    
    def method_missing(action, *args)
      if match = /^bf4_([a-zA-Z]\w*__[a-zA-Z]\w*$)|bf4_([a-zA-Z]\w*$)/.match(action.to_s)
        cmdary = []
        cmdary << (match[1] ? match[1] : match[2]).gsub(/__/, ".")
        cmdary.concat(args) if args.length > 0
        packet = Bf4Rcon.build_rconpacket(cmdary)
        recv_packet = nil
        
        begin
          packet.write(@sock)
          recv_packet = Bf4RconHdr.read(@sock)
        rescue => err
          raise err
        end
        
        if ret = @functable.assoc(match[1])
          ret[1].call(recv_packet)
        else
          return recv_packet
        end
      else
        super(action, *args)
      end
    end # end of method_missing

    # end of method_missing
    def respond_to?(action)
      if match = /^bf4_([a-zA-Z]\w*__[a-zA-Z]\w*$)|bf4_([a-zA-Z]\w*$)/.match(action.to_s)
        true
      else
        super
      end
    end
    
  end # end of class Bf4Rcon

end # Bf4rcon

