package.path = getScriptPath() .. "\\?.lua;"

require("Assistant")

log = require("log")

isRun = true
transId = os.time() -- Номер стартовый и используется для идентификации транзакции, привязки заявки к транзакции

N_TransReplies = {} -- Таблица для хранения ответов от сервера
N_LastTransID = 0 -- Последний ID транзакции, который был обработан и сохранён в таблице на экране
N_Orders = {} -- Таблица для хранения активных заявок на экране
N_LastOrderNum = 0 -- Последний номер заявки, которая была обработана и сохранена в таблице на экране
N_Trades = {} -- Таблица для хранения активных сделок на экране
N_LastTradeNum = 0 -- Последний номер сделки, которая была обработана и сохранена в таблице на экране

function main()
  -- Основной цикл
  while isRun do
    -- Вызов основного цикла работы скрипта, если он существует
    if N_OnMainLoop ~= nil then
      N_OnMainLoop()
    end

    -- Обработка событий

    -- Обработка ответов от сервера
    for i, TransReplie in ipairs(N_TransReplies) do
      -- Если данный ответ ещё не был обработан
      if N_TransReplies[i].checked == nil then
        -- Проверка на наличие ошибок в ответе
        if N_TransReplies[i].status > 1 and N_TransReplies[i].status ~= TRANS_STATUS_COMPLETED then
          -- Если произошла ошибка
          -- Вызов обработчика ошибки транзакции (если он существует)
          if N_OnTransExecutionError ~= nil then
            N_OnTransExecutionError(N_TransReplies[i])
          end
          -- Отмечаем, что данный ответ обработан
          N_TransReplies[i].checked = true
        elseif N_TransReplies[i].status == TRANS_STATUS_COMPLETED then
          -- Вызов обработчика успешной транзакции (если он существует)
          if N_OnTransOK ~= nil then
            N_OnTransOK(N_TransReplies[i])
          end
          -- Отмечаем, что данный ответ обработан
          N_TransReplies[i].checked = true
        end
      end
    end

    -- Обработка заявок
    for i, Order in ipairs(N_Orders) do
      -- Если данная заявка ещё не была обработана
      if N_Orders[i].checked == nil then
        -- Вызов обработчика новой заявки (если он существует)
        if N_OnNewOrder ~= nil then
          N_OnNewOrder(N_Orders[i])
        end
        N_Orders[i].checked = true
      end
      -- Подсчёт количества исполненных лотов по заявке
      local ExecutionCount = N_Orders[i].qty - N_Orders[i].balance
      -- Если ещё есть лоты для исполнения, и количество исполненных лотов изменилось по сравнению с предыдущим циклом, то вызываем обработчик
      if
        (N_Orders[i].last_execution_count == nil or N_Orders[i].last_execution_count ~= ExecutionCount)
        and ExecutionCount > 0
      then
        -- Вызов обработчика исполнения заявки (если он существует)
        if N_OnExecutionOrder ~= nil then
          N_OnExecutionOrder(N_Orders[i])
          -- Сохранение количества исполненных лотов для сравнения в следующем цикле
          N_Orders[i].last_execution_count = ExecutionCount
        end
      end
    end

    -- Обработка сделок
    local tradesToRemove = {}
    local ordersToRemove = {}
    local repliesToRemove = {}

    for i, Trade in ipairs(N_Trades) do
      if N_Trades[i].order_num ~= nil then
        for j, Order in ipairs(N_Orders) do
          if N_Trades[i].order_num == N_Orders[j].order_num then
            N_Trades[i].trans_id = N_Orders[j].trans_id
            if N_OnNewTrade ~= nil then
              N_OnNewTrade(N_Trades[i])
            end
            N_LastTradeNum = N_Trades[i].trade_num
            tradesToRemove[N_Trades[i].trade_num] = true

            if N_Orders[j].last_execution_count ~= nil and N_Orders[j].last_execution_count == N_Orders[j].qty then
              N_LastTransID = N_Orders[j].trans_id
              ordersToRemove[N_Orders[j].order_num] = true
              for k, TransReply in ipairs(N_TransReplies) do
                if TransReply.trans_id == N_Orders[j].trans_id then
                  repliesToRemove[k] = true
                end
              end
              N_LastOrderNum = N_Orders[j].order_num
              break
            end
          end
        end
      end
    end

    -- Безопасное удаление помеченных элементов в обратном порядке
    for i = #N_TransReplies, 1, -1 do
      if repliesToRemove[i] then
        table.remove(N_TransReplies, i)
      end
    end
    for i = #N_Orders, 1, -1 do
      if ordersToRemove[N_Orders[i].order_num] then
        table.remove(N_Orders, i)
      end
    end
    for i = #N_Trades, 1, -1 do
      if tradesToRemove[N_Trades[i].trade_num] then
        table.remove(N_Trades, i)
      end
    end

    sleep(1000)
  end
