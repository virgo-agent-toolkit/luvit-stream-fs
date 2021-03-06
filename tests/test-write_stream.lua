require('helper')
local test = require('tape')('test ReadStream')
local stream = require('stream')

local fs = require('fs')
local path = require('path')
local string = require('string')

local WriteStream = require('../lib/write_stream').WriteStream
local WriteOptions = require('../lib/write_stream').WriteOptions

local text = [[Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]]

local Source = stream.Readable:extend()

function Source:initialize(data)
  stream.Readable.initialize(self)
  self.pos = 1
  self.data = data or text
end

function Source:_read(n)
  if self.pos > string.len(self.data) then
    self:push(nil)
  else
    self:push(string.sub(self.data, self.pos, self.pos + n - 1))
    self.pos = self.pos + n
  end
end

test('simple write', nil, function(t)
  local tmp_file = path.join(__dirname, 'tmp', 'write_all')

  local ws = WriteStream:new(tmp_file)

  local source = Source:new()
  ws:once('finish', function()
    local written = fs.readFileSync(tmp_file)
    t:equal(text, written, 'incorrect data from ReadStream')
    t:finish()
  end)
  source:pipe(ws)
end)

test('write large', nil, function(t)
  local tmp_file = path.join(__dirname, 'tmp', 'write_large')

  local large = ''
  local l = 0
  while l <= 16 * 1024 do -- default hwm in Writable
    l = l + string.len(text)
    large = large .. text
  end

  local options = WriteOptions:new()
  local ws = WriteStream:new(tmp_file, options)

  local source = Source:new(large)
  ws:once('finish', function()
    local written = fs.readFileSync(tmp_file)
    t:equal(large, written, 'incorrect data from ReadStream')
    t:finish()
  end)
  source:pipe(ws)
end)
