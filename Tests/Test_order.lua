--require"C:\\Users\\Nebelung\\source\\repos\\QuikAssistant\\Order"
package.path = "C:\\Users\\Nebelung\\Documents\\QuikAssistant\\?.lua;"

require("Order")

---------------------
--- Акция МосБиржи
---------------------

local securityCode = "GAZP"
local order = Order:new(securityCode)

local gazp = {
  name = '"Газпром" (ПАО) ао', --Инструмент
  short_name = "ГАЗПРОМ ао", --	Инструмент сокр.
  code = "GAZP", --	Код инструмента
  isin_code = "RU0007661625", --	ISIN
  regnumber = "1-02-00028-A", --	Рег.номер
  class_name = "МБ ФР: Т+ Акции и ДР", --	Класс
  class_code = "TQBR", --	Код класса
  face_value = 5, --	Номинал
  face_unit = "SUR", --	Валюта
  scale = 2, --	Точность
  min_price_step = 0.01, --	Шаг цены
  lot_size = 10, --	Размер лота
}

--- Поиск инструмента
assert(order.SecurityCode == securityCode)
assert(
  order.SecurityInfo.name == gazp.name,
  string.format("Инструмент: %s != %s", order.SecurityInfo.name, gazp.name)
)
assert(
  order.SecurityInfo.short_name == gazp.short_name,
  string.format("Инструмент сокр.: %s != %s", order.SecurityInfo.short_name, gazp.short_name)
)
assert(order.SecurityInfo.code == gazp.code)
assert(order.SecurityInfo.isin_code == gazp.isin_code)
assert(order.SecurityInfo.regnumber == gazp.regnumber)
assert(order.SecurityInfo.class_name == gazp.class_name)
assert(order.SecurityInfo.class_code == gazp.class_code)
assert(order.SecurityInfo.face_value == gazp.face_value)
assert(order.SecurityInfo.face_unit == gazp.face_unit)
assert(order.SecurityInfo.scale == gazp.scale)
assert(order.SecurityInfo.min_price_step == gazp.min_price_step)
assert(order.SecurityInfo.lot_size == gazp.lot_size)

assert(order.Operation == "")
assert(order.Quantity == 0)
assert(order.Price == 0)
assert(order.GetVolume() == 0)
assert(order.IsBond() == false, string.format("Облигация?: %s != %s", tostring(order.IsBond), tostring(false)))
assert(order.IsOFZ() == false)
assert(order.IsSpb() == false)
assert(order.IsBuy() == false)
assert(order.IsSell() == false)

--- Задание параметров заявки
local operation = "B"
local quantity = 100
local price = 250.1

order:SetOperation(operation, price, quantity)

assert(
  order.Operation == operation,
  string.format("Операция: %s != %s", order.SecurityInfo.Operation, operation)
)
assert(order.Quantity == quantity)
assert(order.Price == price)
assert(order:GetVolume() == 250100)
assert(order.IsBuy() == true)
assert(order.IsSell() == false)

---
local quantityMax = 10000
order:SetQuantity(operation, price, quantityMax)
assert(
  order.Operation == operation,
  string.format("Операция: %s != %s", order.SecurityInfo.Operation, operation)
)
assert(
  order.Quantity == 3,
  string.format(
    "Количество выставляемых лотов: %s != %s",
    tostring(order.Quantity),
    tostring(3)
  )
)
assert(order.Price == price)
assert(
  order:GetVolume() == 7503,
  string.format("Объем заявки: %s != %s", tostring(order:GetVolume()), tostring(7503))
)

--- Минимально возможная заявка
order:SetPriceMin(operation)

assert(
  order.Operation == operation,
  string.format("Операция: %s != %s", order.SecurityInfo.Operation, operation)
)
assert(order.Quantity == 1)
assert(order.Price == gazp.min_price_step)
assert(order:GetVolume() == gazp.min_price_step * gazp.lot_size)
assert(order.IsBuy() == true)
assert(order.IsSell() == false)

operation = "S"
order:SetPriceMin(operation)

assert(
  order.Operation == operation,
  string.format("Операция: %s != %s", order.SecurityInfo.Operation, operation)
)
assert(order.Quantity == 0)
assert(order.Price == 0)
assert(order:GetVolume() == 0)
assert(order.IsBuy() == false)
assert(order.IsSell() == true)

---------------------
--- Облигация МосБиржи
---------------------

local bondCode = "RU000A102RN7"
local orderBond = Order:new(bondCode)

