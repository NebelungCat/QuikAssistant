Order = {}

math.round = function(num, idp)
  if num == nil then
    return nil
  end
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- ==========================================
-- Кэш информации о инструментах
-- ==========================================
local securityInfoCache = {}

function ClearSecurityInfoCache()
  securityInfoCache = {}
end

--- Получение информации об инструменте по коду бумаги
function GetSecurityInfo(securityCode)
  if securityInfoCache[securityCode] then
    return securityInfoCache[securityCode]
  end
  for classCode in string.gmatch("TQCB,TQBR,SPBXM,EQOB,TQIR,TQRD,TQOB,FQBR,TQTF,TQPI,MTQR,", "(%P*),") do
    local SecurityInfo = getSecurityInfo(classCode, securityCode)
    if SecurityInfo ~= nil then
      securityInfoCache[securityCode] = SecurityInfo
      return SecurityInfo
    end
  end
  log.error(
    "Инструмент не найден: "
      .. securityCode
  )
  return nil
end

--- Получение информации об инструменте в валюте (USD)
function GetUsdSecurityInfo(securityCode)
  local cacheKey = securityCode .. "_USD"
  if securityInfoCache[cacheKey] then
    return securityInfoCache[cacheKey]
  end
  for classCode in string.gmatch("TQCB,TQBD,TQBR,SPBXM,EQOB,TQIR,TQRD,TQOB,TQTF,TQPI,MTQR,", "(%P*),") do
    local SecurityInfo = getSecurityInfo(classCode, securityCode)
    if SecurityInfo ~= nil then
      securityInfoCache[cacheKey] = SecurityInfo
      return SecurityInfo
    end
  end
  log.error(
    "Инструмент не найден (USD): "
      .. securityCode
  )
  return nil
end

