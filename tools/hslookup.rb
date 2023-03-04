require 'json'
require 'net/http'

# Simple tool to get names of cards from their CardID
# Results rely on https://hearthstonejson.com/

def get(uri)
    Net::HTTP.get_response URI(uri)
end

def latest()
    get("https://api.hearthstonejson.com/v1/latest/")["location"]
end

cards = JSON.parse get("#{latest}enUS/cards.json").body
$*.each do |a|
    cards.each do |c|
        if c["id"] == a
            puts c.to_json
            break
        end
    end
end