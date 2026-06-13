function GetParamInfo(order, param)
  local value = getParamEx(order.SecurityInfo.class_code, order.SecurityInfo.code, param)
  if value == nil or value.result == "0" then
    log.error(
      "�������� �� ������.",
      param,
      order.Print()
    )
    return "0"
  end
  return value.param_value
end

--- ��������� ��������� ����
function GetPriceLast(order)
  local priceLast = GetParamInfo(order, "LAST")
  if tonumber(priceLast) == 0 then
    priceLast = GetPricePrev(order)
  end
  return priceLast
end

--- ��������� ����������� ����
function GetPriceMin(order)
  local priceMin = GetParamInfo(order, "PRICEMIN")
  return priceMin
end

--- ��������� ������������ ����
function GetPriceMax(order)
  local priceMax = GetParamInfo(order, "PRICEMAX")
  return priceMax
end

---����������
function GetPricePrev(order)
  local pricePrev = GetParamInfo(order, "PREVPRICE")
  return pricePrev
end

-- �������������� ������������� ������� ������, ���� ������ �� ������������ � ������������
function GetKoeffVolumeOrderMax(order, priceMin)
  local priceLast = GetPriceLast(order)
  if tonumber(priceMin) == nil or tonumber(priceMin) == 0 or tonumber(priceLast) == nil then
    return 1
  end
  local koeff = (tonumber(priceLast) - tonumber(priceMin)) / tonumber(priceMin) * 10
  if koeff ~= nil and tonumber(koeff) > 1 then
    return koeff
  end
  return 1
end

-- ������ ������� ������
--- �������������� ����������� ������������� ������� ������ �� ������ �� ����������.
--- ��� ��������� �������� BondVolumeOrderMax ���������� �� �����������.
--- ��� ����������� ����� � SPB - ������������ ������ � ��������.
function GetOrderVolumeMax(order, priceMin)
  local koeff = GetKoeffVolumeOrderMax(order, priceMin)
  local limit = VolumeOrderMax

  if order:IsBond() then
    limit = BondVolumeOrderMax * tonumber(koeff)
  elseif order:IsUsd() then
    limit = VolumeOrderLimitUSD
  elseif order:IsForeign() then
    limit = VolumeOrderLimitForeign
  end

  -- ����������� �� ������
  if limit > VolumeOrderLimit then
    limit = VolumeOrderLimit
  end

  return limit
end

function GetOperation(flags)
  if (flags & FLAG_SELL) > 0 then
    return "S"
  else
    return "B"
  end
end

--- �������� �� ������� �� ����� �� ����� ��� ����������
function IsOrderExecuted(flags)
  return (flags & FLAG_ACTIVE) == 0 and (flags & FLAG_EXECUTED) == 0
end

--�������� �� ���������� ������
function FindOrder(flags, sec_code, class_code)
  if (flags & FLAG_ACTIVE) > 0 or IsOrderExecuted(flags) then
    return true
  else
    return false
  end
end

--- ����� � QUIK ��� �������� ������� ����������� ��� ��������� ����������
function GetQuikOrders()
  local countOrders = getNumberOf("orders")

  log.debug(
    string.format(
      "���������� �������: %d ��.",
      countOrders
    )
  )
  local ok, orders = pcall(function()
    return SearchItems("orders", 0, countOrders - 1, FindOrder, "flags, sec_code, class_code")
  end)
  if ok and orders ~= nil then
    for i = 1, #orders do
      local ok2, order = pcall(function()
        return getItem("orders", orders[i])
      end)
      if ok2 and order then
        OnOrder(order)
      end
    end
  end
end

-- �������� ���������� �� �������� ����� � QUIK �� ���������� �� ������, ����������� �� ���� ���������� ��������� ������
function IsOrderExists(newOrder)
  local countOrders = getNumberOf("orders")

  local ok, orders = pcall(function()
    return SearchItems("orders", 0, countOrders - 1, FindOrder, "flags, sec_code, class_code")
  end)
  if ok and orders ~= nil then
    for i = 1, #orders do
      local ok2, order = pcall(function()
        return getItem("orders", orders[i])
      end)
      if ok2 and order then
        local operation
        if (order.flags & FLAG_SELL) > 0 then
          operation = "S"
        else
          operation = "B"
        end

        if
          order.sec_code == newOrder.SecurityCode
          and operation == newOrder.Operation
          and string.format("%." .. newOrder.SecurityInfo.scale .. "f", tonumber(order.price)) == string.format(
            "%." .. newOrder.SecurityInfo.scale .. "f",
            tonumber(newOrder.Price)
          )
          and ((order.flags & FLAG_ACTIVE) > 0 or IsOrderExecuted(order.flags))
        then
          return true
        end
      end
    end
  end

  return false
end

function FindPosition(limit_kind, currentbal)
  if limit_kind == 2 and tonumber(currentbal) ~= 0 then
    return true
  end
  return false
end

