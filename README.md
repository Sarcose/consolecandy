## Debug Candy!

A fun little implementation of some debug tools I like to use, now in convenient library form!

* `require "debugcandy.lua"` will put the `ccandy` namespace into Global, putting all tools there. 
* `require ("path.debugcandy.lua"):export(n)` will export all of the functions into the Global namespace with the optional `n` prefix.
* Leaving `n` blank will use the prefix `_c_` to avoid overwriting common Lua and Love names like `error`

<img src="https://github.com/user-attachments/assets/7f4d1d7c-2143-414e-9012-73be4e7dd330" width="600">

**UPDATE:** As of 01/04/2025, sequential files are now collapsed into a "line path" so `[update.lua:100][update.lua:55][update.lua:2]` becomes `[update.lua:100:55:2]`. In addition, an optional global `CANDYPATHDEPTH` has been added. See below.

`debug()`,`error()`, `warn()`, and `success()` all print the passed message (including if it's a table, which they will iterate and print), and trace back the command call for as many levels as `level` is passed.

The global constants used are:
  * `CANDYDEBUGMODE` : Used to activate `debug()`, `todo()`, and `remind()` to let users declutter the console space when just looking for more serious `error`s and `warn`ings
  * `CANDYDEBUGBASELEVEL` : The default level of stacktracing that gets reported to the console. This comes in the form of `[data.lua:100][src.lua:10][main.lua:256]`, where the number is the line number the command was called from.
  * `CANDYTODOEXPIRATION` : In days. `todo()` allows you to pass a date as the first entry, which gets compared with the current date using `os.time()` and, if it's been this many days or more, will give you a warning. At `days x 3` the warning goes from yellow to red.
  * `CANDYPATHDEPTH` : if greater than 0, this will add the filepath for the filename itself, such as `[src/states/game.lua:100]` instead of simply showing `[game.lua:100]`

  More info on each function:

  * `debug(msg,level)` - Prits blue to the console. Will print variable types and values of every item in the msg table (or just the msg variable if it's not a table), and if it finds a table nested it will print how many keys, indices, the memory address, and how deep the table goes (with limited functionality to avoid recursion - I'm still figuring that part out). All formatted to (mostly) line up neatly.
  * An example of `debug()` printing a table:
   <img src="https://github.com/user-attachments/assets/f927ca5b-0b22-4c09-9368-cd121e352f51" width="400">

  * `warn(msg,level)` - Prints yellow to the console
  * `error(msg,level)` - Prints red to the console.
  * `stop(msg,level)` - Calls `ccandy.error(msg,level)` and then uses Love's inbuilt `error()` to stop the game completely. Lets you stop the program with a little more detailed readout.
  * `todo{"DD/MM/YYYY","unchecked listitem 1","Xchecked listitem 2"}` - Prints Cyan to the console. Generates a ToDo`[ ]` list. The first entry is checked against the indicated format to determine if it is a date, and then compares with `os.time()` and `CANDYTODOEXPIRATION` in days to determine whether to throw a warning and whether that warning is yellow or red. Will interpret capital `X` at the beginning of a string as a checkmark on the item `[X]`
  * `remind(setDate,remindDate,reminderList)` - Prints Yellow to the console. Like `todo{}` it uses `os.time()` to check the dates. Checks against `remindDate` and, if that date has passed, will print how many days it's been since `setDate` and then print the `reminderList`. `reminderList` can accept an arbitrary number of functions, and it will call those functions non-deterministically if it them. This way you can do something crazy like nest `todo{}` inside of it..
  * `blank(msg,lines)` - Prints blank newlines to the console, with an optional message. Can be called as `blank()`, `blank(lines)`, or `blank(msg,lines)`. If `lines` is empty, will default to 10 newlines.

  The code to generate the screenshot above is as follows:
 ```
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


## Customizing
For now, only the header and footer of `remind()` can be edited but I'm working on getting it to the point where the colors can be picked. 
`ccandy.reminderheader` and `ccandy.reminderfooter` are those variables. Leave them alone and they'll look like the screenshot.