local bond = {
  name = "КБ Ренессанс Кредит БО-06", --Инструмент
  short_name = "РенКредБО6", --	Инструмент сокр.
  code = "RU000A102RN7", --	Код инструмента
  isin_code = "RU000A102RN7", --	ISIN
  regnumber = "4B020603354B", --	Рег.номер
  class_name = "МБ ФР: Т+: Корпоративные облигации", --	Класс
  class_code = "TQCB", --	Код класса
  face_value = 1000.00, --	Номинал
  face_unit = "SUR", --	Валюта
  scale = 2, --	Точность
  min_price_step = 0.01, --	Шаг цены
  lot_size = 1, --	Размер лота
}

--- Поиск инструмента
assert(orderBond.SecurityCode == bondCode)
assert(
  orderBond.SecurityInfo.name == bond.name,
  string.format("Инструмент: %s != %s", orderBond.SecurityInfo.name, bond.name)
)
assert(
  orderBond.SecurityInfo.short_name == bond.short_name,
  string.format("Инструмент сокр.: %s != %s", orderBond.SecurityInfo.short_name, bond.short_name)
)
assert(orderBond.SecurityInfo.code == bond.code)
assert(orderBond.SecurityInfo.isin_code == bond.isin_code)
assert(
  orderBond.SecurityInfo.regnumber == bond.regnumber,
  string.format("Рег.номер: %s != %s", orderBond.SecurityInfo.regnumber, bond.regnumber)
)
assert(orderBond.SecurityInfo.class_name == bond.class_name)
assert(orderBond.SecurityInfo.class_code == bond.class_code)
assert(orderBond.SecurityInfo.face_value == bond.face_value)
assert(orderBond.SecurityInfo.face_unit == bond.face_unit)
assert(orderBond.SecurityInfo.scale == bond.scale)
assert(orderBond.SecurityInfo.min_price_step == bond.min_price_step)
assert(orderBond.SecurityInfo.lot_size == bond.lot_size)

assert(orderBond.Operation == "")
assert(orderBond.Quantity == 0)
assert(orderBond.Price == 0)
assert(orderBond:GetVolume() == 0)
assert(
  orderBond.IsBond() == true,
  string.format("Облигация?: %s != %s", tostring(orderBond.IsBond), tostring(true))
)
assert(orderBond.IsOFZ() == false)
assert(orderBond.IsSpb() == false)
assert(orderBond.IsBuy() == false)
assert(orderBond.IsSell() == false)

--- Задание параметров заявки
local operation = "B"
local quantity = 100
local price = 101.5

orderBond:SetOperation(operation, price, quantity)

assert(
  orderBond.Operation == operation,
  string.format("Операция: %s != %s", orderBond.SecurityInfo.Operation, operation)
)
assert(orderBond.Quantity == quantity)

assert(orderBond.Price == price, string.format("Цена: %s != %s", orderBond.Price, price))
assert(orderBond:GetVolume() == 101500)
assert(orderBond.IsBuy() == true)
assert(orderBond.IsSell() == false)

--- Точность цены ниже
local operation = "B"
local quantity = 100
local price = 101.12345

orderBond:SetOperation(operation, price, quantity)

assert(
  orderBond.Operation == operation,
  string.format("Операция: %s != %s", orderBond.SecurityInfo.Operation, operation)
)
assert(orderBond.Quantity == quantity)

assert(orderBond.Price == 101.12, string.format("Цена: %s != %s", orderBond.Price, price))
assert(orderBond:GetVolume() == 101120)
assert(orderBond.IsBuy() == true)
assert(orderBond.IsSell() == false)

--- Минимально возможная заявка
orderBond:SetPriceMin(operation)

assert(
  orderBond.Operation == operation,
  string.format("Операция: %s != %s", orderBond.SecurityInfo.Operation, operation)
)
assert(orderBond.Quantity == 1)
assert(orderBond.Price == bond.min_price_step)
assert(orderBond:GetVolume() == bond.min_price_step * 10)
assert(orderBond.IsBuy() == true)
assert(orderBond.IsSell() == false)

operation = "S"
orderBond:SetPriceMin(operation)

assert(
  orderBond.Operation == operation,
  string.format("Операция: %s != %s", orderBond.SecurityInfo.Operation, operation)
)
assert(orderBond.Quantity == 0)
assert(orderBond.Price == 0)
assert(orderBond:GetVolume() == 0)
assert(orderBond.IsBuy() == false)
assert(orderBond.IsSell() == true)

---------------------
--- Иностранные акции С-П биржа
---------------------

local spbCode = "ADBE_SPB"
local orderSpb = Order:new(spbCode)

