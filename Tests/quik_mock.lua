-- ��� API QUIK ��� unit-������������

_G.isConnected = function()
  return 1
end

_G.getInfoParam = function(param)
  if param == "USERID" then
    return "119330"
  end
  if param == "SERVERTIME" then
    return "10:30:00"
  end
  return ""
end

_G.getScriptPath = function()
  return "."
end

_G.sleep = function(ms) end
_G.message = function(text) end

local securities = {
  GAZP = {
    name = '"�������" (���) ��',
    short_name = "������� ��",
    code = "GAZP",
    isin_code = "RU0007661625",
    regnumber = "1-02-00028-A",
    class_name = "����� ������������",
    class_code = "TQBR",
    face_value = 5,
    face_unit = "SUR",
    scale = 2,
    min_price_step = 0.01,
    lot_size = 10,
  },
  ["RU000A102RN7"] = {
    name = "�� ���� ���-06",
    short_name = "������6",
    code = "RU000A102RN7",
    isin_code = "RU000A102RN7",
    regnumber = "4B020603354B",
    class_name = "��������� ��������",
    class_code = "TQOB",
    face_value = 1000.00,
    face_unit = "SUR",
    scale = 2,
    min_price_step = 0.01,
    lot_size = 1,
  },
  ADBE_SPB = {
    name = "Adobe Inc.",
    short_name = "Adobe Inc.",
    code = "ADBE_SPB",
    isin_code = "US00724F1012",
    regnumber = "",
    class_name = "SPB: �����������",
    class_code = "SPBXM",
    face_value = 0.0001,
    face_unit = "USD",
    scale = 2,
    min_price_step = 0.01,
    lot_size = 1,
  },
  LKOH = {
    name = '"������" (���) ��',
    short_name = "������ ��",
    code = "LKOH",
    isin_code = "RU0009029458",
    regnumber = "1-01-00010-A",
    class_name = "����� ������������",
    class_code = "TQBR",
    face_value = 25,
    face_unit = "SUR",
    scale = 2,
    min_price_step = 5.0,
    lot_size = 1,
  },
}

_G.getSecurityInfo = function(class_code, sec_code)
  local sec = securities[sec_code]
  if sec and sec.class_code == class_code then
    local copy = {}
    for k, v in pairs(sec) do
      copy[k] = v
    end
    return copy
  end
  return nil
end

local params = {
  LAST = {},
  PRICEMIN = {},
  PRICEMAX = {},
  PREVPRICE = {},
  LASTCHANGE = {},
}

_G.getParamEx = function(class_code, sec_code, param)
  local defaults = {
    LAST = "250.0",
    PRICEMIN = "200.0",
    PRICEMAX = "300.0",
    PREVPRICE = "245.0",
    LASTCHANGE = "1.5",
  }
  return {
    result = "1",
    param_value = defaults[param] or "0",
  }
end

local tables = {
  orders = {},
  depo_limits = {},
}
_G.tables = tables

_G.getNumberOf = function(table_name)
  if tables[table_name] then
    return #tables[table_name]
  end
  return 0
end

_G.SearchItems = function(table_name, from, to, func, params)
  local items = tables[table_name] or {}
  local results = {}
  for i = from + 1, to + 1 do
    if i <= #items then
      local item = items[i]
      if func then
        local args = {}
        for rawParam in string.gmatch(params, "([^,]+)") do
          local param = rawParam:gsub("^%s+", ""):gsub("%s+$", "")
          table.insert(args, item[param] or item[param:gsub("_", "")])
        end
        if func(unpack(args)) then
          table.insert(results, i - 1)
        end
      else
        table.insert(results, i - 1)
      end
    end
  end
  return results
end

_G.getItem = function(table_name, index)
  local items = tables[table_name] or {}
  return items[index + 1]
end

_G.sendTransaction = function(transaction)
  return ""
end

_G.getPortfolioInfoEx = function(firm_id, client_code, flags)
  return {
    in_all_assets = 1500000,
    all_assets = 1200000,
    profit_loss = 50000,
    rate_change = 2.5,
  }
end

local table_id_counter = 100

_G.AllocTable = function()
  table_id_counter = table_id_counter + 1
  return table_id_counter
end

_G.CreateWindow = function(t_id) end
_G.DestroyTable = function(t_id) end
_G.IsWindowClosed = function(t_id)
  return false
