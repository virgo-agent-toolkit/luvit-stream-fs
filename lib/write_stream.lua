local core = require('core')
local pathlib = require('path')
local fs = require('fs')
local string = require('string')

local Writable = require('stream').Writable

local WriteOptions = core.Object:extend()

function WriteOptions:initialize()
  self.flags = 'w'
  self.mode = '0644'
  self.offset = 0
  self.fd = nil
end

local WriteStream = Writable:extend()

function WriteStream:initialize(path, options)
  Writable.initialize(self)

  self.destroyed = false

  self.path = path
  self.options = options or WriteOptions:new()

  if not core.instanceof(self.options, WriteOptions) then
    self:emit('error', core.Error:new("options is not type of WriteOptions"))
    return
  end
  
  self.offset = self.options.offset

  if self.options.fd ~= nil then
    self.fd = self.options.fd
  else
    self:open()
  end
end

function WriteStream:open()
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

function WriteStream:_write(data, encoding, callback)
  if self.destroyed then
    return
  end

  if self.fd == nil then
    self:once('open', function()
      self:_write(data, encoding, callback)
    end)
    return
  end

  fs.write(self.fd, self.offset, data, function(err, len)
    if err or len == 0 then
      self:destroy(function()
        callback(err)
      end)
    else
      callback()
    end
  end)
  self.offset = self.offset + string.len(data)
end

function WriteStream:destroy(callback)
  if self.destroyed then
    return
  end
  if self.fd then
    fs.close(self.fd, function(er)
      if er then
        self:emit('error', er)
      else
        self:emit('close')
      end
    end)
    self.fd = nil
    self.destroyed = true
    callback()
  else
    -- fd is not opened yet
    self:once('open', function()
      self:destroy(callback)
    end)
  end
end

local exports = {}

exports.WriteOptions = WriteOptions
exports.WriteStream = WriteStream

return exports
