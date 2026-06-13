require("TableSetting")

--- Коды флагов транзакций QUIK
FLAG_ACTIVE = 0x1
FLAG_EXECUTED = 0x2
FLAG_SELL = 0x4

--- Коды ошибок транзакций QUIK
ERR_PRICE_TOO_LOW = 579
ERR_PRICE_TOO_HIGH = 580
ERR_EXECUTION_REJECTED = 133

--- Коды статусов транзакций
TRANS_STATUS_REJECTED = 2
TRANS_STATUS_COMPLETED = 3

--- Множитель для корректировки цен
PRICE_DEVIATION_MULTIPLIER = 10

--- Настройки параметров
Broker = ""
ClientCode = ""
AccountCode = ""
AccountCodeSpb = ""
FirmId = ""
VolumeOrderMin = 0
VolumeOrderMax = 0
BondVolumeOrderMax = 0
--- Настройки из размера облигаций
OFZVolumeOrderMax = 0
--- Настройки из размера сделки
VolumeOrderLimit = 200000
--- Настройки из размера сделки в долларах
VolumeOrderLimitUSD = 100
--- Настройки из размера сделки иностранных бумаг и фондов
VolumeOrderLimitForeign = 70000

--- Настройки настолчика от цены рынка
LimitActuationOrderEdge = 5
--- Настройки настолчика от цены рынка облигаций
LimitActuationOrderBondEdge = 60
--- Настройки настолчика от цены рынка иностранных бумаг
LimitActuationOrderForeignEdge = 30

FileBuyOrder = ""
FileSellOrder = ""
FileBuyOrderEdge = ""
FileBuyOrderBondsEdge = ""
FileBuyOrderSpbEdge = ""
FileBuyOrderRmUsdEdge = ""

function SetSettingFinam()
  Broker = "FINAM"
  ClientCode = "0734A/0734A"
  AccountCode = "L01+00000F00"
  FirmId = "MC0061900000"
  VolumeOrderMin = 11000
  VolumeOrderMax = 70000
  VolumeOrderLimitForeign = 50000
  BondVolumeOrderMax = 100000
  OFZVolumeOrderMax = 10000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 50
  LimitActuationOrderForeignEdge = 50
  VolumeOrderLimit = 120000
end

function SetSettingVTB()
  Broker = "VTB"
  ClientCode = "386507"
  AccountCode = "L01-00000F00"
  AccountCodeSpb = "VTBRM_CL"
  FirmId = "MC0003300000"
  VolumeOrderMin = 11000
  VolumeOrderMax = 20000
  BondVolumeOrderMax = 20000
  OFZVolumeOrderMax = 15000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 30
  LimitActuationOrderForeignEdge = 50
end

function SetSettingPSB()
  Broker = "PSB"
  ClientCode = "40200"
  AccountCode = "L01+00000F00"
  FirmId = "MC0038600000"
  VolumeOrderMin = 10000
  VolumeOrderMax = 50000
  BondVolumeOrderMax = 100000
  OFZVolumeOrderMax = 10000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 0
  VolumeOrderLimit = 120000
end

function SetSettingRSHB()
  Broker = "RSHB"
  ClientCode = "496082"
  AccountCode = "L01+00000F00"
  AccountCodeSpb = "VTBRM_CL"
  FirmId = "MC0134700000"
  VolumeOrderMin = 11000
  VolumeOrderMax = 20000
  BondVolumeOrderMax = 20000
  OFZVolumeOrderMax = 15000
  LimitActuationOrderEdge = 0
  LimitActuationOrderBondEdge = 60
  LimitActuationOrderForeignEdge = 50
end

function SetSettingTest()
  Broker = "TEST"
  ClientCode = "10567"
  AccountCode = "NL0011100043"
  FirmId = ""
  VolumeOrderMin = 11000
  VolumeOrderMax = 11000
  BondVolumeOrderMax = 7000
  OFZVolumeOrderMax = 7000
end

--- Настройки параметров для брокера
function SetClientSetting()
  -- Очистка кэша параметров и кода для всех брокеров
  if ClearSecurityInfoCache then
    ClearSecurityInfoCache()
  end
  local userId = getInfoParam("USERID")
  local problem = ""
  if userId == nil or userId == "" then
    problem = "ID пользователя не найден"
  end

  if userId == "171783" then
    SetSettingFinam()
  elseif userId == "49653" then
    SetSettingVTB()
  elseif userId == "34146" then
    SetSettingPSB()
  elseif userId == "48640" then
    SetSettingRSHB()
  elseif userId == "119330" then
    SetSettingTest()
  else
    Broker = ""
    ClientCode = ""
    AccountCode = ""
    VolumeOrderMax = 0
  end

  FileBuyOrder = Broker .. "_BuyOrders.csv"
  FileSellOrder = Broker .. "_SellOrders.csv"
  FileBuyOrderEdge = Broker .. "_BuyOrders_Edge.csv"
  FileBuyOrderBondsEdge = Broker .. "_BuyOrdersBonds_Edge.csv"
  FileBuyOrderSpbEdge = Broker .. "_BuyOrdersSpb_Edge.csv"
  FileBuyOrderRmUsdEdge = Broker .. "_BuyOrders_RmUSD_Edge.csv"
end
