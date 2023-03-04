#/usr/bin/env ruby
require 'json'
require 'uri'
require 'net/http'

# Quickly test if you have lethal playing mine warlock
# This is a very dumb bot, doesn't account for other ways to achieve lethal
# - Checks if all parts of the combo are in hand
# - Checks the cost
# - Checks the damage done is enough
# This is just a test to see whats possible with the data gathered by hearthstoned


# Send HTTP request, return body
def get(uri)
    res = Net::HTTP.get_response URI("http://localhost:8080#{uri}")
    abort unless res.is_a? Net::HTTPSuccess
    res.body
end

# Get the user's player info (I think it's always 2?)
player = JSON.parse(get("/entity/2"))["2"]
# opponent = JSON.parse(get("/entity/3"))["3"]
# Get the player's current remaining mana
mana = player["RESOURCES"].to_i - player["RESOURCES_USED"].to_i
# Get all cards that are in the player's hand
hand = JSON.parse(get("/")).select { |k, v| v.key? "ZONE" and v["ZONE"] == "HAND" }

# Required cards for the combo
combo = {
    "BAR_918" => {
        :inHand => false,
        :currentCost => 0
    }, # Tamsin Roame
    "AV_317" => {
        :inHand => false,
        :currentCost => 0
    }, # Tamsin's Phylactery
    "DED_504" => {
        :inHand => false,
        :currentCost => 0,
        :imps => 0
    }, # Wicked Shipment
    "ULD_717" => {
        :inHand => false,
        :currentCost => 0
    }, # Plague of Flames
}

imps = 0 # Holds the number of imps created by Wicked Shipment

# Check each card in hand to see if it's part of the combo
hand.each do |k, v|
    next if not v.key? "CardID" or v["CardID"].empty? or not combo.key? v["CardID"]
    cardId = v["CardID"]
    if combo[cardId][:inHand] == true
        newCost = v["COST"].to_i
        combo[cardId][:currentCost] = newCost if newCost < combo[cardId][:currentCost]
    else
        if cardId == "DED_504" # If Wicked Shipment
            i = v["TAG_SCRIPT_DATA_NUM_1"].to_i # TAG_SCRIPT_DATA_NUM_1 holds the number of imps summoned
            imps = i if i > imps
        end
        combo[cardId][:inHand] = true
        combo[cardId][:currentCost] = v["COST"].to_i
    end
end

# Check if any combo pieces are missing
missing = combo.select { |k, v| v[:inHand] == false }
if not missing.empty?
    puts "Missing pieces: #{missing.keys.join ", "}"
    abort
end

# Check if player has enough mana
cost = combo.reduce(0) { |sum, (k, v)| sum +=  v[:currentCost]  }
if cost > mana
    puts "Not enough mana: #{mana}, #{cost}"
    abort
end

# At the moment health/armor is not tracked by hearthstoned, value must be set manually :(
$OPPONENT_HEALTH = 26
# Calculate damage, (minions * 4) * 2
board = [7, imps + 1].min
damage = (board * 2) * 4

# Is it lethal???
if damage > $OPPONENT_HEALTH
    puts "It's lethal! Damage: #{damage}"
else
    puts "Missing #{$OPPONENT_HEALTH - damage} damage"
    abort
end