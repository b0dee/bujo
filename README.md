# BuJo - Bullet Journal

A decently customisable bullet journalling cli written in bash 

Minimal binary dependencies: 
* date
* expr
* dirname
* basename
* printf
* cat

Complements existing workloads as operates solely on markdown files agnostic of
any systems (so long as they store raw files it should work).

Supports piping

## Usage

```shell
bujo [opts] [note input can have spaces without quotes]

A command line utility for rappid note logging

Parameters:
  -l|--list               List (tree) entries and exit
  -g|--grep [args]        Run `grep` against $BUJO_ROOT
  -t|--task|--todo        Mark entry as a todo
  -c|--collection <name>  Specify collection (filename). Accepts subpaths, i.e. docs/collections
                          Append trailing slash to denote directory.
  -o|--open               Open editor instead of exiting
  -T0                     Do not include timestamp (default unless configured)
  -T                      Include timestamp
  -h|                     Print short help.
  --help                  Print full help.
  -H|--heading <title>    Specify custom title (collection name if ommitted)
  -d|--debug              Print debug messages

Pattern Substitutions:
  %y - Year
  %m - Month
  %d - Day
  %w - Week of month (based off $BUJO_WEEK_START)
  %H - Hour
  %M - Minute

Configuration:
  $BUJO_ROOT                   Base path to use, defaults to ~/.bujo
  $BUJO_WEEK_START             Day to use as first day of week (from 0 to 6, 0 being Sunday, 6 being Saturday). Defaults to 1 (Monday)
  $BUJO_EDITOR                 Editor to use, defaults to $EDITOR
  $BUJO_FILENAME               Filename format to use when not specifying collection
  $BUJO_INCLUDE_TIMESTAMP      Whether to log a timestamp before each action. Is overwritten by parameters

Entries can be written naturally with no need for quoting, i.e.
  bujo Today I tried bujo cli
Creates the entry `Today I tried bujo cli` in the default file

Because of this, you need to quote any positional argument containing spaces, i.e.
  bujo -c examples/spaces in args -H "Your custom header" With a note entry
Creates a file under the `examples` folder in $BUJO_ROOT named `spaces in args` with the title set
to `Your custom header` and the entry `With a note entry`
```

## Configuration

Shell environment variables to configure behaviour

- `$EDITOR` - default editor to use 
- `$BUJO_ROOT` - path to bujo root (default: "~/.bujo")
- `$BUJO_FILENAME` - filename when no collection specified (default: "%y_%m_%d")
- `$BUJO_WEEK_START` - week start day (default: uses system locale)
- `$BUJO_INCLUDE_COLLECTION_NAME` - include collection name as a header when
first creating file
- `$BUJO_INCLUDE_TIMESTAMP` - log date and time in file each time a command is
run (separates input by blank line)

Available placeholders for filename: 
- `%y` - Year
- `%m` - Month
- `%w` - Week
- `%d` - Day

## FAQ

### Why no 'rm' command

It's easy enough to do yourself, safer too.

