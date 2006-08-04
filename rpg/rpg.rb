# Plugin for the Ruby IRC bot (http://linuxbrit.co.uk/rbot/)
#
# Little IRC game
#
# (c) 2006 Mark Kretschmann <markey@web.de>
# Licensed under GPL V2.
 

class Player

  attr_accessor :name, :player_type, :hp, :strength, :description

  def initialize
    @name = ""
    @player_type = "Human"
    @hp = 20
    @strength = 10

    @description = "A typical human geek."
  end


  def punch( game, target ) 
    damage = rand( @strength )
    target.hp -= damage

    game.msg.reply( "#{@name} punches #{target.name}." )
    game.msg.reply( "#{target.name} loses #{damage} hit points." )
  end

end


class Monster < Player

  @@monsters = [] 
 
  def initialize
    super

  end


  def Monster.monsters
    @@monsters
  end
    

  def Monster.register( monster )
    @@monsters << monster
  end


  def act( game )
    game.players.each_value do |p| 
      if p.instance_of?( Player )
        punch( game, p )
      end  
    end
  end

end    


class Orc < Monster
  
  Monster.register Orc

  def initialize
    super

    @name = "orc"
    @player_type = "Orc"
    @hp = 14

    @description = "The Orc is a humanoid creature resembling a caveman. It has dangerous looking fangs and a snout. Somehow, it does not look very smart."
  end

end


class Slime < Monster

  Monster.register Slime

  def initialize
    super

    @name = "slime"
    @player_type = "Slime"
    @hp = 8

    @description = "The Slime is a slimy jelly, oozing over the ground. You really don't feel like touching that." 
  end  

end


class RpgPlugin < Plugin

  attr_accessor :players, :msg

  def initialize
    super

    @players = Hash.new
  end

#####################################################################
# Core Methods
#####################################################################

  def schedule
    # Check for death:
    @players.each_value do |p|
      if p.hp < 0
        @msg.reply( "#{p.name} dies from his injuries." )
        @players.delete( p.name )        
      end  
    end

    # Let monsters act:
    @players.each_value do |p|
      if p.is_a?( Monster )
        p.act( self )
      end
    end
  end


  def spawned?( m, nick )
    if @players.has_key?( nick )
      return true
    else
      m.reply( "You have not joined the game. Use 'spawn player' to join." )
      return false  
    end
  end


  def target_spawned?( m, target )
    if @players.has_key?( target )
      return true
    else  
      m.reply( "#{m.sourcenick} seems confused: there is noone named #{target} near.." )
      return false
    end
  end
 

#####################################################################
# Command Handlers
#####################################################################

  def handle_spawn_player( m, params )
    p = Player.new  
    p.name = m.sourcenick
    @players[p.name] = p
    m.reply "Player #{p.name} enters the game."

    # handle_spawn_monster m, params  # for testing
  end


  def handle_spawn_monster( m, params )
    p = Monster.monsters[rand( Monster.monsters.length )].new  

    # Make sure we don't have multiple monsters with same name (FIXME)
    a = [0]
    @players.each_value { |x| a << x.name[-1,1].to_i if x.name.include? p.name }
    p.name += ( a.sort.last + 1).to_s

    @players[p.name] = p
    m.reply "A #{p.player_type} enters the game. ('#{p.name}')"
  end


  def handle_punch( m, params )
    return unless spawned?( m, m.sourcenick )
    return unless target_spawned?( m, params[:target] )
 
    @msg = m  #temp hack
    @players[m.sourcenick].punch( self, @players[params[:target]] )
    schedule
  end


  def handle_look( m, params )
    return unless spawned?( m, m.sourcenick )

    if params[:object] == nil
      if @players.length == 1
        m.reply( "#{m.sourcenick}: You are alone." )
        return
      end
      objects = []
      @players.each_value { |x| objects << x.name unless x.name == m.sourcenick }
      m.reply( "#{m.sourcenick}: You see the following objects: #{objects.join( ', ' )}." )
    else
      p = nil
      @players.each_value { |x| p = x if x.name == params[:object] }
      if p == nil
        m.reply( "#{m.sourcenick}: There is no #{params[:object]} here." )
      else
        m.reply( "#{m.sourcenick}: #{p.description}" )   
      end
    end  
  end

end
  

plugin = RpgPlugin.new
plugin.register( "rpg" )

plugin.map 'spawn player',  :action => 'handle_spawn_player'
plugin.map 'spawn monster', :action => 'handle_spawn_monster' 
plugin.map 'punch :target', :action => 'handle_punch' 
plugin.map 'look :object',  :action => 'handle_look',         :defaults => { :object => nil }


