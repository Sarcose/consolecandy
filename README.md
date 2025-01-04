# Debug Candy!
A fun little implementation of some debug tools I like to use, now in convenient library form!

<img src="https://github.com/user-attachments/assets/7f4d1d7c-2143-414e-9012-73be4e7dd330" width="500">

For generating this text, see [Example 1](#Examples)

  * [Installation](#Installation)
  * [Latest Features](#Latest) - updated 01/04/2025
  * [Functions](#Functions)
  * [Arguments](#Arguments)
  * [Customizing](#Customizing)
  * [Examples](#Examples)
  * [Some Notes](#Notes)
  * [ToDo List](#TODO)

## Installation
* `require "debugcandy.lua"` will put the `ccandy` namespace into Global, putting all tools there. 
* `require ("path.debugcandy.lua"):export(n)` will export all of the functions into the Global namespace with the optional `n` prefix.
* Leaving `n` blank will use the prefix `_c_` to avoid overwriting common Lua and Löve names like `error`



## Latest
Last updated 01/04/2025
  * Sequential files are now collapsed into a "line path" so `[update.lua:100][update.lua:55][update.lua:2]` becomes `[update.lua:100:55:2]`.
  * New Customizations! All globals are now local to the library now too. (see [Customizations](#Customizations) )
  * New Optional argument: `parseStart` that modifies how many lines of the stacktrace are ignored
  * Most commands can now call a function if they find them in the `msg` (or `reminderList`) table. See [Example 2](#Examples) for an example of how to do this.
  * backgrounds are now an option, although I have yet to play around with them to figure out what looks good as defaults. The default bgs are eyesores, so they are turned off by default.

## Functions
  * `debug(msg,level,parseStart)`
    * **<code style="color : blue">Default Blue</code>** Prints detailed information on every value including variable type and, if it finds a nested table, it will show how many indices, keys, the memory address, and the depth (recursion is still an issue for me, so it stops at 9 for now). Will **not** call functions, but instead show that the function is there and the addresss. See [Example 3](#Examples) for an example of `debug()` printing a table.
  * `warn(msg,level,parseStart)`
    * **<code style="color : cyan">Default Yellow</code>**. Takes a string or indiced table, will call functions as it finds them.
  * `error(msg,level,parseStart)`
    * **<code style="color : red">Default Red</code>**. Takes a string or indiced table, will call functions as it finds them.
  * `stop(msg,level,parseStart)`
    * **<code style="color : red">Default Red</code>**. Calls `ccandy.error()` and then uses Löve's inbuilt `error()` to stop the game completely. Lets you use the library's own `ccandy.error()` function, while retaining Löve's program-stopping feature of the builtin `error()`
  * `todo(msg)`
    * **<code style="color : cyan">Default Cyan</code>**. Generates a ToDo`[ ]` list from the indiced table. Does not accept `functions`. If it finds a date in format of `01/01/2025` it will compare it with `os.time()`. If the number of days is ` >= toDoExpiration` it will throw a warning. The warning is **<code style="color : cyan">warning color</code>** at first, then **<code style="color : red">error color</code>** at `days x 3`. Will interpret capital `X` at the beginning of a string as a checkmark on the item `[X]`. **Note:** will parse the first date it finds then treat subsequent datestrings as todolist items. It will otherwise discard the first date it finds after evaluating the expiration status.
      * Since it basically is meant to be called with a table only, it is more [Lua-esque](http://lua-users.org/wiki/LuaStyleGuide) to call it like this: `todo{"01/01/2025","todo1","todo2","Xtodo3"}`
  * `remind(setDate,remindDate,reminderList)`
    * **<code style="color : yellow">Default Yellow</code>**. Like `todo{}` it uses `os.time()` to check the dates. Checks against `remindDate` and, if that date has passed, will print how many days it's been since `setDate` and then print the **indiced items of** `reminderList`. Will call both indiced and non-indiced functions, first calling the indiced ones then the non-indiced ones. It also prints a visually distinct header and footer, which can be set per [Customization](#Customization) below.
  * `blank(msg,lines)`
    * Prints blank newlines to the console, with an optional message. Can be called as `blank()`, `blank(lines)`, or `blank(msg,lines)`. If `lines` is empty, will default to 10 newlines.

## Arguments
All arguments are optional. Using any function with no arguments will result in defaults being used no message being printed.
  * `msg`
    * An indiced table or a string which gets printed. `debug()` will print non-indiced keys, as well. Default just prints blank. If a function is found, most tools will call that function (see the functions list for details)
  * `level`
    * The level of files to parse back in the stacktrace. E.g. `[data.lua:10][src.lua:10]`. It attempts to avoid showing its own filename for obvious reasons. Default is `CANDYDEBUGBASELEVEL` below.
  * `parseStart`
    * How many files of the traceback are omitted in the output. You can usually leave this alone, as the code has been generally tweaked to avoid unnecessary info (such as showing that every function comes from `debugcandy.lua`. However, if you are including the library nested further than one or two additional files, you might want to use this. The default starts at `4` so tweak accordingly.

## Customizing
All of these have default values that produce the results you see in the screenshots.
  * Data Output Customizations:
      * `ccandy.colorsOff` : turns all colors off. Will not affect already-printed outputs. False by default.
      * `ccandy.debugOn`      : Used to activate `debug()`, `todo()`, and `remind()`
      * `ccandy.baseLevel` : For if `level` is not passed
      * `ccandy.pathDepth`      : If `>0`, this will add paths to the parsed stacktrace itself, e.g.: `[src/states/game.lua:100]`
      * `ccandy.tabledepthlimit` : how far `debug()` will parse a nested table before stopping.
      * `ccandy.toDoExpiration` : How many days can pass before `todo()` shows warnings
  * Visual Customizations:
      * `ccandy.reminderheader` and `ccandy.reminderfooter` : are printed before and after reminders to make them standout. They look like the screenshots by default.
      * `ccandy.todotab` : how far indented the todolist is
      * `ccandy.backgrounds` : defaults to false. If true, will use `ccandy.backgrounds` to print background colors to all options. Can be set individually, see `ccandy.bgcolors`
      * `ccandy.colors` : are the colors printed by different functions. These are strings. Can also use ANSI escape codes, ex: `warn = "\x1B[31m"` this will make warnings print red instead of yellow. If you're familiar with these escape codes you can add things like underlines, bold, italics etc. to the output.
        * `warn = "yellow"`
        * `error = "red"`
        * `debug = "blue"`
        * `todo = "cyan"`
        * `remind = "yellow"`
        * `success = "green"`
      * `ccandy.bgcolors` : Only used if `ccandy.backgrounds` is on. These are off by default. Set to nil or "" to turn off individual ones instead.
        * `warn = "yellow"`
        * `error = "red"`
        * `debug = "blue"`
        * `todo = "cyan"`
        * `remind = "yellow"`
        * `success = "green"`
       
        * 
## Examples

### Example 1.
 ```lua
_c_warn("A new console library is in town!")
_c_blank(0)
_c_debug{sup = "sup","you can debug a table and print it with a bunch of data",x=10,y=20,sheesh = "sheesh",isTrue=false}
_c_blank(0)
_c_todo{"02/02/2024","Make an old todo list","todo() can throw a warning if it's been too long since you've updated","Show off features"}
_c_blank(0)
_c_remind("01/03/2025","02/03/2025",{"Clean up _g^crash deprecations",f = function() _c_todo{"Evaluate deprecation stubs","Evaluate namespace stubs","Do the dishes","XMake a todo list","XPost something in time for Vornmas"}end})
_c_blank(0)
_c_error("this is an error, jack",2)
_c_blank(0)
_c_success("successful something or other", 3)
_c_blank(0)
_c_success()
_c_blank("Also I thought it'd be nice to be able to blank the console (blank(n) just prints n or 10 blank lines")
```

### Example 2.
This type of function usage is called [functional programming](https://www.geeksforgeeks.org/functional-programming-paradigm/):
```lua
local function throwDebugError(bad_thing,level,parseLevel)
     return function _c_debug(bad_thing,level,parseLevel) end
end
---somewhere in your code where you need a hard assertion:
if bad_thing then
    _c_stop{"bad_thing happened! Debug Output", throwDebugError(bad_thing,level,parseLevel)}
end
```

### Example 3.
An example of `debug()` printing a table:

<img src="https://github.com/user-attachments/assets/f927ca5b-0b22-4c09-9368-cd121e352f51" width="400">

## Notes

  * File parsing will remove spaces because the stack trace produces a lot of formatting, and debugcandy removes that in favor of its own. That said, if the filename has a space in it, that space will be removed. I don't personally plan to tweak this to "fix" this situation, because spaces are a pain in code files anyway so I never use them, and it's generally not recommended.
  * Most of the time, I am attempting to follow  [Lua style recommendations](http://lua-users.org/wiki/LuaStyleGuide) for cleaner code. Please leave feedback if you use this and find any issues with the formatting!
  * This is not a "live updating" debug tool, nor is it a visual GUI debug tool. There aren't plans for one either. It outputs a static console output, and is meant for during-development stages. Heavy use of these tools *will* affect game performance, so be sure to erase and comment out your uses of these tools when you're not needing them! (and turn off `CANDYDEBUGMODE`)
  * This library *probably* won't dig into memory profiling. If and until it does, pick something from the [Awesome Löve](https://github.com/Löve2d-community/awesome-Löve2d) repo instead.

## ToDo
Planned for the future
  * Play with background settings to produce defaults that look nice.
  * Dig deeper into ANSI escape sequences to provide more shortcuts to those features.
  * Improve recursion detection by `debug()` so `tableDepthLimit` can be expanded safely (I'm not sure the lib is doing it right).
  * Document how `printC()` and `printCTable()` work. These are used internally but users could also access them directly.
  * Memory usage statistics of tables in `debug()`? This might be out of scope for this library. Maybe just use a memory module from 