local adobe = {
  name = "Adobe Inc.", --Инструмент
  short_name = "Adobe Inc.", --	Инструмент сокр.
  code = "ADBE_SPB", --	Код инструмента
  isin_code = "US00724F1012", --	ISIN
  regnumber = "", --	Рег.номер
  class_name = "SPB: Акции", --	Класс
  class_code = "SPBXM", --	Код класса
  face_value = 0.0001, --	Номинал
  face_unit = "USD", --	Валюта
  scale = 2, --	Точность
  min_price_step = 0.01, --	Шаг цены
  lot_size = 1, --	Размер лота
}

--- Поиск инструмента
assert(orderSpb.SecurityCode == spbCode)
assert(
  orderSpb.SecurityInfo.name == adobe.name,
  string.format("Инструмент: %s != %s", orderSpb.SecurityInfo.name, adobe.name)
)
assert(
  orderSpb.SecurityInfo.short_name == adobe.short_name,
  string.format("Инструмент сокр.: %s != %s", orderSpb.SecurityInfo.short_name, adobe.short_name)
)
assert(orderSpb.SecurityInfo.code == adobe.code)
assert(orderSpb.SecurityInfo.isin_code == adobe.isin_code)
assert(orderSpb.SecurityInfo.regnumber == adobe.regnumber)
assert(orderSpb.SecurityInfo.class_name == adobe.class_name)
assert(orderSpb.SecurityInfo.class_code == adobe.class_code)
assert(orderSpb.SecurityInfo.face_value == adobe.face_value)
assert(orderSpb.SecurityInfo.face_unit == adobe.face_unit)
assert(orderSpb.SecurityInfo.scale == adobe.scale)
assert(orderSpb.SecurityInfo.min_price_step == adobe.min_price_step)
assert(orderSpb.SecurityInfo.lot_size == adobe.lot_size)

assert(orderSpb.Operation == "")
assert(orderSpb.Quantity == 0)
assert(orderSpb.Price == 0)
assert(orderSpb:GetVolume() == 0)
assert(
  orderSpb.IsBond() == false,
  string.format("Облигация?: %s != %s", tostring(orderSpb.IsBond), tostring(false))
)
assert(orderSpb.IsOFZ() == false)
assert(orderSpb.IsSpb() == true)
assert(orderSpb.IsBuy() == false)
assert(orderSpb.IsSell() == false)

--- Задание параметров заявки
local operation = "B"
local quantity = 100
local price = 500.1

orderSpb:SetOperation(operation, price, quantity)

assert(
  orderSpb.Operation == operation,
  string.format("Операция: %s != %s", orderSpb.SecurityInfo.Operation, operation)
)
assert(orderSpb.Quantity == quantity)
assert(orderSpb.Price == price)
assert(orderSpb:GetVolume() == 50010)
assert(orderSpb.IsBuy() == true)
assert(orderSpb.IsSell() == false)

---
local quantityMax = 10000
orderSpb:SetQuantity(operation, price, quantityMax)
assert(
  orderSpb.Operation == operation,
  string.format("Операция: %s != %s", orderSpb.SecurityInfo.Operation, operation)
)
assert(
  orderSpb.Quantity == 19,
  string.format(
    "Количество выставляемых лотов: %s != %s",
    tostring(orderSpb.Quantity),
    tostring(19)
  )
)
assert(orderSpb.Price == price)
assert(
  orderSpb:GetVolume() == 9501.90,
  string.format("Объем заявки: %s != %s", tostring(orderSpb:GetVolume()), tostring(9501.90))
)

--- Минимально возможная заявка
orderSpb:SetPriceMin(operation)

assert(
  orderSpb.Operation == operation,
  string.format("Операция: %s != %s", orderSpb.SecurityInfo.Operation, operation)
)
assert(orderSpb.Quantity == 1)
assert(orderSpb.Price == adobe.min_price_step)
assert(orderSpb:GetVolume() == adobe.min_price_step * adobe.lot_size)
assert(orderSpb.IsBuy() == true)
assert(orderSpb.IsSell() == false)

operation = "S"
orderSpb:SetPriceMin(operation)

assert(
  orderSpb.Operation == operation,
  string.format("Операция: %s != %s", orderSpb.SecurityInfo.Operation, operation)
)
assert(orderSpb.Quantity == 0)
assert(orderSpb.Price == 0)
assert(orderSpb:GetVolume() == 0)
assert(orderSpb.IsBuy() == false)
assert(orderSpb.IsSell() == true)

message("Test Order: OK")
