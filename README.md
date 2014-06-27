luvit-stream-fs
===============

Package `stream-fs` provides filesystem access through `luvit-stream`
compatible interfaces.

## Example

```
#!/usr/bin/env luvit

local fs = require('.')
local stream = require('stream')

local observable = stream.Observable:new()
local observer = observable:observe()

local from = fs.ReadStream:new(process.argv[1])
local to = fs.WriteStream:new(process.argv[2])

observer:pipe(process.stdout)
from:pipe(observable):pipe(to)
```

```
$ cat input
Hello!
$ ./tee.lua input output
Hello!
$ cat output
Hello!
```
