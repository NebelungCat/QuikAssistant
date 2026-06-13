-- Unit-����� ��� ������ Order
-- ������: lua Tests/run_tests.lua

-- ��������� UTF-8 ��������� ��� ���������� ������ Windows
os.execute("chcp 65001 >nul 2>&1")

-- ��������� ��� QUIK API
dofile("Tests/quik_mock.lua")

-- ��������� �������� ������
dofile("Order.lua")
dofile("QuikFunction.lua")
dofile("TradeSave.lua")
dofile("TableConstructor.lua")

-- ��� N_SetLimitOrder ��� SubmittingOrders
_G.N_SetLimitOrder = function(clientAccountCode, clientCode, classCode, secCode, operation, price, quantity)
  table.insert(tables.orders, {
    sec_code = secCode,
    class_code = classCode,
    flags = operation == "S" and (FLAG_ACTIVE | FLAG_SELL) or FLAG_ACTIVE,
    trans_id = 1,
    order_num = math.random(1000, 9999),
    price = price,
    qty = quantity,
    balance = 0,
  })
  return math.random(1000, 9999), ""
end

_G.sleep = function(ms) end

dofile("SubmittingOrders.lua")

-- ��������������� ������� ����� require("Setting")
VolumeOrderMax = 11000
BondVolumeOrderMax = 7000
OFZVolumeOrderMax = 7000
VolumeOrderLimit = 200000
VolumeOrderLimitUSD = 100
VolumeOrderLimitForeign = 70000
LimitActuationOrderEdge = 5
LimitActuationOrderBondEdge = 60
LimitActuationOrderForeignEdge = 30

local passed = 0
local failed = 0
local errors = {}

local function assert_eq(actual, expected, msg)
  if actual == expected then
    passed = passed + 1
  else
    failed = failed + 1
    local err = string.format(
      "FAIL: %s (���������: %s, ��������: %s)",
      msg or "",
      tostring(expected),
      tostring(actual)
    )
    table.insert(errors, err)
    print("  " .. err)
  end
end

local function assert_true(value, msg)
  if value == true then
    passed = passed + 1
  else
    failed = failed + 1
    local err = string.format("FAIL: %s (���������: true, ��������: %s)", msg or "", tostring(value))
    table.insert(errors, err)
    print("  " .. err)
  end
end

local function assert_false(value, msg)
  if value == false then
    passed = passed + 1
  else
    failed = failed + 1
    local err = string.format("FAIL: %s (���������: false, ��������: %s)", msg or "", tostring(value))
    table.insert(errors, err)
    print("  " .. err)
  end
end

local function test(name, func)
  print("  " .. name)
  func()
end

---------------------------------------------
-- ������������ ������ Order
---------------------------------------------
print("=== ������������ ������ Order ===")

ClearSecurityInfoCache()
test("SecurityCode", function()
  local order = Order:new("GAZP")
  assert_eq(order.SecurityCode, "GAZP", "��� ������")
end)

ClearSecurityInfoCache()
test("SecurityInfo ����", function()
  local order = Order:new("GAZP")
  local expected = getSecurityInfo("TQBR", "GAZP")
  assert_eq(order.SecurityInfo.name, expected.name, "�������� �����������")
  assert_eq(order.SecurityInfo.short_name, expected.short_name, "������� ���")
  assert_eq(order.SecurityInfo.code, "GAZP", "���")
  assert_eq(order.SecurityInfo.isin_code, "RU0007661625", "ISIN")
  assert_eq(order.SecurityInfo.class_code, "TQBR", "��� ������")
  assert_eq(order.SecurityInfo.face_value, 5, "�������")
  assert_eq(order.SecurityInfo.face_unit, "SUR", "������")
  assert_eq(order.SecurityInfo.scale, 2, "��������")
  assert_eq(order.SecurityInfo.min_price_step, 0.01, "���. ��� ����")
  assert_eq(order.SecurityInfo.lot_size, 10, "������ ����")
end)

ClearSecurityInfoCache()
test("���� ������������", function()
  local order = Order:new("GAZP")
  assert_true(order:IsBond() == false, "GAZP �� ���������")
  assert_true(order:IsSpb() == false, "GAZP �� ���")
end)

ClearSecurityInfoCache()
test("�������� Buy ��� �����", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  assert_eq(order.Operation, "B", "��������")
  assert_eq(order.Price, 200.00, "����")
  assert_eq(order.Quantity, 100, "����������")
end)