--- ==========================================
--- ��� �������: securityCode -> position
--- ==========================================
local positionCache = {}

--- ������� ���� ������� (���������� ��� �����������)
function ClearPositionCache()
  positionCache = {}
end

--- ��������� ������� �� ������ �� depo_limits.
function GetPosition(securityCode)
  -- �������� ����
  if positionCache[securityCode] then
    return positionCache[securityCode]
  end

  local countPositions = getNumberOf("depo_limits")

  local ok, positions = pcall(function()
    return SearchItems("depo_limits", 0, countPositions - 1, FindPosition, "limit_kind, currentbal")
  end)
  if ok and positions ~= nil then
    for i = 1, #positions do
      local ok2, position = pcall(function()
        return getItem("depo_limits", positions[i])
      end)
      if ok2 and position and position.sec_code == securityCode then
        log.debug(
          "������� �������. ",
          securityCode
        )
        log.trace(json.encode(position))
        positionCache[securityCode] = position
        return position
      end
    end
  end

  return nil
end

local volumeWarnedTickers = {}

function ClearVolumeWarnedTickers()
  volumeWarnedTickers = {}
end

--- ������������� ���� ������ � ������������ � ������� �����
--- �������������� ������������� ��� ��� ��������� ���������� ������
--- �������� ������ ��� ������� (���� ������� ���� ������� ����)
function AdjustPrice(order)
  if order == nil or order.Price == nil or order.Operation == nil then
    return
  end

  if order.UseFileParams then
    return
  end

  local priceLast = GetPriceLast(order)

  if order:IsBuy() then
    if tonumber(priceLast) < tonumber(order.Price) and tonumber(priceLast) ~= 0 then
      order.Price = priceLast - PRICE_DEVIATION_MULTIPLIER * order.SecurityInfo.min_price_step
    end
    local priceMin = tonumber(GetPriceMin(order))
    if priceMin ~= nil and priceMin > 0 and tonumber(order.Price) < priceMin then
      order.Price = priceMin
      order:GetPriceRound()
    end
  end

  if order:IsSell() then
    if tonumber(priceLast) > tonumber(order.Price) and tonumber(priceLast) ~= 0 then
      order.Price = priceLast + PRICE_DEVIATION_MULTIPLIER * order.SecurityInfo.min_price_step
    end
  end
end

--- @return boolean, string ��������� (true/false), ������� ������ ("" ���� ���)
function CheckOrder(order)
  -- �������� ������������ ����������
  if
    order == nil
    or order.Price == nil
    or order.Quantity == nil
    or order.Operation == nil
    or tonumber(order.Price) <= 0
    or tonumber(order.Quantity) <= 0
    or order.Operation == ""
  then
    log.error(
      "������������ ��������� ������.",
      order and order.Print() or "nil"
    )
    return false, "������������ ��������� ������"
  end

  local priceLast = GetPriceLast(order)

  -- �������� �� ������� �� ����� ���� ������� ���� (�������)
  if order:IsBuy() then
    if tonumber(priceLast) < tonumber(order.Price) and tonumber(priceLast) ~= 0 then
      log.debug(
        "���� ������� ������ ���� ������� ����. ����������� ���� "
          .. tostring(priceLast)
          .. " ������������ ��� ��������� ���������� ������. "
          .. order.Print()
      )
      order.Price = priceLast - PRICE_DEVIATION_MULTIPLIER * order.SecurityInfo.min_price_step
    end
    local priceMin = tonumber(GetPriceMin(order))
    if priceMin ~= nil and priceMin > 0 and tonumber(order.Price) < priceMin then
      local reason = string.format(
        "price %s below PRICEMIN %s",
        tostring(order.Price),
        tostring(priceMin)
      )
      log.warn(reason .. " " .. order.Print())
      return false, reason
    end
  end

  -- �������� �� ������� �� ����� ���� ������� ���� (�������)
  if order:IsSell() then
    if tonumber(priceLast) > tonumber(order.Price) and tonumber(priceLast) ~= 0 then
      log.debug(
        "���� ������� ������ ���� ������� ����. ����������� ���� "
          .. tostring(priceLast)
          .. " ������������ ��� ��������� ���������� ������. "
          .. order.Print()
      )
      order.Price = priceLast + PRICE_DEVIATION_MULTIPLIER * order.SecurityInfo.min_price_step
    end
  end

  --- �������� ������� ����������� ������� ��� �������
  if order:IsSell() then
    local position = GetPosition(order.SecurityCode)
    if position == nil or tonumber(position.currentbal) < tonumber(order.Quantity) then
      local reason = string.format(
        "insufficient position for sell (have: %s, need: %s)",
        tostring(position and position.currentbal or 0),
        tostring(order.Quantity)
      )
      return false, reason
    end
  end

  --- �������� �� ���������� ������������� ������ ������ ��� �������
  if order:IsBuy() then
    local limit = VolumeOrderLimit
    if order:IsSpb() then
      limit = VolumeOrderLimitUSD
    end
    if order:IsUsd() then
      limit = VolumeOrderLimitUSD
    end
    if order:GetVolume() > limit then
      local reason = string.format(
        "volume %s %s exceeds limit %s",
        tostring(order:GetVolume()),
        order.SecurityInfo.face_unit,
        tostring(limit)
      )
      order:Clear()
      return false, reason
    end
  end

  --- �������� �� ���������� ������������� ���������� ���� �� ����� ��� �������
  if order:IsBuy() then
    if order:IsExceptionFromLimitActuation() then
      return true, ""
    end

    local actuation = (tonumber(priceLast) - tonumber(order.Price)) / tonumber(order.Price) * 100
    local limit = LimitActuationOrderEdge
    if order:IsBond() and not order:IsOFZ() then
      limit = LimitActuationOrderBondEdge
    elseif order:IsForeign() then
      limit = LimitActuationOrderForeignEdge
    end

    if actuation ~= nil and tonumber(actuation) < tonumber(limit) then
      local reason = string.format("actuation %.2f%% below limit %s%%", actuation, tostring(limit))
      return false, reason
    end
  end

  -- �������� �� ���� �� ���� ��������� �������� (100%)
  if order:IsBuy() then
    if order:IsBond() then
      local nominal = 100.0
      if tonumber(order.Price) > tonumber(nominal) then
        local reason = string.format(
          "���� ������� ��������� ���� �������� 100%% (����: %s%%)",
          tostring(order.Price)
        )
        log.warn(reason .. " " .. order.Print())
        return false, reason
      end
    end
  end

  --- �������� �� ���� �� ���� ������� ����� ��� �������
  if order:IsBuy() and not order:IsBond() then
    local position = GetPosition(order.SecurityCode)
    if position ~= nil and tonumber(position.wa_position_price) < tonumber(order.Price) then
      local reason = string.format(
        "���� ������� ���� ������� ���� ����� %s",
        string.format("%.2f", position.wa_position_price)
      )
      log.warn(reason .. " " .. order.Print())
      return false, reason
    end
  end

  return true, ""
