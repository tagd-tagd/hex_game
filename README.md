# hex_game

TUI/CLI variant of 2048 game by Gabriele Cirulli

The best game for prod :-)

![](https://github.com/tagd-tagd/hex_game/blob/main/hex_screen.png)

~~~
./hex.sh [huc]
-h help
-u disable undo (minimize write to disk)
-c disable colors

KEYS
arrow keys
r - redraw screen
u - undo
s - save game
l - load saved game
q - quit (for restore game press 'u' after start)
~~~
## USAGE ##

```bash
wget https://github.com/tagd-tagd/hex_game/raw/refs/heads/main/hex.sh
chmod +x ./hex.sh
./hex.sh
```

## Dependencies ##

bash, readlink, stty, tput