ClearSecurityInfoCache()
test("�������� Sell", function()
  local order = Order:new("GAZP")
  order:SetOperation("S", 250.00, 50)
  assert_eq(order.Operation, "S", "��������")
  assert_eq(order.Price, 250.00, "����")
  assert_eq(order.Quantity, 50, "����������")
end)

ClearSecurityInfoCache()
test("��������� - ���������� ���", function()
  local order = Order:new("RU000A102RN7")
  assert_eq(order.SecurityInfo.class_code, "TQOB", "��� ������ TQOB")
  assert_true(order:IsBond(), "�������� ����������")
  assert_true(order:IsOFZ(), "�������� ���")
  assert_false(order:IsSpb(), "�� ���")
  assert_false(order:IsForeign(), "�� �����������")
end)

ClearSecurityInfoCache()
test("��������� - �������", function()
  local order = Order:new("RU000A102RN7")
  assert_eq(order.SecurityInfo.face_value, 1000.00, "������� ���������")
end)

ClearSecurityInfoCache()
test("SPB - ���������� ���", function()
  local order = Order:new("ADBE_SPB")
  assert_true(order:IsSpb(), "�������� SPB")
end)

ClearSecurityInfoCache()
test("SetOperation", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  assert_eq(order.Operation, "B", "�������� B")
  order:SetOperation("S", 250.00, 50)
  assert_eq(order.Operation, "S", "�������� S")
end)

ClearSecurityInfoCache()
test("SetQuantity", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  order:SetQuantity("B", 200.00, 200)
  assert_true(order.Quantity > 0, "���������� > 0")
end)

ClearSecurityInfoCache()
test("SetPriceMin", function()
  local order = Order:new("GAZP")
  order:SetPriceMin("B")
  assert_true(order.Price > 0, "���� > 0 ����� SetPriceMin")
end)

ClearSecurityInfoCache()
test("Clear", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  order:Clear()
  assert_eq(order.Operation, "", "�������� ����� Clear")
end)

ClearSecurityInfoCache()
test("FormatPrice", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.123, 100)
  assert_eq(order:FormatPrice(), "200.12", "������ ���� GAZP (scale=2)")
end)

ClearSecurityInfoCache()
test("GetPriceRound", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.123, 100)
  order:SetPriceMin("B")
  order:GetPriceRound()
  assert_true(order.Price > 0, "���������� ���� > 0")
end)

ClearSecurityInfoCache()
test("IsExceptionFromLimitActuation", function()
  local order = Order:new("GAZP")
  assert_true(order:IsExceptionFromLimitActuation(), "GAZP - ����������")
  local order2 = Order:new("LKOH")
  assert_false(order2:IsExceptionFromLimitActuation(), "LKOH - �� ����������")
end)

ClearSecurityInfoCache()
test("GetVolume ��� �����", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  assert_true(order:GetVolume() > 0, "����� > 0")
end)

ClearSecurityInfoCache()
test("GetPriceInCurrency", function()
  local order = Order:new("GAZP")
  assert_eq(order:GetPriceInCurrency(100), 100, "���� ����� � ������")
  local bond = Order:new("RU000A102RN7")
  assert_eq(bond:GetPriceInCurrency(100), 1000, "���� ��������� � ������")
end)

ClearSecurityInfoCache()
test("IsBuy/IsSell", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  assert_true(order:IsBuy(), "IsBuy")
  assert_false(order:IsSell(), "�� IsSell")
  order:SetOperation("S", 250.00, 50)
  assert_true(order:IsSell(), "IsSell")
  assert_false(order:IsBuy(), "�� IsBuy")
end)

ClearSecurityInfoCache()
test("Print", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  local str = order:Print()
  assert_true(str ~= nil and #str > 0, "Print ���������� ������")
end)

---------------------------------------------
-- Edge Cases � ��������� ��������
---------------------------------------------
print("\n=== Edge Cases � ��������� �������� ===")

ClearSecurityInfoCache()
test("Order:new � �������������� �������", function()
  local order = Order:new("ZZZZZ")
  assert_true(order == nil, "nil ��� ������������ ������")
end)

ClearSecurityInfoCache()
test("SetOperation � price = 0", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 0, 100)
  assert_true(order.Price > 0, "���� becomes min_price_step")
end)

