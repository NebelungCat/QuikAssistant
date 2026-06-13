---------------------------------------------------------------------------
-- Функции для работы с файлами
--
-- @author Nebelung (Nebelung.Programming@mail.ru)
--
-- @copyright 2021 Nebelung Project
---------------------------------------------------------------------------

local csv = require("csv")

function getFromCSV(nameFileCSV)
  local result = {}
  local path = getScriptPath() .. "//Data//" .. nameFileCSV
  local fileCSV = csv.open(path)

  if fileCSV ~= nil then
    for r in fileCSV:lines() do
      local r2 = {}
      for i, v in ipairs(r) do
        r2[#r2 + 1] = tostring(v)
      end
      result[#result + 1] = r2
    end
  else
    log.warn("Не удалось открыть CSV файл: " .. path)
  end

  return result
end
