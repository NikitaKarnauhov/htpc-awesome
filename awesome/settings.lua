local gears = require("gears")

settings = {}

local write_value
local write_record

local function store(f, name, value)
	f:write(name .. " = ")
	write_value(f, value)
end

write_value = function(f, value)
  local t = type(value)
      if t == 'nil'    then f:write('nil')
  elseif t == 'number' then f:write(value)
  elseif t == 'string' then f:write('"' .. value .. '"')
  elseif t == 'table'  then write_record(f, value)
  end
end

write_record = function(f, t)
  local i, v = next(t, nil)
  f:write('{')
  while i do
    store(f, i, v)
    f:write(', ')
    i, v = next(t, i)
  end
  f:write('}')
end

local filename = gears.filesystem.get_cache_dir() .. "/settings.lua"

function load_settings()
    local f = io.open(filename)
	if f then
		f:close()
		dofile(filename)
	end
end

function save_settings()
    local f = io.open(filename, "w")
	if f then
		f:write('settings = ')
		write_value(f, settings)
		f:close()
	end
end
