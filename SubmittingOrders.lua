require("Setting")
require("FileFunction")
require("Order")
require("QuikFunction")
require("TableOrders")

--- ����� ������ �������� ������
TimeMainStart = nil

--- ����� ������ �������� ������
TimeMorningStart = nil

--- ����� ������ �������� ������
TimeEveningStart = nil

--- ����, ��� ������ ��� ����������
IsSentOrders = false

--- ����, ��� ������ ��� �������� ������� �� �����
IsSendingOrders = false

--- ������� ����� ������
IsMorningTime = false

--- ������� ����� ������
IsMainTime = false

--- ������� ����� ������
IsEveningTime = false

-- ��������� ��� ������������ ������� (��� ������������)
-- ����: "SECURITY_CODE OPERATION", ��������: true
sendOrders = {}
sendOrdersSet = {}

-- ������� ������
local cycleCount = 0

-- ���������� �������, ����������� ���� QUIK
unknownSecurities = {}


--- ������������� ���������� �������
function Initialization()
  SetClientSetting()

  TimeMainStart = os.date("!*t", os.time())
  TimeMainStart.hour = 10
  TimeMainStart.min = 0
  TimeMainStart.sec = 30

  TimeMorningStart = os.date("!*t", os.time())
  TimeMorningStart.hour = 7
  TimeMorningStart.min = 0
  TimeMorningStart.sec = 30

  TimeEveningStart = os.date("!*t", os.time())
  TimeEveningStart.hour = 19
  TimeEveningStart.min = 2
  TimeEveningStart.sec = 10

  IsSentOrders = false
  IsSendingOrders = false
  IsMorningTime = false
  IsMainTime = false
  IsEveningTime = false
end



--- ��������� ������� ����� � ��������� ��������.
function SubmittingOrders()
  local timeCurrent = os.time()

  if (os.time(TimeMorningStart) < timeCurrent) and not IsMorningTime then
    if IsSentOrders then
      N_CloseAllOrder()
    end
    IsMorningTime = true
    IsSentOrders = false
  end

  if (os.time(TimeMainStart) < timeCurrent) and not IsMainTime then
    if IsSentOrders then
      N_CloseAllOrder()
    end
    IsMainTime = true
    IsSentOrders = false
  end

  if (os.time(TimeEveningStart) < timeCurrent) and not IsEveningTime then
    if IsSentOrders then
      N_CloseAllOrder()
    end
    IsEveningTime = true
    IsSentOrders = false
  end

  if not IsSentOrders then
    if (os.time(TimeMorningStart) < timeCurrent) then
      log.debug("������ ����� �������� �������.")
      SubmittingOrdersRun()
    end
  end
end

--- ���� �������� ������� �� �����.
function SubmittingOrdersRun()

  if (IsSendingOrders) then
    return
  end

  local isSubmittingOrdersRun = true

  if IsMorningTime and not IsMainTime and not IsEveningTime then
    isSubmittingOrdersRun = false
  end

  if IsMorningTime and IsMainTime and IsEveningTime then
    isSubmittingOrdersRun = false
  end

  IsSendingOrders = true
  cycleCount = cycleCount + 1

  local function ensureSendingReset()
    IsSendingOrders = false
  end

  local ok, err = pcall(function()
    local stats = { loaded = 0, sent = 0, rejected = 0, duplicate = 0 }
    unknownSecurities = {}

    log.info(string.format("=== ���� %d ������� ===", cycleCount))

    if isSubmittingOrdersRun then
      log.debug(string.format("2.1 �������� ������ �� ������� �� ����� %s", FileBuyOrder))
      local orders = LoadOrdersFromFile(FileBuyOrder)
      stats.loaded = stats.loaded + #orders
      local s = SubmitOrders(orders)
      stats.sent = stats.sent + s.sent
      stats.rejected = stats.rejected + s.rejected
      stats.duplicate = stats.duplicate + s.duplicate
      sleep(3000)
    end

    if isSubmittingOrdersRun then
      log.debug(string.format("2.2 �������� ������ �� ������� ��������� edge %s", FileBuyOrderBondsEdge))
      local orders = LoadOrdersFromFile(FileBuyOrderBondsEdge)
      stats.loaded = stats.loaded + #orders
      local s = SubmitOrders(orders)
      stats.sent = stats.sent + s.sent
      stats.rejected = stats.rejected + s.rejected
      stats.duplicate = stats.duplicate + s.duplicate
      sleep(3000)
    end

    if isSubmittingOrdersRun then
      local orders = LoadOrdersFromFile(FileBuyOrderEdge)
      log.debug(string.format("2.3 �������� ������ �� ������� �� ����� edge %s", FileBuyOrderEdge))
      stats.loaded = stats.loaded + #orders
      local s = SubmitOrders(orders)
      stats.sent = stats.sent + s.sent
      stats.rejected = stats.rejected + s.rejected
      stats.duplicate = stats.duplicate + s.duplicate
      sleep(1000)
    end

    log.debug(string.format("2.7 �������� ������ �� ������� �� ����� %s", FileSellOrder))
    local orders = LoadOrdersFromFile(FileSellOrder)
    stats.loaded = stats.loaded + #orders
    local s = SubmitOrders(orders)
    stats.sent = stats.sent + s.sent
    stats.rejected = stats.rejected + s.rejected
    stats.duplicate = stats.duplicate + s.duplicate

    log.info(string.format("=== ���� %d ��������: ���������=%d, ����������=%d, ���������=%d, ����������=%d ===",
      cycleCount, stats.loaded, stats.sent, stats.rejected, stats.duplicate))

    local unknownCount = 0
    for _ in pairs(unknownSecurities) do unknownCount = unknownCount + 1 end
    if unknownCount > 0 then
      log.warn(string.format("=== ������� %d ������, ���������� ���� QUIK (������� ���������):", unknownCount))
      for code, name in pairs(unknownSecurities) do
        log.warn(string.format("  %s (%s)", code, name))
      end
      log.warn("=== ���� ������� ���� =====")
    end
  end)

  ensureSendingReset()

  if not ok then
    log.error("������ � ����� ��������: " .. tostring(err))
  end

  IsSentOrders = true

  for k in pairs (sendOrders) do
    sendOrders[k] = nil
  end
  sendOrdersSet = {}

