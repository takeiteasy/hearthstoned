# hearthstoned

Hearthstoned is a log monitoring daemon for Hearthstone. Interact with the daemon via a simple HTTP server that provides a simple API that returns a representation of the current game state in a JSON format. **WIP**

To see some examples of what you can do, look in the [tools](https://github.com/takeiteasy/hearthstoned/tree/master/tools) directory. **NOTE**: This is ***NOT*** a fully-featured deck tracker, it only records the current game state and responds to requests. This has been designed for making scripts to query the state of the game.

## API Routes

- ```/``` and ```/entities```
    - Returns a full list of every game entity, including game state and players
- ```/entities```
    - Returns all game entities, minus game state and players
- ```/players```
    - Returns all players
- ```/player/{id}```
    - Returns a specific player
- ```/entity/{id}```
    - Returns a specific entity
- ```/state```
    - Returns game state
- ```/previous```
    - Returns the final state of the previous game

## License
```
The MIT License (MIT)

Copyright (c) 2022 George Watson

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```