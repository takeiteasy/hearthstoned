#/bin/sh

# Simple script to print your current hand using hearthstoner.rb and jq

ruby tools/hslookup.rb $(ruby tools/hearthstoner.rb player.hand | jq ".[].CardID" -M | tr '\n' ' ' | tr -d '"') | jq ".name"