end

function SetLimitOrdersWithError(trans)
  -- ������: (579) ���� �� ����� ���� ������ ���������� ���������� ����
  local error579 = string.find(trans.result_msg, ": (" .. ERR_PRICE_TOO_LOW .. ")", 1, true)
  if error579 ~= nil then
    log.warn(
      "������ (579) ��� " .. trans.sec_code
        .. " (qty=" .. tostring(trans.quantity) .. ", price=" .. tostring(trans.price) .. "): "
        .. trans.result_msg
    )
    return
  end

  -- ������: (580) ���� �� ����� ���� ������ ������������ ���������� ����
  local error580 = string.find(trans.result_msg, ": (" .. ERR_PRICE_TOO_HIGH .. ")", 1, true)
  if error580 ~= nil then
    local maxPrice = string.match(trans.result_msg, "�� ������ (%d+%.?%d*)")
    if maxPrice == nil then
      maxPrice = string.match(trans.result_msg, "%d+[%.]?%d+")
    end
    local operation = "S"
    local order = Order:new(trans.sec_code)
    if order == nil then
      log.error("�� ������� ������� ���������� ��� ������������� ������", trans.sec_code)
      return
    end
    order:SetOperation(operation, maxPrice, trans.quantity)
    log.info("�������������� ����� �� ������� ������ �� ������������ ����: " .. order.Print())
    local orders = {}
    table.insert(orders, order)
    SubmitOrders(orders)
    return
  end

  -- ������: ���� ������ �� �������� � ���������� ��������
  local errorTest = string.find(trans.result_msg, "�� �������� � ���������� �������� ���������� ��� ��", 1, true)
  if errorTest ~= nil then
    local minPrice = string.match(trans.result_msg, "�� (%d+%.?%d*)")
    if minPrice == nil then
      minPrice = string.match(trans.result_msg, "%d+[%.]?%d+")
    end
    local operation = "B"
    local order = Order:new(trans.sec_code)
    if order == nil then
      log.error("�� ������� ������� ���������� ��� ������������� ������", trans.sec_code)
      return
    end
    order:SetOperation(operation, minPrice, 0)
    log.info("�������������� ����� ������ �� ����������� ����: " .. order.Print())
    return
  end

  -- ������: (133) ������ �� ����� ���� ��������� �� ��������� ����������
  local error133 = string.find(trans.result_msg, ": (" .. ERR_EXECUTION_REJECTED .. ")", 1, true)
  if error133 ~= nil then
    log.warn("������ (133) ��� " .. trans.sec_code
      .. " (qty=" .. tostring(trans.quantity) .. ", price=" .. tostring(trans.price) .. "): "
      .. trans.result_msg)
    return
  end

  log.error(string.format("����������� ������ ����������. %s", trans.result_msg))
  log.error(json.encode(trans))
end