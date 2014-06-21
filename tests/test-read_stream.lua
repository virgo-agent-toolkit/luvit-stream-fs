require('helper')
local test = require('tape')('test ReadStream')
local stream = require('stream')

local fs = require('fs')
local path = require('path')
local string = require('string')

local ReadStream = require('../lib/read_stream').ReadStream
local ReadOptions = require('../lib/read_stream').ReadOptions

local text = [[Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim
veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]]

local Sink = stream.Writable:extend()

function Sink:initialize()
  stream.Writable.initialize(self)
  self.text = ""
end

function Sink:_write(data, encoding, cb)
  self.text = self.text .. data
  cb()
end

test('read all', nil, function(t)
  local tmp_file = path.join(__dirname, 'tmp', 'read_all')
  fs.writeFileSync(tmp_file, text)

  local rs = ReadStream:new(tmp_file)

  local sink = Sink:new()
  sink:once('finish', function()
    t:equal(text, sink.text, 'incorrect data from ReadStream')
    t:finish()
  end)
  rs:pipe(sink)
end)

test('read length', nil, function(t)
  local tmp_file = path.join(__dirname, 'tmp', 'read_length')
  fs.writeFileSync(tmp_file, text)

  local options = ReadOptions:new()
  options.length  = 64
  local rs = ReadStream:new(tmp_file, options)

  local sink = Sink:new()
  sink:once('finish', function()
    t:equal(string.sub(text, 1, options.length), sink.text, 'incorrect data from ReadStream')
    t:finish()
  end)
  rs:pipe(sink)
end)
