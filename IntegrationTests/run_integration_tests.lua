-- Интеграционные тесты QUIK Assistant
-- Запуск: cd QuikAssistant && lua IntegrationTests/run_integration_tests.lua --broker=TEST --session=main
--
-- Параметры:
--   --broker=NAME    Имя брокера: FINAM, VTB, PSB, RSHB, TEST
--   --session=TYPE   Тип сессии: morning, main, evening
--
-- Примеры:
--   lua IntegrationTests/run_integration_tests.lua --broker=VTB --session=main
--   lua IntegrationTests/run_integration_tests.lua --broker=FINAM --session=morning
--   lua IntegrationTests/run_integration_tests.lua --broker=TEST --session=evening

-- ==========================================
-- 1. Разбор аргументов командной строки
-- ==========================================

local brokerName = "TEST"
local sessionType = "main"

for _, v in ipairs(arg or {}) do
  local name, value = v:match("^%-%-(.+)=(.+)$")
  if name == "broker" then
    brokerName = string.upper(value)
  elseif name == "session" then
    sessionType = string.lower(value)
  end
end

local validBrokers = { FINAM = true, VTB = true, PSB = true, RSHB = true, TEST = true }
local validSessions = { morning = true, main = true, evening = true }

if not validBrokers[brokerName] then
  print(
    "ОШИБКА: Неизвестный брокер '"
      .. brokerName
      .. "'. Допустимые: FINAM, VTB, PSB, RSHB, TEST"
  )
  os.exit(1)
end
if not validSessions[sessionType] then
  print(
    "ОШИБКА: Неизвестная сессия '"
      .. sessionType
      .. "'. Допустимые: morning, main, evening"
  )
  os.exit(1)
end

-- ==========================================
-- 2. Настройка путей
-- ==========================================

package.path = "C:\\Users\\Dexter\\source\\repos\\QuikAssistant\\?.lua;" .. package.path

-- ==========================================
-- 3. Загрузка мока и настроек брокера
-- ==========================================

dofile("IntegrationTests/quik_mock_integration.lua")
dofile("IntegrationTests/broker_settings.lua")

-- Переназначаем getInfoParam для выбранного брокера
local brokerUserId = BrokerSettings[brokerName].userId
_G.getInfoParam = function(param)
  if param == "USERID" then
    return brokerUserId
  end
  if param == "SERVERTIME" then
    return os.date("%H:%M:%S")
  end
  return ""
end

print(string.format("\n========================================"))
print(string.format("  ИНТЕГРАЦИОННЫЕ ТЕСТЫ QUIK ASSISTANT"))
print(string.format("  Брокер: %s (USERID=%s)", brokerName, brokerUserId))
print(string.format("  Сессия: %s", sessionType))
print(string.format("========================================\n"))

-- ==========================================
-- 4. Загрузка логгера (реальный, не мок)
-- ==========================================

log = require("log")
log.level = "trace"
log.usecolor = false

-- ==========================================
-- 5. Загрузка модулей проекта
-- ==========================================

require("TableConstructor")
require("TableSetting")
require("Setting")
require("FileFunction")
require("Order")
require("QuikFunction")
require("TradeSave")
require("TableOrders")
require("SubmittingOrders")

json = require("json")

-- ==========================================
-- 6. Инициализация системы
-- ==========================================

transId = os.time()
N_TransReplies = {}
N_LastTransID = 0
N_Orders = {}
N_LastOrderNum = 0
N_Trades = {}
N_LastTradeNum = 0

-- Определяем брокера через QUIK API (как в реальном запуске)
SetClientSetting()

print(string.format("Брокер определён: %s", Broker))
print(string.format("Код клиента: %s", ClientCode))
print(string.format("Код счета: %s", AccountCode))
print(string.format("Фирма: %s", FirmId))
print(string.format("Файл покупок: %s", FileBuyOrder))
print(string.format("Файл продаж: %s", FileSellOrder))
print(string.format("Файл покупок (edge): %s", FileBuyOrderEdge))
print(string.format("Файл покупок облигаций (edge): %s", FileBuyOrderBondsEdge))
print("")

-- ==========================================
-- 7. Настройка времени сессии
-- ==========================================

-- Время "завтра" для установки будущих окон
local tomorrow = os.time() + 86400

-- Утреннее окно всегда в прошлом (для вызова SubmittingOrdersRun)
TimeMorningStart = os.date("!*t", os.time())
TimeMorningStart.hour = 7
TimeMorningStart.min = 0
TimeMorningStart.sec = 30

-- Дневное и вечернее окна - в зависимости от сессии
if sessionType == "morning" then
  -- Только утро: дневное и вечернее окна в будущем
  TimeMainStart = os.date("!*t", tomorrow)
  TimeMainStart.hour = 10
  TimeMainStart.min = 0
  TimeMainStart.sec = 30

  TimeEveningStart = os.date("!*t", tomorrow)
  TimeEveningStart.hour = 19
  TimeEveningStart.min = 2
  TimeEveningStart.sec = 10
