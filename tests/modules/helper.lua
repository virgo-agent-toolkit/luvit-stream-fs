local fs = require('fs')
local path = require('path')

local tmp_dir = path.join(__dirname, '..', 'tmp')
if not fs.existsSync(tmp_dir) then
  fs.mkdirSync(tmp_dir, '0755')
end