ClearSecurityInfoCache()
test("SetQuantity � nil �����������", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  order:SetQuantity("B", nil, 200)
  assert_true(order.Quantity >= 0, "���������� >= 0")
  order:SetQuantity("B", 200.00, nil)
  assert_true(order.Quantity >= 0, "���������� >= 0 � nil quantityMax")
end)

ClearSecurityInfoCache()
test("SetQuantity ��� ���������", function()
  local order = Order:new("RU000A102RN7")
  order:SetOperation("B", 95.00, 1)
  assert_true(order.Quantity > 0, "����� > 0 ��� ���������")
end)

ClearSecurityInfoCache()
test("GetPriceRound edge cases", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.123, 100)
  order:SetPriceMin("B")
  order:GetPriceRound()
  assert_true(order.Price > 0, "���������� ���� > 0")
end)

ClearSecurityInfoCache()
test("GetVolume edge cases", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 0, 100)
  assert_true(order:GetVolume() > 0, "����� � ������� �����")
  order:Clear()
  order:SetOperation("B", 200.00, 0)
  assert_true(order:GetVolume() >= 0, "����� � ������� �����������")
end)

ClearSecurityInfoCache()
test("FormatPrice edge cases", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 0, 100)
  assert_eq(order:FormatPrice(), "0.01", "���� = min_price_step")
end)

ClearSecurityInfoCache()
test("FormatQuantity edge cases", function()
  local order = Order:new("GAZP")
  assert_eq(order:FormatQuantity(0), "0", "�������� = 0")
  assert_eq(order:FormatQuantity(4), "0.0000", "�������� = 1 � scale 4")
end)

ClearSecurityInfoCache()
test("Clear ��������� ��� �����������", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  order:Clear()
  assert_eq(order.SecurityInfo.code, "GAZP", "��� ����������� ����� Clear")
end)

ClearSecurityInfoCache()
test("IsBuy/IsSell � nil ���������", function()
  local order = Order:new("GAZP")
  assert_false(order:IsBuy(), "IsBuy � ������ ���������")
end)

---------------------------------------------
-- �������������� edge cases
---------------------------------------------
print("\n=== �������������� edge cases ===")

ClearSecurityInfoCache()
test("��������� ������������ GAZP", function()
  local order1 = Order:new("GAZP")
  local order2 = Order:new("GAZP")
  assert_eq(order1.SecurityCode, order2.SecurityCode, "���������� ���")
end)

ClearSecurityInfoCache()
test("���������������� - ����", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  assert_true(order:IsBuy(), "Buy ��������")
  order:SetOperation("S", 250.00, 50)
  assert_true(order:IsSell(), "Sell ��������")
end)

ClearSecurityInfoCache()
test("�������� �������� - ���������", function()
  local order = Order:new("GAZP")
  assert_eq(order.Operation, "", "������ ��������")
  assert_eq(order.Quantity, 0, "������� ����������")
  assert_eq(order.Price, 0, "������� ����")
end)

ClearSecurityInfoCache()
test("SPB ����������", function()
  local order = Order:new("ADBE_SPB")
  assert_true(order:IsSpb(), "SPB ����������")
  assert_eq(order.SecurityInfo.class_code, "SPBXM", "����� SPBXM")
end)

ClearSecurityInfoCache()
test("����� = 0.01 * 100 * 10", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 0, 100)
  assert_eq(order:GetVolume(), 10, "����� = 0.01 * 100 * 10 = 10")
end)

ClearSecurityInfoCache()
test("�������������� ���� GAZP", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.123, 100)
  assert_eq(order:FormatPrice(), "200.12", "������ ����")
end)

ClearSecurityInfoCache()
test("�������������� ����������", function()
  local order = Order:new("GAZP")
  assert_eq(order:FormatQuantity(4), "0.0000", "������ ����������")
end)

