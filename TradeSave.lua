--Сохранение сделки в лог и в файл истории сделок
function TradeSave(trade)
  local Operation = ""
  if (trade.flags & FLAG_EXECUTED) ~= 0 then
    Operation = "-"
  else
    Operation = ""
  end

  local TradeLine = os.date("%Y-%m-%d")
    .. " "
    .. os.date("%X", os.time())
    .. ";"
    .. trade.sec_code
    .. ";"
    .. Operation
    .. trade.qty
    .. ";"
    .. trade.price
    .. ";"
    .. Broker
    .. "\n"

  local fp, err = io.open(getScriptPath() .. "//Data//MyTrades.csv", "a+")
  if not fp then
    log.error("Не удалось открыть MyTrades.csv: " .. tostring(err))
    return
  end

  local ok, werr = pcall(function()
    fp:write(TradeLine)
  end)
  if not ok then
    log.error("Ошибка записи в MyTrades.csv: " .. werr)
  end

  pcall(function()
    fp:flush()
  end)
  pcall(function()
    fp:close()
  end)
end
