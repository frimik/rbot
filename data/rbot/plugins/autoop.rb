class AutoOP < Plugin
    def help(plugin, topic="")
        "perform autoop based on hostmask - usage: add <hostmask> [channel channel ...], rm <hostmask> [channel], list - list current ops. If you don't specify which channels, all channels are assumed"
    end
    
    def join(m)
      return if m.address?
      @registry.each { |mask,channels|
        if m.source.matches?(mask.to_irc_netmask(:server => m.server)) &&
            (channels.empty? || channels.include?(m.channel.to_s))
          @bot.mode(m.channel, "+o", m.source.nick)
          return
        end
      }
    end

    def nick(m)
      return if m.address?
      is_on = m.server.channels.inject(ChannelList.new) { |list, ch|
        list << ch if ch.users.include?(m.source)
        list
      }
      is_on.each { |channel|
        ch = channel.to_s
        @registry.each { |mask,channels|
          if m.source.matches?(mask.to_irc_netmask(:server => m.server)) &&
            (channels.empty? || channels.include?(ch))
            @bot.mode(ch, "+o", m.source.nick)
            return
          end
        }
      }
    end

    def add(m, params)
      @registry[params[:mask]] = params[:channels].dup
      m.okay
    end

    def rm(m, params)
      unless @registry.has_key?(params[:mask])
        m.reply @bot.lang.get('dunno')
        return
      end
      if (!params[:channels].empty? && @registry[params[:mask]] != nil)
        params[:channels].each do |c|
          @registry[params[:mask]] = @registry[params[:mask]].reject {|ele| ele =~ /^#{c}$/i}
        end
        if @registry[params[:mask]].empty?
          @registry.delete(params[:mask])
        end
      else
        @registry.delete(params[:mask])
      end
      m.okay
    end

    def list(m, params)
      debug @registry.length
      if(@registry.length > 0)
        @registry.each { |mask,channels|
          m.reply "#{mask} in #{channels.empty? ? 'all channels' : channels.join(', ')}"
        }
      else
        m.reply "No entries"
      end
    end
end

plugin = AutoOP.new

plugin.map 'autoop list', :action => 'list'
plugin.map 'autoop add :mask *channels', :action => 'add'
plugin.map 'autoop add :mask', :action => 'add'
plugin.map 'autoop rm :mask *channels', :action => 'rm'
plugin.map 'autoop rm :mask', :action => 'rm'