ClearSecurityInfoCache()
test("Print � SetPriceMin", function()
  local order = Order:new("GAZP")
  order:SetPriceMin("B")
  local str = order:Print()
  assert_true(str ~= nil and #str > 0, "Print ��������")
end)

ClearSecurityInfoCache()
test("�������� ��������� - ������� � ���", function()
  local order = Order:new("RU000A102RN7")
  assert_true(order:IsBond(), "���������")
  assert_true(order:IsOFZ(), "���")
  assert_eq(order.SecurityInfo.face_value, 1000.00, "�������")
end)

ClearSecurityInfoCache()
test("IsExceptionFromLimitActuation - ������ ����", function()
  local order = Order:new("GAZP")
  assert_true(order:IsExceptionFromLimitActuation(), "����� - ����������")
end)

ClearSecurityInfoCache()
test("GetPriceRound - ���� �� ����� ����", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  order:SetPriceMin("B")
  order:GetPriceRound()
  assert_true(order.Price > 0, "���� = n * step ��� �����")
end)

ClearSecurityInfoCache()
test("GetVolume - �������������� edge cases", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 1)
  assert_true(order:GetVolume() > 0, "����� � ����������� 1")
end)

ClearSecurityInfoCache()
test("SetQuantity - ���������� �����", function()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  order:SetQuantity("B", 200.00, 200)
  assert_true(order.Quantity > 0, "���������� > 0")
end)

ClearSecurityInfoCache()
test("�������������� ��������������", function()
  local order = Order:new("GAZP")
  assert_eq(order:FormatQuantity(4), "0.0000", "FormatQuantity")
  local order2 = Order:new("GAZP")
  order2:SetOperation("B", 200.00, 100)
  assert_eq(order2:FormatPrice(), "200.00", "FormatPrice")
end)

ClearSecurityInfoCache()
test("�������� ������������ �����������", function()
  local order = Order:new("GAZP")
  assert_true(order.SecurityInfo ~= nil, "SecurityInfo ����������")
end)

---------------------------------------------
-- QuikFunction �����
---------------------------------------------
print("\n=== QuikFunction ����� ===")

test("GetOperation, IsOrderExecuted, FindOrder", function()
  assert_eq(GetOperation(FLAG_ACTIVE | FLAG_SELL), "S", "GetOperation sell")
  assert_eq(GetOperation(FLAG_ACTIVE), "B", "GetOperation buy")
  assert_false(IsOrderExecuted(FLAG_EXECUTED), "IsOrderExecuted ��� executed")
  assert_false(IsOrderExecuted(FLAG_ACTIVE), "IsOrderExecuted ��� active")
end)

test("TradeSave - ��������� ��������", function()
  assert_true((FLAG_EXECUTED & FLAG_EXECUTED) > 0, "FLAG_EXECUTED")
  assert_true((FLAG_ACTIVE & FLAG_ACTIVE) > 0, "FLAG_ACTIVE")
  assert_true((FLAG_SELL & FLAG_SELL) > 0, "FLAG_SELL")
end)

test("TableConstructor �������", function()
  assert_eq(comma_value(1000), "1 000", "comma_value")
  assert_eq(round(1.5), 2, "round")
end)

test("GetKoeffVolumeOrderMax", function()
  local order = Order:new("GAZP")
  local koeff = GetKoeffVolumeOrderMax(order, 200)
  assert_true(koeff >= 1, "koeff >= 1")
end)

test("GetOrderVolumeMax", function()
  local order = Order:new("GAZP")
  local vol = GetOrderVolumeMax(order, 200)
  assert_true(vol > 0, "����� > 0")
end)

ClearSecurityInfoCache()
test("��������� - �����", function()
  local order = Order:new("RU000A102RN7")
  local vol = GetOrderVolumeMax(order, 90)
  assert_true(vol > 0, "����� > 0")
end)

ClearSecurityInfoCache()
test("����������� ������ - �����", function()
  local order = Order:new("ADBE_SPB")
  local vol = GetOrderVolumeMax(order, 400)
  assert_true(vol > 0, "����� > 0")
end)

---------------------------------------------
-- SubmittingOrders �����
---------------------------------------------
print("\n=== SubmittingOrders ����� ===")

local function resetSendOrders()
  sendOrders = {}
  sendOrdersSet = {}
  clearTestData()
  ClearPositionCache()
end

ClearSecurityInfoCache()
test("GetDedupKey", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  local key = order:GetDedupKey()
  assert_eq(key, "GAZP B 100 200.00", "dedup key format")
end)

ClearSecurityInfoCache()
test("IsSendOrder - �� ���������", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  assert_eq(IsSendOrder(order), false, "����� ����� �� � ���������")
end)