end
_G.SetWindowCaption = function(t_id, caption) end
_G.GetWindowCaption = function(t_id)
  return ""
end
_G.SetWindowPos = function(t_id, x, y, dx, dy) end
_G.GetWindowRect = function(t_id)
  return 0, 0, 640, 480
end
_G.AddColumn = function(t_id, col, name, visible, c_type, width) end
_G.Clear = function(t_id) end
_G.InsertRow = function(t_id, pos)
  return math.random(1, 100)
end
_G.GetTableSize = function(t_id)
  return 0, 0
end
_G.SetCell = function(t_id, row, col, text, image) end
_G.GetCell = function(t_id, row, col)
  return { image = "", value = "" }
end
_G.SetColor = function(t_id, row, col, fg1, fg2, bg1, bg2) end
_G.SetTableNotificationCallback = function(t_id, func) end

_G.QTABLE_STRING_TYPE = 1
_G.QTABLE_DOUBLE_TYPE = 2
_G.QTABLE_INT64_TYPE = 3
_G.QTABLE_NO_INDEX = -1
_G.QTABLE_DEFAULT_COLOR = 0xFFFFFF
_G.QTABLE_LBUTTONDBLCLK = 0x100

_G.QTABLE_LBUTTONDOWN = 0x001
_G.QTABLE_RBUTTONDOWN = 0x002
_G.QTABLE_RBUTTONDBLCLK = 0x003
_G.QTABLE_SELCHANGED = 0x004
_G.QTABLE_CHAR = 0x005
_G.QTABLE_VKEY = 0x006
_G.QTABLE_CONTEXTMENU = 0x007
_G.QTABLE_MBUTTONDOWN = 0x008
_G.QTABLE_MBUTTONDBLCLK = 0x009
_G.QTABLE_LBUTTONUP = 0x00A
_G.QTABLE_RBUTTONUP = 0x00B
_G.QTABLE_CLOSE = 0x00C

_G.RGB = function(r, g, b)
  return r * 65536 + g * 256 + b
end

function addTestPosition(sec_code, balance, wa_price)
  table.insert(tables.depo_limits, {
    sec_code = sec_code,
    limit_kind = 2,
    currentbal = tostring(balance),
    wa_position_price = tostring(wa_price),
  })
end

function addTestOrder(sec_code, class_code, flags, trans_id, order_num, price, qty, balance)
  table.insert(tables.orders, {
    sec_code = sec_code,
    class_code = class_code,
    flags = flags,
    trans_id = trans_id,
    order_num = order_num,
    price = tostring(price),
    qty = qty,
    balance = balance or 0,
  })
end

function clearTestData()
  tables.orders = {}
  tables.depo_limits = {}
end

_G.ClearSecurityInfoCache = function() end
_G.ClearPositionCache = function() end

_G.log = {
  trace = function(...) end,
  debug = function(...) end,
  info = function(...) end,
  warn = function(...) end,
  error = function(...) end,
  fatal = function(...) end,
  outfile = nil,
  level = "trace",
  usecolor = false,
}

_G.json = {
  encode = function(t)
    return "{}"
  end,
  decode = function(s)
    return {}
  end,
}

_G.FLAG_ACTIVE = 0x1
_G.FLAG_EXECUTED = 0x2
_G.FLAG_SELL = 0x4
_G.ERR_PRICE_TOO_LOW = 579
_G.ERR_PRICE_TOO_HIGH = 580
_G.TRANS_STATUS_REJECTED = 2
_G.TRANS_STATUS_COMPLETED = 3
_G.PRICE_DEVIATION_MULTIPLIER = 10

_G.Broker = "TEST"
_G.ClientCode = "10567"
_G.AccountCode = "NL0011100043"
_G.AccountCodeSpb = ""
_G.FirmId = ""
_G.VolumeOrderMin = 11000
_G.VolumeOrderMax = 11000
_G.BondVolumeOrderMax = 7000
_G.OFZVolumeOrderMax = 7000
_G.VolumeOrderLimit = 200000
_G.VolumeOrderLimitUSD = 100
_G.VolumeOrderLimitForeign = 70000
_G.LimitActuationOrderEdge = 5
_G.LimitActuationOrderBondEdge = 60
_G.LimitActuationOrderForeignEdge = 30

print("[MOCK] QUIK API ������ ��������")

if not unpack then
  unpack = table.unpack
end
