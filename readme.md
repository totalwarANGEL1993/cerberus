Script library for THE SETTLERS - Heritage of Kings.

<img src="https://stylesrebelradio.files.wordpress.com/2020/09/my-post-13.jpg?w=450"
     alt="It just work's!"
     style="float: left; margin-right: 10px;" />

# Usage

## Loading Files

To load a file from the library use the function `Lib.Require`. Paths use the
`/` instead of `\\` to not forcefully break your fingers.

Example:
```lua
Lib.Require("comfort/GetEnemiesInArea");
```

## File Locations

The library can be packed into the map. The path would be 
`maps/externalmap/cerberus`.
(Don't forget to delete the .git folder!)

The library can also be used in a map that exists as a folder. Then your path
is `maps/user/name_of_map/cerberus`.

The library is packed directly in the root folder of the script.
Then the path is `script/cerberus`.

Additional paths can be defined.

### Load Order

When searching for files the library will check in the following order:
* `maps/user/cerberus`
* `maps/externalmap/cerberus`
* `script/cerberus`

Any custom path will be add before the first entry and checked first.

## Save Games

The function `Mission_OnSaveGameLoaded` is automatically defined by the first
call of `Lib.Require`. If you plan on using this function to reatore the game
state than ensure that it is defined before the first call of `Lib.Require` or
later overwritten in the first map action!

To correctly overwrite the function do the following:
```lua
Mission_OnSaveGameLoaded_Original = Mission_OnSaveGameLoaded;
Mission_OnSaveGameLoaded = function()
    Mission_OnSaveGameLoaded_Original();
    -- Call your stuff here
end
```
Do NOT use the overwrite module for this function! Overwriting 
`Mission_OnSaveGameLoaded` while using an overwrite will cause an infinite
loop and break the game!
