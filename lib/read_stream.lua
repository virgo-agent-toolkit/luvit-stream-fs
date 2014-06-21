local core = require('core')
local pathlib = require('path')
local fs = require('fs')

local Readable = require('stream').Readable

local ReadOptions = core.Object:extend()

function ReadOptions:initialize()
  self.flags = 'r'
  self.mode = '0644'
  self.offset = 0
  self.chunk_size = 65536
  self.fd = nil
  self.length = nil
end

local ReadStream = Readable:extend()

function ReadStream:initialize(path, options)
  Readable.initialize(self)

  self.destroyed = false
  self.reading = false

  self.path = path
  self.options = options or ReadOptions:new()

  if not core.instanceof(self.options, ReadOptions) then
    self:emit('error', core.Error:new("options is not type of ReadOptions"))
    return
  end
  
  self.offset = self.options.offset
  if self.options.length ~= nil then
    self.last = self.options.offset + self.options.length
  end

  if self.options.fd ~= nil then
    self.fd = self.options.fd
  else
    self:open()
  end
end

function ReadStream:open()
  fs.open(self.path, self.options.flags, self.options.mode, function(er, fd)
    if er then
      self:destroy()
      self:emit('error', er)
      return
    end
    self.fd = fd
    self:emit('open', fd)
  end)
end

function ReadStream:_read(n)
  if self.destroyed then
    return
  end

  if self.fd == nil then
    self:once('open', function()
      self:_read(n)
    end)
    return
  end

  if self.reading then
    process.nextTick(function()
      self:_read(n)
    end)
    return
  end

  local to_read = self.options.chunk_size
  if self.last ~= nil then
    -- indicating length was set in option; need to check boundary
    if to_read + self.offset > self.last then
      to_read = self.last - self.offset
    end
  end

  self.reading = true

  fs.read(self.fd, self.offset, to_read, function(err, chunk, len)
    if err or len == 0 then
      self:destroy(function()
        self:push(nil)
      end)
      if err then
        self:emit("error", err)
      end
      self.reading = false
    else
      self:push(chunk)
      self.offset = self.offset + len
      self.reading = false
    end
  end)
end

function ReadStream:destroy(callback)
  if self.destroyed then
    return
  end
  if self.fd then
    fs.close(self.fd, function(er)
      if er then
        self:emit('error', er)
      else
        self:emit('close')
        self:push(nil)
      end
    end)
    self.fd = nil
    self.destroyed = true
    callback()
  else
    -- fd is not opened yet
    process.nextTick(function()
      self:destroy(callback)
    end)
  end
end

local exports = {}

exports.ReadOptions = ReadOptions
exports.ReadStream = ReadStream

return exports
