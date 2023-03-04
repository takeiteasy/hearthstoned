#/bin/sh
ruby tools/hslookup.rb $(ruby tools/hearthstoner.rb player.hand | jq ".[].CardID" -M | tr '\n' ' ' | tr -d '"') | jq ".name"