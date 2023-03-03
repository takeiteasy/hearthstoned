require 'json'
require 'singleton'

def Error(msg, die=false)
    puts "#{die ? "FATAL " : ""}ERROR: #{msg}"
    puts "##{State.instance.currentLineNo}: #{State.instance.currentLine}"
    abort if die
end

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
        return if hasEntity? id 
        @lastEntity = id
        @entities[id] = {}
    end

    def players
        @entities.select { |k, v| v.key? "PlayerID" }
    end

    def setEntityTag(id, key, value)
        return unless hasEntity? id
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

def ParseGameState(type, tags)
    case type
    when "DebugPrintPower"
        case tags
        when "CREATE_GAME"
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
        when /^\s*TAG_CHANGE Entity=(.*) tag=(\S+) value=(\S+)( DEF CHANGE)?$/
            entity  = $1
            key     = $2
            value   = $3
            case entity
            when /^\d+$/
                State.instance.setEntityTag entity, key, value
            when /^\[/
                if entity =~ /^\[entityName=(.*) id=(\d+) zone=(\S+) zonePos=(\d+) cardId=(\S+)? player=(\d+)\]$/
                    entityName = $1
                    id         = $2
                    zone       = $3
                    zonePos    = $4
                    cardId     = $5
                    player     = $6
                    if entityName =~ /^UNKNOWN ENTITY \[cardType=(\S+)\]$/
                        entityName = "UNKNOWN ENTITY"
                        State.instance.setEntityTag id, "cardType", $1
                    end
                    State.instance.setEntityTag id, "entityName", entityName
                    State.instance.setEntityTag id, "ZONE", zone
                    State.instance.setEntityTag id, "ZONE_POSITION", zonePos
                    State.instance.setEntityTag id, "CardID", cardId unless cardId.nil?
                    State.instance.setEntityTag id, "player", player
                else
                    Error "Unhandled TAG_CHANGE format"
                end
            when /GameEntity/
                State.instance.setEntityTag "1", key, value
            else
                State.instance.players.each do |k, v|
                    if v.key? "PlayerName" and v["PlayerName"] == entity
                        v[key] = value
                        break
                    end
                end
            end
        when /^SHOW_ENTITY - Updating Entity=(.*) CardID=(\S+)$/
            entity = $1
            cardid = $2
            case entity
            when /^\d+$/
                State.instance.setEntityTag entity, "CardID", cardid
            when /^\[entityName=(.+) id=(\d+) zone=(\S+) zonePos=(\d+) cardId=(\S+)? player=(\d+)\]$/
                entityName = $1
                id         = $2
                zone       = $3
                zonePos    = $4
                cardId     = $5
                player     = $6
                if entityName =~ /^(.+)\[cardType=(\S+)\]$/
                    entityName = $1.rstrip
                    State.instance.setEntityTag id, "cardType", $2
                end
                State.instance.setEntityTag id, "entityName", entityName
                State.instance.setEntityTag id, "ZONE", zone
                State.instance.setEntityTag id, "ZONE_POSITION", zonePos
                State.instance.setEntityTag id, "CardID", cardId unless cardId.nil?
                State.instance.setEntityTag id, "player", player
            else
                Error "Unhandled SHOW_ENTITY format"
            end
        when /^HIDE_ENTITY - Entity=(.*) tag=(\S+) value=(\S+)$/
            # TODO
        when /^CHANGE_ENTITY - Updating Entity=(\S+) CardID=(\S+)$/
            # TODO
        when /^BLOCK_START/
        when "BLOCK_END"
        when /^CACHED_TAG_FOR_DORMANT_CHANGE Entity=(.*) tag=(\S+) value=(\S+)$/
            # TODO
        when /^META_DATA - Meta=(\S+) Data=(\d+) InfoCount=(\d+)$/
        when /^Info\[(\d+)\] = (.*)$/
        when /^Source = (.*)$/
        when /^Targets\[(\d+)\] = (.*)$/
        when /^SHUFFLE_DECK PlayerID=(\d+)$/
        when /^SUB_SPELL_START/
        when "SUB_SPELL_END"
        else
            Error "Unhandled: GameState.DebugPrintPower"
        end
    when "OnEntityChoices", "OnEntitiesChosen"
    when "DebugPrintEntityChoices", "DebugPrintEntitiesChosen"
    when "DebugPrintPowerList"
    when "DebugPrintGame"
        case tags
        when /^(\S+)=(\S+)$/
            State.instance.setEntityTag "1", $1, $2
        when /^PlayerID=(\d+), PlayerName=(.*)$/
            State.instance.players.each do |k, v|
                if v.key? "PlayerID" and v["PlayerID"] == $1
                    v["PlayerName"] = $2
                end
            end
        else
            Error "Unhandled: GameState.DebugPrintGame"
        end
    when "SendChoices"
    when "SendOption"
    when "DebugPrintOptions"
    else
        Error "Unhandled GameState"
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
        Error "Unhandled PowerTaskList: #{type}"
    end
end

def ParsePowerProcessor(type, tags)
    case type
    when "DebugDump"
    when "DebugPrintPower"
    else
        Error "Unhandled PowerProcessor: #{type}"
    end
end

def ParseChoiceCardMgr(type, tags)
    case type
    when "WaitThenShowChoices"
    when "DoesLocalChoiceMatchPacket"
    when "WaitThenHideChoicesFromPacket"
    else
        Error "Unhandled ChoiceCardMgr: #{type}"
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
        when "ChoiceCardMgr"
            ParseChoiceCardMgr $2, $3
        else
            Error "Unhadled log category: #{$1}"
        end
    else
        Error "Unhandled log format"        
    end
end

# def Watch(f)
#     f.seek 0, IO::SEEK_END
#     loop do
#         line = f.read
#         unless line
#             sleep 0.1
#             next
#         end
#         yield line.strip
#     end
# end

# $PROGRAM_NAME = "hearthstoned"

# exit if fork
# Process.setsid
# exit if fork

# STDIN.reopen  "/dev/null"       
# STDOUT.reopen "/dev/null", "a"
# STDERR.reopen "/dev/null", 'a' 

# Dir.chdir "/"

# Watch File.open("/Applications/Hearthstone/Logs/Power.log", "r") do |line|
$<.each_line do |line|
    State.instance.currentLine = line
    State.instance.currentLineNo += 1
    if State.instance.inGame
        Parse line.strip
    else
        State.instance.reset true if line =~ /GameState\.DebugPrintPower\(\) - CREATE_GAME$/
    end
end

State.instance.dump