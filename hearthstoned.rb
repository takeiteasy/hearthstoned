require 'json'
require 'singleton'

class State 
    include Singleton
    attr_accessor :inGame, :entities, :lastEntity, :currentLine, :currentLineNo

    def initialize
        reset
    end

    def reset(inGame=false)
        @inGame = inGame
        @entities = {}
        @lastEntity = nil
        @currentLine = ""
        @currentLineNo = 0
    end

    def hasEntity?(id)
        @entities.key? id or !@entities[id].nil?
    end

    def addEntity(id)
        Die("Entity already exists with ID: #{id}") if hasEntity? id 
        @lastEntity = id
        @entities[id] = {}
    end

    def players
        @entities.select { |k, v| v.key? "PlayerID" }
    end

    def setEntityTag(id, key, value)
        Die("Entity already exists with ID: #{id}") unless hasEntity? id
        @entities[id][key] = value
    end

    def dump
        @entities.each do |k, v|
            puts "#{k}:"
            v.each do |kk, vv|
                puts "\t #{kk}=#{vv}"
            end
        end
    end
end

def Die(msg)
    puts "FATAL ERROR: #{msg}"
    puts "##{State.instance.currentLineNo}: #{State.instance.currentLine}"
    abort
end

def ParseGameState(type, tags)
    case type
    when "DebugPrintPower"
        case tags
        when "CREATE_GAME"
            State.instance.reset true
        when /^GameEntity EntityID=(\d+)$/
            State.instance.addEntity $1
        when /^Player EntityID=(\d+) PlayerID=(\d+) GameAccountId=\[hi=(\d+) lo=(\d+)\]$/
            State.instance.addEntity $1
            State.instance.setEntityTag $1, "PlayerID", $2
            State.instance.setEntityTag $1, "GameAccountHi", $3
            State.instance.setEntityTag $1, "GameAccountLo", $4
        when /^FULL_ENTITY - Creating ID=(\d+) CardID=(\S*)$/
            State.instance.addEntity $1
            State.instance.setEntityTag $1, "CardID", $2 unless $2.empty? or $2.nil?
        when /^tag=(\S+) value=(\S+)$/
            State.instance.setEntityTag State.instance.lastEntity, $1, $2
        when /^TAG_CHANGE Entity=(.*) tag=(\S+) value=(\S+)$/
            entity = $1
            key = $2
            value = $3
            case entity
            when /^\d+$/
                State.instance.setEntityTag entity, key, value
            when /^\[/
                if entity =~ /\[entityName=(.*) (\[cardType=(\S+)\] )?id=(\d+) zone=(\S+) zonePos=(\d+) cardId=(\S+)? player=(\d+)\]/
                else
                    Die("Unhandled TAG_CHANGE format")
                end
            when /GameEntity/
                State.instance.setEntityTag "1", key, value
            else
                State.instance.players.each do |k, v|
                    if v.key? "PlayerName" and v["PlayerName"] == entity
                        State.instance.setEntityTag k, key, value
                        break
                    end
                end
            end
        else
            # Die("Unhandled: GameState.DebugPrintPower: #{tags}")
        end
    when "OnEntityChoices", "OnEntitiesChosen"
    when "DebugPrintEntityChoices", "DebugPrintEntitiesChosen"
    when "DebugPrintPowerList"
    when "DebugPrintGame"
        case tags
        when /^(\S+)=(\S+)$/
            State.instance.setEntityTag "1", $1, $2
        when /^PlayerID=(\d+), PlayerName=(.*)$/
            State.instance.setEntityTag $1, "PlayerName", $2
        else
            Die("Unhandled: GameState.DebugPrintGame: #{tags}")
        end
    when "SendChoices"
    when "SendOption"
    when "DebugPrintOptions"
    else
        Die("Unhandled GameState: #{type}")
    end
end

def ParsePowerTaskList(type, tags)
    case type
    when "DebugDump"
    when "DebugPrintPower"
    when "PrepareHistoryForCurrentTaskList"
    when "EndCurrentTaskList"
    when "DoTaskListForCard"
    else
        Die("Unhandled PowerTaskList: #{type}")
    end
end

def ParsePowerProcessor(type, tags)
    case type
    when "DebugDump"
    when "DebugPrintPower"
    else
        Die("Unhandled PowerProcessor: #{type}")
    end
end

def Parse(line)
    if line =~ /^D \d{2}:\d{2}:\d{2}\.\d{7} (\S+)\.(\S+)\(\)\s-\s+(.*)$/
        case $1
        when "GameState"
            ParseGameState $2, $3
        when "PowerTaskList"
            ParsePowerProcessor $2, $3
        when "PowerProcessor"
            ParsePowerTaskList $2, $3
        else
            Die("Unhadled log category: #{$1}")
        end
    else
        Die("Unhandled log format")        
    end
end

def Watch(f)
    if true
        f.each_line do |line|
            yield line.strip
        end
    else
        f.seek 0, IO::SEEK_END
        loop do
            line = f.read
            unless line
                sleep 0.1
                next
            end
            p line
            yield line.strip
        end
    end
end

# $PROGRAM_NAME = "hearthstoned"

# exit if fork
# Process.setsid
# exit if fork

# STDIN.reopen  "/dev/null"       
# STDOUT.reopen "/dev/null", "a"
# STDERR.reopen "/dev/null", 'a' 

# Dir.chdir "/"

Watch File.open("/Applications/Hearthstone/Logs/Power.log", "r") do |line|
    State.instance.currentLine = line
    State.instance.currentLineNo += 1
    if State.instance.inGame
        Parse line
    else
        State.instance.reset(true) if line =~ /CREATE_GAME$/
    end
end

State.instance.dump