--- Создание заявки
function Order:new(securityCode)
  local obj = {}

  if Broker == "VTB" then
    obj.SecurityInfo = GetUsdSecurityInfo(securityCode)
  else
    obj.SecurityInfo = GetSecurityInfo(securityCode)
  end

  obj.SecurityCode = securityCode
  obj.Operation = ""
  obj.Quantity = 0
  obj.Price = 0
  obj.UseFileParams = false

  if obj.SecurityInfo == nil then
    return nil
  end

  -- Проверка на вхождение в список бумаг с исключением по проскальзыванию
  function obj:IsExceptionFromLimitActuation()
    for secCode in
      string.gmatch(
        "ENPG,RTKM,MTSS,NKNCP,UPRO,MGTSP,IRAO,MAGN,TGKA,GAZP,AFLT,ELFV,SMLT,SNGS,ALRS,MGNT,HYDR,VTBR,FEES,MVID,SGZH,AQUA,STSB,IVAT,UPRO,VKCO,",
        "(%P*),"
      )
    do
      if obj.SecurityCode == secCode then
        return true
      end
    end
    return false
  end

  --- Проверка, является ли инструмент облигацией
  function obj:IsBond()
    for classCode in string.gmatch("TQCB,EQOB,TQIR,TQRD,TQOB,", "(%P*),") do
      if obj.SecurityInfo.class_code == classCode then
        return true
      end
    end
    return false
  end

  --- Проверка, является ли инструмент ОФЗ
  function obj:IsOFZ()
    if obj.SecurityInfo.class_code == "TQOB" then
      return true
    end
    return false
  end

  --- Проверка, является ли инструмент ETF
  function obj:IsEtf()
    if obj.SecurityInfo.class_code == "TQTF" then
      return true
    end
    return false
  end

  --- Проверка, является ли инструмент иностранной бумагой на СПБ
  function obj:IsSpb()
    if obj.SecurityInfo.class_code == "SPBXM" then
      return true
    end
    return false
  end

  --- Проверка, является ли инструмент иностранной
  function obj:IsForeign()
    if
      obj.SecurityInfo.class_code == "SPBXM"
      or obj.SecurityInfo.class_code == "FQBR"
      or obj.SecurityInfo.class_code == "TQBD"
    then
      return true
    end
    return false
  end

  --- Проверка, является ли инструмент в долларах
  function obj:IsUsd()
    if obj.SecurityInfo.class_code == "SPBXM" or obj.SecurityInfo.class_code == "TQBD" then
      return true
    end
    return false
  end

  --- Проверка, является ли операцией покупки
  function obj:IsBuy()
    if obj.Operation ~= nil and obj.Operation == "B" then
      return true
    end
    return false
  end

  --- Проверка, является ли операцией продажи
  function obj:IsSell()
    if obj.Operation ~= nil and obj.Operation == "S" then
      return true
    end
    return false
  end

  --- Очистка параметров заявки
  function obj:Clear()
    obj.Operation = ""
    obj.Quantity = 0
    obj.Price = 0
  end

  --- Форматирование цены в строку
  function obj:FormatPrice()
    return string.format("%." .. obj.SecurityInfo.scale .. "f", tonumber(obj.Price))
  end

  function obj:FormatQuantity(n)
    local n = (n or 0)
    return string.format("%." .. n .. "f", obj.Quantity)
  end

  function obj:GetDedupKey()
    return obj.SecurityInfo.code .. " " .. obj.Operation .. " " .. obj:FormatQuantity() .. " " .. obj:FormatPrice()
  end

  function obj:GetPriceInCurrency(price)
    if obj:IsBond() then
      local nominal = obj.SecurityInfo.face_value
      return tonumber(price) * tonumber(nominal) / 100
    else
      return tonumber(price)
    end
  end

  function obj:SetOperation(operation, price, quantity)
    obj.Operation = operation
    obj.Quantity = quantity
    obj.Price = price
    obj:GetPriceRound()

    if price == 0 then
      if obj.SecurityInfo.min_price_step <= 0.0001 then
        obj.Price = 0.0001
      else
        obj.Price = obj.SecurityInfo.min_price_step
      end
    end
  end

  function obj:SetPriceMin(operation)
    obj.Operation = operation
    if obj:IsBuy() then
      obj.Quantity = 1
      obj.Price = obj.SecurityInfo.min_price_step
    else
      obj.Quantity = 0
      obj.Price = 0
    end
  end

  function obj:SetQuantity(operation, price, quantityMax)
    obj.Operation = operation
    if price ~= nil and tonumber(price) > 0 and quantityMax ~= nil and tonumber(quantityMax) > 0 and obj:IsBuy() then
      obj.Price = tonumber(price)
      obj:GetPriceRound()

      if obj:IsBond() then
        local priceRub = obj:GetPriceInCurrency(price)
        obj.Quantity = math.floor(tonumber(quantityMax) / tonumber(priceRub) / tonumber(obj.SecurityInfo.lot_size))
      else
        obj.Quantity = math.floor(tonumber(quantityMax) / tonumber(obj.Price) / tonumber(obj.SecurityInfo.lot_size))
      end

      if obj.Quantity <= 0 then
        obj.Quantity = 1
      end
    else
      obj.Quantity = 0
    end
  end

  function obj:GetVolume()
    local priceInCurrency = 0
    if obj:IsBond() then
      priceInCurrency = obj:GetPriceInCurrency(obj.Price)
    else
      priceInCurrency = obj.Price
    end
    return tonumber(obj.Quantity) * tonumber(priceInCurrency) * tonumber(obj.SecurityInfo.lot_size)
  end

  function obj:GetPriceRound()
    local price = math.round(obj.Price, obj.SecurityInfo.scale)

    if price == nil then
      price = 0
    end

    if obj:IsBuy() then
      price = math.ceil(price / obj.SecurityInfo.min_price_step) * obj.SecurityInfo.min_price_step
    elseif obj:IsSell() then
      price = math.floor(price / obj.SecurityInfo.min_price_step) * obj.SecurityInfo.min_price_step
    else
      price = 0
    end
    obj.Price = price
  end

  function obj:Print()
    return string.format(
      "[Инструмент: %s; код: %s; код класса: %s; операция: %s; цена: %f; количество: %f; объём: %f;]",
      obj.SecurityInfo.name,
      obj.SecurityCode,
      obj.SecurityInfo.class_code,
      obj.Operation,
      obj.Price,
      obj.Quantity,
      obj:GetVolume()
    )
  end

  setmetatable(obj, self)
  obj.__index = self
  return obj
end