elseif sessionType == "main" then
  -- Утро + день: вечернее окно в будущем
  TimeMainStart = os.date("!*t", os.time())
  TimeMainStart.hour = 10
  TimeMainStart.min = 0
  TimeMainStart.sec = 30

  TimeEveningStart = os.date("!*t", tomorrow)
  TimeEveningStart.hour = 19
  TimeEveningStart.min = 2
  TimeEveningStart.sec = 10
elseif sessionType == "evening" then
  -- Все три окна в прошлом
  TimeMainStart = os.date("!*t", os.time())
  TimeMainStart.hour = 10
  TimeMainStart.min = 0
  TimeMainStart.sec = 30

  TimeEveningStart = os.date("!*t", os.time())
  TimeEveningStart.hour = 19
  TimeEveningStart.min = 2
  TimeEveningStart.sec = 10
end

-- Сброс флагов сессии
IsSentOrders = false
IsSendingOrders = false
IsMorningTime = false
IsMainTime = false
IsEveningTime = false

print(string.format("Настройка сессии '%s':", sessionType))
print(
  string.format(
    "  TimeMorningStart: %02d:%02d:%02d UTC",
    TimeMorningStart.hour,
    TimeMorningStart.min,
    TimeMorningStart.sec
  )
)
print(string.format("  TimeMainStart:    %02d:%02d:%02d UTC", TimeMainStart.hour, TimeMainStart.min, TimeMainStart.sec))
print(
  string.format(
    "  TimeEveningStart: %02d:%02d:%02d UTC",
    TimeEveningStart.hour,
    TimeEveningStart.min,
    TimeEveningStart.sec
  )
)
print("")

-- ==========================================
-- 8. Проверка параметров инструментов
-- ==========================================

print("--- Проверка параметров инструментов ---")
print("")

-- Тестовые тикеры
local testStockTickers = { "GAZP", "SBER", "LKOH", "VTBR", "FESH" }
local testBondTickers = { "RU000A10BFF4", "SU26224RMFS4", "RU000A10BFG2", "RU000A0ZZRY2", "RU000A0ZZGT5" }

print("Акции (тикер <= 7 символов):")
for _, ticker in ipairs(testStockTickers) do
  local info = getSecurityInfo("TQBR", ticker)
  local params = getParamEx("TQBR", ticker, "LAST")
  local priceMin = getParamEx("TQBR", ticker, "PRICEMIN")
  local priceMax = getParamEx("TQBR", ticker, "PRICEMAX")
  print(
    string.format(
      "  %s: класс=%s, номинал=%s, шаг=%s, цена=%s, мин=%s, макс=%s",
      ticker,
      info and info.class_code or "NIL",
      info and tostring(info.face_value) or "NIL",
      info and tostring(info.min_price_step) or "NIL",
      params.param_value,
      priceMin.param_value,
      priceMax.param_value
    )
  )
end
print("")

print("Облигации (тикер > 7 символов):")
for _, ticker in ipairs(testBondTickers) do
  local info = getSecurityInfo("TQOB", ticker)
  local params = getParamEx("TQOB", ticker, "LAST")
  local priceMin = getParamEx("TQOB", ticker, "PRICEMIN")
  local priceMax = getParamEx("TQOB", ticker, "PRICEMAX")
  print(
    string.format(
      "  %s: класс=%s, номинал=%s, шаг=%s, цена=%s%%, мин=%s%%, макс=%s%%",
      ticker,
      info and info.class_code or "NIL",
      info and tostring(info.face_value) or "NIL",
      info and tostring(info.min_price_step) or "NIL",
      params.param_value,
      priceMin.param_value,
      priceMax.param_value
    )
  )
end
print("")

-- ==========================================
-- 9. Загрузка заявок из файлов
-- ==========================================

print("--- Загрузка заявок из CSV файлов ---")
print("")

local allOrders = {}
local fileOrders = {}

