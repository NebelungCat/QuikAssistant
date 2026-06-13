require("SubmittingOrders")
require("TableConstructor")
require("TradeSave")

json = require("json")

function N_OnInit()
  if isConnected() == 0 then
    log.error("N_OnInit() ошибка подключения к серверу")
    return
  end
  -- Очистка кэша данных
  ClearSecurityInfoCache()
  Initialization()
  UpdateTableSetting()
  RefreshTableOrdersControl()
  log.debug("N_OnInit() инициализация завершена")
end

-- Основной цикл обработки заявок, выполняется в цикле while в главной функции
function N_OnMainLoop()
  if isConnected() == 0 then
    log.error("N_OnMainLoop() ошибка подключения к серверу")
    return
  end
  SubmittingOrders()
  RefreshDataToTableSetting(tableSetting)
  RefreshTableOrdersControl()
end

-- Обработчик остановки скрипта
function N_OnStop()
  -- Удаление окон таблиц
  tableSetting:Delete()
  tableOrdersControl:Delete()
  -- Сохранение данных
  log.debug("N_OnStop() завершение работы скрипта")
end

function N_OnClose()
  -- Удаление окон таблиц
  log.debug("N_OnClose() закрытие соединения")
end

-- Обработчик ошибки отправки транзакции
function N_OnTransSendError(trans)
  SetLimitOrdersWithError(trans)
  log.debug(
    "N_OnTransSendError() ошибка отправки транзакции "
      .. trans.trans_id
      .. ": "
      .. trans.result_msg
  )
  log.trace(json.encode(trans))
end

-- Обработчик ошибки исполнения транзакции
function N_OnTransExecutionError(trans)
  -- Обработка ошибок для повторной отправки заявки (если это возможно)
  SetLimitOrdersWithError(trans)
  log.debug(
    "N_OnTransExecutionError() ошибка исполнения транзакции "
      .. trans.trans_id
      .. ": "
      .. trans.result_msg
      .. " (по бумаге "
      .. trans.sec_code
      .. ", количество "
      .. trans.quantity
      .. ", цена "
      .. (trans.price or "nil")
      .. ")"
  )
  log.trace(json.encode(trans))
end

-- Обработчик успешного исполнения транзакции
function N_OnTransOK(trans)
  log.debug("N_OnTransOK() транзакция " .. trans.trans_id .. " успешно исполнена")
  log.trace(json.encode(trans))
end

-- Обработчик новой заявки
function N_OnNewOrder(order)
  log.debug(
    "N_OnNewOrder() создана новая заявка №"
      .. order.order_num
      .. " по транзакции №"
      .. order.trans_id
      .. ", бумага: "
      .. order.sec_code
      .. ", цена: "
      .. order.price
      .. ", количество: "
      .. order.qty
  )
  log.trace(json.encode(order))
end

-- Обработчик заявки, которая частично исполнилась
function N_OnExecutionOrder(order)
  log.debug(
    "N_OnExecutionOrder() исполнение заявки №"
      .. order.order_num
      .. " executed на "
      .. (order.qty - (order.last_execution_count or 0))
      .. " из "
      .. order.balance
  )
  log.trace(json.encode(order))
end

-- Обработчик новой сделки
function N_OnNewTrade(trade)
  -- Сохранение сделки в файл
  TradeSave(trade)

  -- Закрытие позиции по сделке
  TradeClosePosition(trade)

  log.debug(
    "N_OnNewTrade() новая сделка №"
      .. trade.trade_num
      .. " по транзакции №"
      .. trade.trans_id
      .. " по цене "
      .. trade.price
      .. " кол-во "
      .. trade.qty
  )
  log.trace(json.encode(trade))
end

-- Счётчик рекурсии для защиты от бесконечного цикла
local limitOrderRecursionDepth = 0
local LIMIT_ORDER_MAX_RECURSION = 3

-- Функция отправки ограничительной заявки на биржу
function N_SetLimitOrder(
  accountCode,
  clientCode,
  classCode,
  securiyCode,
  operation, -- Операция ('B' - buy, 'S' - sell)
  price,
  quantity
)
  -- Защита от бесконечной рекурсии (N_SetLimitOrder -> ошибка -> SetLimitOrdersWithError -> N_SetLimitOrder)
  limitOrderRecursionDepth = limitOrderRecursionDepth + 1
  if limitOrderRecursionDepth > LIMIT_ORDER_MAX_RECURSION then
    log.error("Превышена глубина рекурсии N_SetLimitOrder, прерывание")
    limitOrderRecursionDepth = limitOrderRecursionDepth - 1
    return transId, "Превышена глубина рекурсии"
  end

  transId = transId + 1
  local Transaction = {
    ["TRANS_ID"] = tostring(transId),
    ["ACCOUNT"] = accountCode,
    ["CLASSCODE"] = classCode,
    ["SECCODE"] = securiyCode,
    ["ACTION"] = "NEW_ORDER",
    ["TYPE"] = "L",
    ["OPERATION"] = operation,
    ["PRICE"] = price,
    ["QUANTITY"] = quantity,
    ["CLIENT_CODE"] = clientCode,
  }

  log.trace(json.encode(Transaction))

  local ok, Res = pcall(function()
    return sendTransaction(Transaction)
  end)
  if not ok then
    Res = "Ошибка sendTransaction: " .. tostring(Res)
  end
  if Res ~= "" then
    if N_OnTransSendError ~= nil then
      local trans = {}
      trans.trans_id = transId
      trans.transaction = Transaction
      trans.result_msg = Res
      trans.sec_code = securiyCode
      trans.quantity = quantity
      trans.price = price
      N_OnTransSendError(trans)
    end
    limitOrderRecursionDepth = limitOrderRecursionDepth - 1
    return transId, Res
  end

  limitOrderRecursionDepth = limitOrderRecursionDepth - 1
  return transId, Res
end

--- Отмена всех заявок
function N_CloseAllOrder()
  local ord = "orders"
  local orders = SearchItems(ord, 0, getNumberOf(ord) - 1, function(F)
    return ((F & FLAG_ACTIVE) ~= 0)
  end, "flags")
  if (orders ~= nil) and (#orders > 0) then
    for i = 1, #orders do
      local item = getItem(ord, orders[i])
      if item then
        transId = transId + 1
        local transaction = {
          TRANS_ID = tostring(transId),
          ACTION = "KILL_ORDER",
          CLASSCODE = item.class_code,
          SECCODE = item.sec_code,
          ORDER_KEY = tostring(item.order_num),
        }
        pcall(function()
          sendTransaction(transaction)
        end)
      end
    end
  end
  tableOrdersControl:Clear()
end