end

--- �������� ������ �� �����.
function LoadOrdersFromFile(fileName)
  local orders = {}
  local rows = getFromCSV(fileName)
  local isEdge = fileName:find("_Edge")
  local isFileSpb = fileName:find("_BuyOrdersSpb_Edge")
  local isRmUsd = fileName:find("_BuyOrders_RmUSD_Edge")

  for i, row in ipairs(rows) do
    local securityName = row[1]
    local isComment = string.find(securityName, "--", 1, true)
    if (isComment == nil) then
      local operation = row[2]
      local securityCode = row[3]
      local quantity = tonumber(row[4])
      local price = tonumber(row[5])

      if securityCode == nil or operation == nil then
        log.error("������������ ������ � CSV:", json.encode(row))
      else
        local order = Order:new(securityCode)
        if (order == nil) then
          log.error("�� ������� ������� ����� " .. json.encode(row))
          unknownSecurities[securityCode] = securityName
        else
          if isRmUsd ~= nil then
            local priceMin = GetPricePrev(order) / 4
            order:SetQuantity(operation, priceMin, VolumeOrderLimitUSD)
          elseif isFileSpb ~= nil then
            local priceMin = GetPriceMin(order)
            if tonumber(priceMin) == nil or tonumber(priceMin) == 0 then
              priceMin = GetPricePrev(order)
            end
            local progressOrderVolumeMax = GetOrderVolumeMax(order, priceMin)
            order:SetQuantity(operation, priceMin, progressOrderVolumeMax)
          elseif isEdge ~= nil then
            local priceMin = GetPriceMin(order)
            if tonumber(priceMin) == nil or tonumber(priceMin) == 0 then
              log.warn("не удалось получить мин. цен. для инстр., пропуск. " .. order:Print())
            else
              local progressOrderVolumeMax = GetOrderVolumeMax(order, priceMin)
              order:SetQuantity(operation, priceMin, progressOrderVolumeMax)
            end
          else
            if quantity ~= nil and price ~= nil then
              order:SetOperation(operation, price, quantity)
              order.UseFileParams = true
            else
              log.error("������������ ������ ��� ������ � CSV:", json.encode(row))
            end
          end
          if order.Quantity > 0 then
            table.insert(orders, order)
          end
        end
      end
    end
  end

  return orders
end

--- �������� ������� �� �����
--- @return table { sent = N, rejected = N, duplicate = N }
function SubmitOrders(orders)
  local stats = { sent = 0, rejected = 0, duplicate = 0 }
  local skipReasons = {}

  for i, order in pairs(orders) do
    AdjustPrice(order)
    if IsOrderExists(order) then
      stats.duplicate = stats.duplicate + 1
    elseif IsSendOrder(order) then
      stats.duplicate = stats.duplicate + 1
    else
      local isCheck, rejectReason = CheckOrder(order)
      if not isCheck then
        stats.rejected = stats.rejected + 1
        local key = rejectReason or "unknown"
        skipReasons[key] = (skipReasons[key] or 0) + 1
      else
      local clientAccountCode = AccountCode
      if order:IsSpb() then
        clientAccountCode = AccountCodeSpb
      end

      local trans_id, error =
        N_SetLimitOrder(
        clientAccountCode,
        ClientCode,
        order.SecurityInfo.class_code,
        order.SecurityInfo.code,
        order.Operation,
        order:FormatPrice(),
        order:FormatQuantity()
      )
      if error ~= "" then
        stats.rejected = stats.rejected + 1
        log.error("�� ������� ��������� ����� �� �����: ", error, order.Print())
      else
        stats.sent = stats.sent + 1
        log.info(string.format("  [SEND] %s %s %s qty=%s price=%s",
          order.Operation, order.SecurityCode, order.SecurityInfo.class_code,
          order:FormatQuantity(), order:FormatPrice()))
        local logOrder = {}
        logOrder.SecurityCode = order.SecurityInfo.code
        logOrder.Operation = order.Operation
        logOrder.Quantity = order:FormatQuantity()
        logOrder.Price = order:FormatPrice()
        table.insert(sendOrders, logOrder)
        sendOrdersSet[order:GetDedupKey()] = true
      end
      end
    end
  end

  if stats.duplicate > 0 then
    log.debug(string.format("  [SKIP] %d orders: already in QUIK or sent this session", stats.duplicate))
  end
  for reason, count in pairs(skipReasons) do
    log.warn(string.format("  [SKIP] %d orders: %s", count, reason))
  end

  return stats
end


--- �������� �� ��� ������������
function IsSendOrder(order)
  return sendOrdersSet[order:GetDedupKey()] == true
end

--- �������� ������ �� �������� ������� ��� ������
function TradeClosePosition(trade)
  local orders = {}
  local operation = "S"
  local securityCode = trade.seccode
  local quantity = tonumber(trade.qty)
  local price = tonumber(trade.price)
  local order = Order:new(securityCode)

  log.info("�������� ����� �� �������� ������� �� ������ ", order:Print())

  if (order == nil) then
    log.error("�� ������� ������� ����� " .. json.encode(trade))
  else
      order:SetOperation(operation, price, quantity)
      table.insert(orders, order)
  end

  SubmitOrders(orders)
end