-- Загрузка покупок
print("1. Файл покупок: " .. FileBuyOrder)
local buyOrders = LoadOrdersFromFile(FileBuyOrder)
fileOrders.buy = buyOrders
print(string.format("   Загружено: %d заявок", #buyOrders))
for i, order in ipairs(buyOrders) do
  print(
    string.format(
      "   [%d] %s %s кол=%d цена=%.2f",
      i,
      order.Operation,
      order.SecurityCode,
      order.Quantity,
      order.Price
    )
  )
  table.insert(allOrders, order)
end
print("")

-- Загрузка покупок облигаций (edge)
print("2. Файл покупок облигаций (edge): " .. FileBuyOrderBondsEdge)
local bondOrders = LoadOrdersFromFile(FileBuyOrderBondsEdge)
fileOrders.bonds = bondOrders
print(string.format("   Загружено: %d заявок", #bondOrders))
for i, order in ipairs(bondOrders) do
  print(
    string.format(
      "   [%d] %s %s кол=%d цена=%.2f",
      i,
      order.Operation,
      order.SecurityCode,
      order.Quantity,
      order.Price
    )
  )
  table.insert(allOrders, order)
end
print("")

-- Загрузка покупок (edge)
print("3. Файл покупок (edge): " .. FileBuyOrderEdge)
local edgeOrders = LoadOrdersFromFile(FileBuyOrderEdge)
fileOrders.edge = edgeOrders
print(string.format("   Загружено: %d заявок", #edgeOrders))
for i, order in ipairs(edgeOrders) do
  print(
    string.format(
      "   [%d] %s %s кол=%d цена=%.4f",
      i,
      order.Operation,
      order.SecurityCode,
      order.Quantity,
      order.Price
    )
  )
  table.insert(allOrders, order)
end
print("")

-- Загрузка продаж
print("4. Файл продаж: " .. FileSellOrder)
local sellOrders = LoadOrdersFromFile(FileSellOrder)
fileOrders.sell = sellOrders
print(string.format("   Загружено: %d заявок", #sellOrders))
for i, order in ipairs(sellOrders) do
  print(
    string.format(
      "   [%d] %s %s кол=%d цена=%.2f",
      i,
      order.Operation,
      order.SecurityCode,
      order.Quantity,
      order.Price
    )
  )
  table.insert(allOrders, order)
end
print("")

print(string.format("ИТОГО загружено заявок: %d", #allOrders))
print("")

-- ==========================================
-- 10. Первый цикл выставления заявок
-- ==========================================

print("--- Цикл 1: Выставление заявок ---")
print("")

-- Добавляем позиции для продаж (чтобы проверка продаж проходила)
for _, order in ipairs(sellOrders) do
  addTestPosition(order.SecurityCode, order.Quantity, order.Price)
end

-- Сброс флагов перед выставлением
IsSentOrders = false
IsSendingOrders = false
IsMorningTime = false
IsMainTime = false
IsEveningTime = false

-- Вызов SubmittingOrders() (как в реальном цикле main)
-- SubmittingOrders() обновит флаги сессии и вызовет SubmittingOrdersRun()
SubmittingOrders()

local sentAfterFirst = getSentOrdersCount()
print("")
print(string.format("Результат цикла 1: отправлено заявок = %d", sentAfterFirst))
print("")

-- ==========================================
-- 11. Второй цикл выставления заявок (проверка дублей)
-- ==========================================

print("--- Цикл 2: Проверка невозможности выставить дубль ---")
print("")

-- Сброс флагов для второго цикла
IsSentOrders = false
IsSendingOrders = false
IsMorningTime = false
IsMainTime = false
IsEveningTime = false

-- Повторный вызов SubmittingOrders()
SubmittingOrders()

local sentAfterSecond = getSentOrdersCount()
local newOrdersInSecond = sentAfterSecond - sentAfterFirst

print("")
print(string.format("Результат цикла 2: всего заявок в таблице = %d", sentAfterSecond))
print(string.format("Новых заявок во 2-м цикле: %d", newOrdersInSecond))

if newOrdersInSecond == 0 then
  print("ПРОВЕРКА ПРОЙДЕНА: Дублирование заявок предотвращено!")
else
  print("ВНИМАНИЕ: Обнаружены дублирующиеся заявки!")
  for i = sentAfterFirst + 1, sentAfterSecond do
    local order = getSentOrders()[i]
    print(
      string.format("  Дубль: %s %s %s цена=%s", order.sec_code, order.class_code, order.flags, order.price)
    )
  end
end
print("")

-- ==========================================
-- 12. Детальный отчёт по отправленным заявкам
-- ==========================================

print("--- Детальный отчёт ---")
print("")

local allSent = getSentOrders()
print(string.format("Всего отправленных заявок: %d", #allSent))
print("")

-- Группировка по бумагам
local byTicker = {}
for _, order in ipairs(allSent) do
  local key = order.sec_code .. " " .. (order.flags & FLAG_SELL > 0 and "S" or "B")
  if not byTicker[key] then
    byTicker[key] = {
      sec_code = order.sec_code,
      class_code = order.class_code,
      operation = order.flags & FLAG_SELL > 0 and "S" or "B",
      count = 0,
      price = order.price,
      qty = order.qty,
    }
  end
  byTicker[key].count = byTicker[key].count + 1
end

print("Уникальные заявки:")
for _, data in pairs(byTicker) do
  local tickerType = isBondTicker(data.sec_code) and "ОБЛ" or "АКЦ"
  print(
    string.format(
      "  [%s] %s %s %s кол=%d цена=%s (отправлено раз: %d)",
      tickerType,
      data.operation,
      data.sec_code,
      data.class_code,
      data.qty,
      data.price,
      data.count
    )
  )
end
print("")

-- ==========================================
-- 13. Проверка соответствия параметров цен
-- ==========================================

print("--- Проверка параметров цен ---")
print("")

local priceErrors = 0

-- Проверка акций
print("Ожидаемые параметры для акций:")
print("  Цена: 1000 руб")
print("  Мин: 800 руб (на 20% ниже)")
print("  Макс: 1200 руб (на 20% выше)")
print("  Шаг цены: 0.1")
print("")

-- Проверка облигаций
print("Ожидаемые параметры для облигаций (тикер > 7 символов):")
print("  Цена: 100%")
print("  Мин: 80% (на 20% ниже)")
print("  Макс: 120% (на 20% выше)")
print("  Шаг цены: 0.01")
print("")

-- Верификация через реальные вызовы
for _, ticker in ipairs(testStockTickers) do
  local last = tonumber(getParamEx("TQBR", ticker, "LAST").param_value)
  local min = tonumber(getParamEx("TQBR", ticker, "PRICEMIN").param_value)
  local max = tonumber(getParamEx("TQBR", ticker, "PRICEMAX").param_value)
  local info = getSecurityInfo("TQBR", ticker)

  if last ~= 1000 then
    print(string.format("  ОШИБКА: %s LAST=%d (ожидалось 1000)", ticker, last))
    priceErrors = priceErrors + 1
  end
  if min ~= 800 then
    print(string.format("  ОШИБКА: %s PRICEMIN=%d (ожидалось 800)", ticker, min))
    priceErrors = priceErrors + 1
  end
  if max ~= 1200 then
    print(string.format("  ОШИБКА: %s PRICEMAX=%d (ожидалось 1200)", ticker, max))
    priceErrors = priceErrors + 1
  end
  if info and info.min_price_step ~= 0.1 then
    print(
      string.format(
        "  ОШИБКА: %s min_price_step=%s (ожидалось 0.1)",
        ticker,
        tostring(info.min_price_step)
      )
    )
    priceErrors = priceErrors + 1
  end
end

for _, ticker in ipairs(testBondTickers) do
  local last = tonumber(getParamEx("TQOB", ticker, "LAST").param_value)
  local min = tonumber(getParamEx("TQOB", ticker, "PRICEMIN").param_value)
  local max = tonumber(getParamEx("TQOB", ticker, "PRICEMAX").param_value)
  local info = getSecurityInfo("TQOB", ticker)

  if last ~= 100 then
    print(string.format("  ОШИБКА: %s LAST=%d (ожидалось 100)", ticker, last))
    priceErrors = priceErrors + 1
  end
  if min ~= 80 then
    print(string.format("  ОШИБКА: %s PRICEMIN=%d (ожидалось 80)", ticker, min))
    priceErrors = priceErrors + 1
  end
  if max ~= 120 then
    print(string.format("  ОШИБКА: %s PRICEMAX=%d (ожидалось 120)", ticker, max))
    priceErrors = priceErrors + 1
  end
  if info and info.min_price_step ~= 0.01 then
    print(
      string.format(
        "  ОШИБКА: %s min_price_step=%s (ожидалось 0.01)",
        ticker,
        tostring(info.min_price_step)
      )
    )
    priceErrors = priceErrors + 1
  end
end

if priceErrors == 0 then
  print("ПРОВЕРКА ПРОЙДЕНА: Все параметры цен корректны!")
else
  print(
    string.format(
      "ОШИБКИ: Обнаружено %d несоответствий в параметрах цен",
      priceErrors
    )
  )
end
print("")

-- ==========================================
-- 14. Итоговый отчёт
-- ==========================================

print("========================================")
print("  ИТОГОВЫЙ ОТЧЁТ")
print("========================================")
print(string.format("  Брокер:            %s", brokerName))
print(string.format("  Сессия:            %s", sessionType))
print(string.format("  Загружено заявок:  %d", #allOrders))
print(string.format("  Отправлено (ц.1):  %d", sentAfterFirst))
print(string.format("  Отправлено (ц.2):  %d", newOrdersInSecond))
print(string.format("  Ошибки цен:        %d", priceErrors))
print(string.format("  Логи:              Log/%s/", brokerName))
print("========================================")
print("")

if newOrdersInSecond == 0 and priceErrors == 0 then
  print("ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!")
  log.close()
  os.exit(0)
else
  print("ЕСТЬ ОШИБКИ - смотрите детали выше")
  log.close()
  os.exit(1)
end