ClearSecurityInfoCache()
test("IsSendOrder - ��� ���������", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  sendOrdersSet[order:GetDedupKey()] = true
  assert_eq(IsSendOrder(order), true, "������������ ����� � ���������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - �������� ������ ������", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  local stats = SubmitOrders({ order })
  assert_eq(stats.sent, 1, "1 ����� ���������")
  assert_eq(stats.rejected, 0, "0 ���������")
  assert_eq(stats.duplicate, 0, "0 ����������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - �������� ����� IsSendOrder", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  SubmitOrders({ order })
  local stats = SubmitOrders({ order })
  assert_eq(stats.sent, 0, "0 ����� ����������")
  assert_eq(stats.duplicate, 1, "1 ��������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - �������� ����� IsOrderExists", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  addTestOrder("GAZP", "TQBR", FLAG_ACTIVE, 1, 100, 200.00, 100, 0)
  local stats = SubmitOrders({ order })
  assert_eq(stats.sent, 0, "0 ���������� - ���� � QUIK")
  assert_eq(stats.duplicate, 1, "1 ��������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - ���������: QUIK > sendOrders", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  addTestOrder("GAZP", "TQBR", FLAG_ACTIVE, 1, 100, 200.00, 100, 0)
  sendOrdersSet[order:GetDedupKey()] = true
  local stats = SubmitOrders({ order })
  assert_eq(stats.duplicate, 1, "�������� �������� ���� ���")
  assert_eq(stats.sent, 0, "�� ���������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - ���������� CheckOrder", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 0, 0)
  local stats = SubmitOrders({ order })
  assert_eq(stats.rejected, 1, "1 ��������")
  assert_eq(stats.sent, 0, "0 ����������")
end)

ClearSecurityInfoCache()
test("CheckOrder - UseFileParams + price below PRICEMIN", function()
  resetSendOrders()
  local savedGetParamEx = getParamEx
  getParamEx = function(class_code, sec_code, param)
    if param == "PRICEMIN" then
      return { result = "1", param_value = "100.0" }
    end
    if param == "LAST" then
      return { result = "1", param_value = "200.0" }
    end
    if param == "PREVPRICE" then
      return { result = "1", param_value = "190.0" }
    end
    return { result = "1", param_value = "0" }
  end
  local order = Order:new("GAZP")
  order:SetOperation("B", 50.00, 10)
  order.UseFileParams = true
  local isCheck, rejectReason = CheckOrder(order)
  assert_false(isCheck, "UseFileParams order with price < PRICEMIN should be rejected")
  assert_true(string.find(rejectReason, "below PRICEMIN") ~= nil, "reason mentions PRICEMIN")
  getParamEx = savedGetParamEx
end)

ClearSecurityInfoCache()
test("SubmitOrders - ��������� �����", function()
  resetSendOrders()
  local order1 = Order:new("GAZP")
  order1:SetOperation("B", 200.00, 100)
  local order2 = Order:new("LKOH")
  order2:SetOperation("B", 5000.00, 10)
  local stats = SubmitOrders({ order1, order2 })
  assert_eq(stats.sent, 2, "2 ������ ����������")
  assert_eq(stats.rejected, 0, "0 ���������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - ����������", function()
  resetSendOrders()
  local order1 = Order:new("GAZP")
  order1:SetOperation("B", 200.00, 100)
  local order2 = Order:new("GAZP")
  order2:SetOperation("B", 200.00, 100)
  local order3 = Order:new("LKOH")
  order3:SetOperation("B", 0, 0)
  local stats = SubmitOrders({ order1, order2, order3 })
  assert_eq(stats.sent, 1, "1 ���������")
  assert_eq(stats.rejected, 1, "1 ��������")
  assert_eq(stats.duplicate, 1, "1 ��������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - sendOrdersSet �������", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("B", 200.00, 100)
  SubmitOrders({ order })
  assert_eq(sendOrdersSet[order:GetDedupKey()], true, "���� � ���������")
  assert_eq(#sendOrders, 1, "1 � ������ sendOrders")
end)

ClearSecurityInfoCache()
test("SubmitOrders - ���������", function()
  resetSendOrders()
  local savedGetParamEx = getParamEx
  getParamEx = function(class_code, sec_code, param)
    if param == "PRICEMIN" then
      return { result = "1", param_value = "90.0" }
    end
    if param == "LAST" then
      return { result = "1", param_value = "100.0" }
    end
    if param == "PREVPRICE" then
      return { result = "1", param_value = "95.0" }
    end
    return { result = "1", param_value = "0" }
  end
  local order = Order:new("RU000A102RN7")
  order:SetOperation("B", 95.00, 1)
  local stats = SubmitOrders({ order })
  assert_eq(stats.sent, 1, "����� ��������� ���������")
  getParamEx = savedGetParamEx
end)

ClearSecurityInfoCache()
test("SubmitOrders - ������� � ��������", function()
  resetSendOrders()
  addTestPosition("GAZP", 50, 250.00)
  local order = Order:new("GAZP")
  order:SetOperation("S", 200.00, 10)
  local stats = SubmitOrders({ order })
  assert_eq(stats.sent, 1, "����� ������� ���������")
end)

ClearSecurityInfoCache()
test("SubmitOrders - ������� ��� ������� �����������", function()
  resetSendOrders()
  local order = Order:new("GAZP")
  order:SetOperation("S", 200.00, 10)
  local stats = SubmitOrders({ order })
  assert_eq(stats.rejected, 1, "������� ��������� - ��� �������")
  assert_eq(stats.sent, 0, "0 ����������")
end)

---------------------------------------------
-- LoadOrdersFromFile �����
---------------------------------------------
print("\n=== LoadOrdersFromFile ����� ===")

local originalGetFromCSV = getFromCSV

local function mockCSV(rows)
  getFromCSV = function(fileName)
    return rows
  end
end

local function restoreCSV()
  getFromCSV = originalGetFromCSV
end

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ������� buy �����", function()
  mockCSV({ { "Gazprom", "B", "GAZP", "100", "200.00" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 1, "1 ����� ��������")
  assert_eq(orders[1].SecurityCode, "GAZP", "��� ������")
  assert_eq(orders[1].Operation, "B", "��������")
  assert_eq(orders[1].Quantity, 100, "����������")
  assert_eq(orders[1].Price, 200.00, "����")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ��������� �������", function()
  mockCSV({ { "Gazprom", "B", "GAZP", "100", "200.00" }, { "Lukoil", "B", "LKOH", "10", "7000.00" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 2, "2 ������ ���������")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ����������� ������������", function()
  mockCSV({
    { "-- header", "B", "GAZP", "100", "200.00" },
    { "Gazprom", "B", "GAZP", "100", "200.00" },
    { "-- footer", "B", "GAZP", "50", "250.00" },
  })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 1, "1 ����� (2 ����������� ���������)")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ����������� ����� ������������", function()
  unknownSecurities = {}
  mockCSV({ { "Unknown", "B", "ZZZZZ", "100", "200.00" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 0, "0 ������� (����������� �����)")
  assert_true(unknownSecurities["ZZZZZ"] ~= nil, "ZZZZZ ����������� ���� unknownSecurities")
  assert_eq(unknownSecurities["ZZZZZ"], "Unknown", "��� ������ �����������")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ������ CSV", function()
  mockCSV({})
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 0, "0 ������� �� ������� CSV")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - sell �����", function()
  mockCSV({ { "Gazprom", "S", "GAZP", "50", "250.00" } })
  local orders = LoadOrdersFromFile("TEST_SellOrders.csv")
  assert_eq(#orders, 1, "1 sell ����� ��������")
  assert_eq(orders[1].Operation, "S", "�������� S")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ���������", function()
  mockCSV({ { "OFZ", "B", "RU000A102RN7", "1", "95.00" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 1, "1 ����� ���������")
  assert_true(orders[1]:IsBond(), "���������")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - edge ����", function()
  mockCSV({ { "Gazprom", "B", "GAZP", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders_Edge.csv")
  assert_eq(#orders, 1, "1 edge �����")
  assert_true(orders[1].Quantity > 0, "���������� ����������")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - edge ���������", function()
  mockCSV({ { "OFZ", "B", "RU000A102RN7", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrdersBonds_Edge.csv")
  assert_eq(#orders, 1, "1 edge ����� ���������")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - SPB edge", function()
  mockCSV({ { "Foreign", "B", "ADBE_SPB", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrdersSpb_Edge.csv")
  assert_eq(#orders, 1, "1 SPB �����")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - RmUSD edge", function()
  mockCSV({ { "Foreign", "B", "ADBE_SPB", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders_RmUSD_Edge.csv")
  assert_eq(#orders, 1, "1 RmUSD �����")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - ��������� ������", function()
  mockCSV({
    { "-- header", "B", "GAZP", "100", "200.00" },
    { "Gazprom", "B", "GAZP", "100", "200.00" },
    { "Lukoil", "B", "LKOH", "10", "7000.00" },
    { "-- footer", "B", "GAZP", "50", "200.00" },
    { "Gazprom2", "B", "GAZP", "200", "300.00" },
  })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 3, "3 ������ (2 ����������� ���������)")
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - SPB �����", function()
  mockCSV({ { "Foreign", "B", "ADBE_SPB", "10", "400.00" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders.csv")
  assert_eq(#orders, 1, "1 SPB �����")
  assert_true(orders[1]:IsSpb(), "SPB ����������")
  restoreCSV()
end)

local originalGetParamEx = getParamEx

ClearSecurityInfoCache()
test("LoadOrdersFromFile - edge с priceMin=0 (пропуск)", function()
  getParamEx = function(class_code, sec_code, param)
    if param == "PRICEMIN" then
      return { result = "1", param_value = "0" }
    end
    if param == "LAST" then
      return { result = "1", param_value = "250.0" }
    end
    if param == "PRICEMAX" then
      return { result = "1", param_value = "300.0" }
    end
    if param == "PREVPRICE" then
      return { result = "1", param_value = "245.0" }
    end
    return { result = "1", param_value = "0" }
  end
  mockCSV({ { "Gazprom", "B", "GAZP", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders_Edge.csv")
  assert_eq(#orders, 0, "0 ����� (priceMin=0, ������)")
  getParamEx = originalGetParamEx
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - edge ����� � ������", function()
  local savedLimit = VolumeOrderLimit
  VolumeOrderLimit = 50000
  mockCSV({ { "Gazprom", "B", "GAZP", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders_Edge.csv")
  assert_eq(#orders, 1, "1 �����")
  local volume = orders[1]:GetVolume()
  assert_true(volume <= VolumeOrderLimit, "����� � ������")
  VolumeOrderLimit = savedLimit
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - edge � ������� koeff", function()
  getParamEx = function(class_code, sec_code, param)
    if param == "PRICEMIN" then
      return { result = "1", param_value = "100.0" }
    end
    if param == "LAST" then
      return { result = "1", param_value = "250.0" }
    end
    if param == "PRICEMAX" then
      return { result = "1", param_value = "300.0" }
    end
    if param == "PREVPRICE" then
      return { result = "1", param_value = "245.0" }
    end
    return { result = "1", param_value = "0" }
  end
  mockCSV({ { "Gazprom", "B", "GAZP", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders_Edge.csv")
  assert_eq(#orders, 1, "1 �����")
  assert_true(orders[1].Quantity > 0, "���������� ���������� � koeff")
  getParamEx = originalGetParamEx
  restoreCSV()
end)

ClearSecurityInfoCache()
test("LoadOrdersFromFile - edge ����� � ����������� ������", function()
  local savedLimit = VolumeOrderLimit
  local savedMax = VolumeOrderMax
  VolumeOrderMax = 500000
  VolumeOrderLimit = 100000
  getParamEx = function(class_code, sec_code, param)
    if param == "PRICEMIN" then
      return { result = "1", param_value = "1.0" }
    end
    if param == "LAST" then
      return { result = "1", param_value = "250.0" }
    end
    if param == "PRICEMAX" then
      return { result = "1", param_value = "300.0" }
    end
    if param == "PREVPRICE" then
      return { result = "1", param_value = "245.0" }
    end
    return { result = "1", param_value = "0" }
  end
  mockCSV({ { "Gazprom", "B", "GAZP", "0", "0" } })
  local orders = LoadOrdersFromFile("TEST_BuyOrders_Edge.csv")
  assert_eq(#orders, 1, "1 �����")
  local volume = orders[1]:GetVolume()
  assert_true(volume <= VolumeOrderLimit, "����� �� ��������� �����")
  VolumeOrderLimit = savedLimit
  VolumeOrderMax = savedMax
  getParamEx = originalGetParamEx
  restoreCSV()
end)

---------------------------------------------
-- �����
---------------------------------------------
print("\n" .. string.rep("=", 40))
print(string.format("���������: %d ������, %d �����", passed, failed))
if #errors > 0 then
  print("\n������:")
  for _, err in ipairs(errors) do
    print("  " .. err)
  end
end

os.exit(failed > 0 and 1 or 0)
