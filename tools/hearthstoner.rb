require 'json'
require 'uri'
require 'net/http'

def get(uri)
    res = Net::HTTP.get_response URI("http://localhost:8080#{uri}")
    abort unless res.is_a? Net::HTTPSuccess
    res.body
end

puts get("/") if $*.empty?
$*.each do |argv|
    puts case argv
         when "state", "players", "entities"
            get("/" + argv)
         when "player.hand"
            JSON.parse(get("/")).select { |k, v| v.key? "ZONE" and v["ZONE"] == "HAND" }.to_json
         when /^state.(\S+)$/
            src   = get("/")
            state = JSON.parse(src)
            return src unless state.key? "1"

            if state["1"].key? $1
                state["1"][$1].to_json
            else
                "{\"error\": \"Invalid state tag\"}"
            end
         end
end