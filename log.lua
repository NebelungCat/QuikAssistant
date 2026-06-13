--
-- log.lua
--
-- Copyright (c) 2016 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

local log = { _version = "0.1.0" }

log.usecolor = true
log.outfile = nil
log.level = "trace"

local logFileHandle = nil
local logFilePath = nil

local modes = {
  { name = "trace", color = "\27[34m" },
  { name = "debug", color = "\27[36m" },
  { name = "info", color = "\27[32m" },
  { name = "warn", color = "\27[33m" },
  { name = "error", color = "\27[31m" },
  { name = "fatal", color = "\27[35m" },
}

local function getLogFile()
  local datetime = os.date("*t", os.time())
  local broker = Broker or ""
  return string.format("/Log/%s/%04d-%02d-%02d.log", broker, datetime.year, datetime.month, datetime.day)
end

local function openLogFile()
  local filePath = getLogFile()
  if logFilePath == filePath and logFileHandle then
    return logFileHandle
  end
  if logFileHandle then
    pcall(function()
      logFileHandle:close()
    end)
  end
  local fp = io.open(getScriptPath() .. filePath, "a")
  if fp then
    logFileHandle = fp
    logFilePath = filePath
    return fp
  end
  return nil
end

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end

local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
end

local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select("#", ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, 0.01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)
    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    local msg = tostring(...)
    local info = debug.getinfo(2, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    print(
      string.format(
        "%s[%-6s%s]%s %s: %s",
        log.usecolor and x.color or "",
        nameupper,
        os.date("%H:%M:%S"),
        log.usecolor and "\27[0m" or "",
        lineinfo,
        msg
      )
    )

    -- Output to log file
    if Broker and Broker ~= "" then
      local fp = openLogFile()
      if fp then
        local str = string.format(
          "%-6s\t\t%s\t\t%s\t\t%s:\t\t%s\n",
          nameupper,
          os.date("%x %X", os.time()),
          Broker,
          lineinfo,
          msg
        )
        local ok, err = pcall(function()
          fp:write(str)
          fp:flush()
        end)
        if not ok then
          logFileHandle = nil
          logFilePath = nil
        end
      end
    end
  end
end

function log.close()
  if logFileHandle then
    pcall(function()
      logFileHandle:close()
    end)
    logFileHandle = nil
    logFilePath = nil
  end
end

return log