end

-- Функция обработки ответа сервера на отправленную транзакцию
function OnTransReply(trans_reply)
  -- Если она обработана в таблице, то пропускаем
  --  if trans_reply.brokerref:find('N_'..SEC_CODE) == nil then return end
  -- Поиск ответа в таблице по номеру транзакции
  for i, TransReply in ipairs(N_TransReplies) do
    -- Если данный ответ уже есть в таблице по номеру транзакции
    if N_TransReplies[i].trans_id == trans_reply.trans_id then
      -- Если данная заявка уже была обработана, то помечаем её для обработки
      if N_TransReplies[i].checked ~= nil then
        trans_reply.checked = true
      end
      -- Заменяем старую запись на новую
      table.sremove(N_TransReplies, i)
      table.sinsert(N_TransReplies, trans_reply)
      -- Выходим из функции
      return
    end
  end
  -- Если такой нет в таблице, то добавляем
  if N_LastTransID < trans_reply.trans_id then
    table.sinsert(N_TransReplies, trans_reply)
  end
end

-- Функция обработки ответа сервера на исполнение/изменение заявки на экране
function OnOrder(order)
  -- Если она обработана в таблице, то пропускаем
  --  if order.brokerref:find('N_'..SEC_CODE) == nil then return end
  -- Поиск заявки в таблице
  for i, Order in ipairs(N_Orders) do
    -- Если заявка уже существует в таблице
    if N_Orders[i].trans_id == order.trans_id then
      -- Если данная заявка уже была обработана, то помечаем её для обработки
      if N_Orders[i].checked ~= nil then
        order.checked = true
      end
      -- Если количество исполненных лотов было обработано, то переносим его в новую заявку
      if N_Orders[i].last_execution_count ~= nil then
        order.last_execution_count = N_Orders[i].last_execution_count
      end
      -- Заменяем старую запись на новую
      table.sremove(N_Orders, i)
      table.sinsert(N_Orders, order)
      -- Выходим из функции
      return
    end
  end
  -- Если такой нет в таблице, то добавляем
  if N_LastOrderNum < order.order_num then
    table.sinsert(N_Orders, order)
  end
end

-- Функция обработки ответа сервера на исполнение/изменение сделки на экране
function OnTrade(trade)
  -- Если она обработана в таблице, то пропускаем
  --  if trade.brokerref:find('N_'..SEC_CODE) == nil then return end
  -- Поиск сделки в таблице
  for i, Trade in ipairs(N_Trades) do
    -- Если номер сделки уже существует в таблице
    if N_Trades[i].trade_num == trade.trade_num then
      -- Если данная сделка уже была обработана, то помечаем её для обработки
      if N_Trades[i].checked ~= nil then
        trade.checked = true
      end
      -- Заменяем старую запись на новую
      table.sremove(N_Trades, i)
      table.sinsert(N_Trades, trade)
      -- Выходим из функции
      return
    end
  end
  -- Если такой нет в таблице, то добавляем
  if N_LastTradeNum < trade.trade_num then
    table.sinsert(N_Trades, trade)
  end
end

function OnInit()
  if N_OnInit ~= nil then
    N_OnInit()
  end
end

-- Функция обработки события завершения работы терминала
function OnStop()
  isRun = false

  if N_OnStop ~= nil then
    N_OnStop()
  end
end

function OnClose()
  if N_OnClose ~= nil then
    N_OnClose()
    sleep(1000)
  end
end
