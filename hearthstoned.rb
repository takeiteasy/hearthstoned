require 'json'
require 'singleton'
require 'socket'

def Error(msg, die=false)
    puts "#{die ? "FATAL " : ""}ERROR: #{msg}"
    puts "##{State.instance.currentLineNo}: #{State.instance.currentLine}"
    abort if die
end

class State 
    include Singleton
    attr_accessor :inGame, :entities, :lastEntity, :currentLine, :currentLineNo, :lastGame

    def initialize
        @entities = nil
        reset
    end

    def reset(inGame=false)
        @inGame = inGame
        @lastGame = @entities
        @entities = {}
        @lastEntity = nil
        @currentLine = ""
        @currentLineNo = 0
    end

    def hasEntity?(id)
        @entities.key? id or !@entities[id].nil?
    end

    def addEntity(id)
        @lastEntity = id
        return if hasEntity? id 
        @entities[id] = {}
    end

    def players
        @entities.select { |k, v| v.key? "PlayerID" }
    end

    def setEntityTag(id, key, value)
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

            if entity == "GameEntity" and key == "STATE" and value == "COMPLETE"
                State.instance.setEntityTag "1", key, value
                State.instance.reset
                return
            end

            case entity
            when /^\d+$/
                State.instance.addEntity entity
                State.instance.setEntityTag entity, key, value
            when /^\[/
                if entity =~ /^\[entityName=(.*) id=(\d+) zone=(\S+) zonePos=(\d+) cardId=(\S+)? player=(\d+)\]$/
                    entityName = $1
                    id         = $2
                    zone       = $3
                    zonePos    = $4
                    cardId     = $5
                    player     = $6

                    State.instance.addEntity id
                    State.instance.setEntityTag id, key, value
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
        when /^(SHOW_ENTITY) - Updating Entity=(.*) (\S+)=(\S+)$/,
             /^(HIDE_ENTITY) - Entity=(.*) tag=(\S+) value=(\S+)$/,
             /^(CACHED_TAG_FOR_DORMANT_CHANGE) Entity=(.*) tag=(\S+) value=(\S+)$/,
             /^(CHANGE_ENTITY) - Updating Entity=(\S+) (\S+)=(\S+)$/,
             /^(FULL_ENTITY) - Updating (.*) (\S+)=(\S*)$/
            subtype = $1
            entity  = $2
            tag     = $3
            value   = $4
            case $2
            when /^(\d+)$/
                State.instance.addEntity entity
                State.instance.setEntityTag entity, tag, value unless value.nil?
            when /^\[entityName=(.+) id=(\d+) zone=(\S+) zonePos=(\S+) cardId=(\S+)? player=(\d+)\]$/
                entityName = $1
                id         = $2
                zone       = $3
                zonePos    = $4
                cardId     = $5
                player     = $6

                State.instance.addEntity id
                State.instance.setEntityTag id, tag, value unless value.nil?
            else
                Error "Unhandled #{subtype.upcase} format"
            end
        when /^BLOCK_START/
        when "BLOCK_END"
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
    when "DebugDump"
    when "DebugPrintPower"
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
        when "GameState", "PowerTaskList"
            ParseGameState $2, $3
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

def Watch(f)
    f.readlines.each do |line|
        yield line
    end

    loop do
        line = f.read
        if line.nil? or line.empty?
            sleep 0.1
            next
        end
        for l in line.split "\n"
            yield l
        end
    end

    f.close
end

# $PROGRAM_NAME = "hearthstoned"

# exit if fork
# Process.setsid
# exit if fork

# STDIN.reopen  "/dev/null"       
# STDOUT.reopen "/dev/null", "a"
# STDERR.reopen "/dev/null", 'a' 

# Dir.chdir "/"

Thread.abort_on_exception = true

Thread.new do
    Watch File.open("/Applications/Hearthstone/Logs/Power.log", "r") do |line|
    # $<.each_line do |line|
        State.instance.currentLine = line
        State.instance.currentLineNo += 1
        if State.instance.inGame
            Parse line.strip
        else
            State.instance.reset true if line =~ /GameState\.DebugPrintPower\(\) - CREATE_GAME$/
        end
    end
end

def FormResponse data, code=200, force=false
    data = "{\"error\":\"Not in-game yet\"}" if not State.instance.inGame
    if data.nil? or data.empty? or data == "{}"
        data = "{\"error\": \"Nothing found\"}"
        code = 404
    end
    "HTTP/1.1 #{code}\r\nContent-Type: application/json\r\nContent-Length: #{data.length}\r\n\r\n#{data}"
end

socket = TCPServer.new 8080

loop do
    client = socket.accept
    header = client.gets
    method, path, version = header.split
    
    client.puts case method 
                when "GET"
                    case path.downcase
                    when /^\/$/, /^\/entities\/?$/
                        FormResponse State.instance.entities.to_json
                    when /^\/entity\/(\d+)?\/?$/
                        FormResponse State.instance.entities.select { |k, v| k == $1 }.to_json
                    when /^\/players\/?$/
                        FormResponse State.instance.players.to_json
                    when /^\/player\/(\d+)\/?$/
                        FormResponse State.instance.players.select { |k, v| v["PlayerID"] == $1 }.to_json
                    when /^\/state\/?$/
                        FormResponse State.instance.entities["1"].to_json
                    when /^\/previous\/?$/
                        FormResponse State.instance.lastGame.to_json, code=200, force=true
                    else
                        FormResponse "{\"error\":\"Invalid API request\"}", code=404 
                    end
                else
                    FormResponse "{\"error\":\"Invalid API request\"}", code=404
                end

    client.close
end

socket.close