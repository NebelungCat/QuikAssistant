EventTable = {
  [QTABLE_LBUTTONDOWN] = "Нажатие левой кнопки мыши",
  [QTABLE_RBUTTONDOWN] = "Нажатие правой кнопки мыши",
  [QTABLE_LBUTTONDBLCLK] = "Двойной клик",
  [QTABLE_RBUTTONDBLCLK] = "Нажатие правого клика",
  [QTABLE_SELCHANGED] = "Изменение строки",
  [QTABLE_CHAR] = "Нажатие символа",
  [QTABLE_VKEY] = "Код клавиши клавиатуры",
  [QTABLE_CONTEXTMENU] = "Контекстное меню",
  [QTABLE_MBUTTONDOWN] = "Нажатие на среднюю кнопку",
  [QTABLE_MBUTTONDBLCLK] = "Двойное нажатие",
  [QTABLE_LBUTTONUP] = "Отпускание левой кнопки мыши",
  [QTABLE_RBUTTONUP] = "Отпускание правой кнопки мыши",
  [QTABLE_CLOSE] = "Закрытие окна",
}

QTable = {}
QTable.__index = QTable

-- Конструктор с основными методами объекта QTable
function QTable.new()
  local t_id = AllocTable()
  if t_id ~= nil then
    q_table = {}
    setmetatable(q_table, QTable)
    q_table.t_id = t_id
    q_table.caption = ""
    q_table.created = false
    q_table.curr_col = 0
    -- Конструктор и описание переменных столбцов
    q_table.columns = {}
    return q_table
  else
    return nil
  end
end

function QTable:Show()
  -- Открытие и позиционирование окна на экране монитора
  CreateWindow(self.t_id)
  if self.caption ~= "" then
    -- Установка заголовка для окна
    SetWindowCaption(self.t_id, self.caption)
  end
  self.created = true
end

function QTable:IsClosed()
  -- Если окно уже закрыто, возвращаем true
  return IsWindowClosed(self.t_id)
end

function QTable:Delete()
  -- Удаление таблицы
  DestroyTable(self.t_id)
end

function QTable:GetCaption()
  if IsWindowClosed(self.t_id) then
    return self.caption
  else
    -- Возвращаем строку, содержащую заголовок окна
    return GetWindowCaption(self.t_id)
  end
end

-- Установка заголовка таблицы
function QTable:SetCaption(s)
  self.caption = s
  if not IsWindowClosed(self.t_id) then
    res = SetWindowCaption(self.t_id, tostring(s))
  end
end

-- Добавление нового столбца <name> типа <c_type> в таблицу
-- <ff> это функция форматирования данных для отображения
function QTable:AddColumn(name, c_type, width, ff)
  local col_desc = {}
  self.curr_col = self.curr_col + 1
  col_desc.c_type = c_type
  col_desc.format_function = ff
  col_desc.id = self.curr_col
  self.columns[name] = col_desc
  -- <name> используется как заголовок столбца таблицы
  AddColumn(self.t_id, self.curr_col, name, true, c_type, width)
end

function QTable:Clear()
  -- Очистка таблицы
  Clear(self.t_id)
end

-- Установка значения в ячейку
function QTable:SetValue(row, col_name, data)
  local col_ind = self.columns[col_name].id or nil
  if col_ind == nil then
    return false
  end
  -- Если есть функция форматирования данных, то она используется
  local ff = self.columns[col_name].format_function

  if type(ff) == "function" then
    -- В противном случае используется форматирование по умолчанию
    -- Отображаем отформатированную строку и исходные данные
    SetCell(self.t_id, row, col_ind, ff(data), data)
    return true
  else
    SetCell(self.t_id, row, col_ind, tostring(data), data)
  end
end

function QTable:AddLine()
  -- Добавляет в конец таблицы новую строку и возвращает её номер
  return InsertRow(self.t_id, -1)
end

function QTable:GetSize()
  -- Возвращает размер таблицы
  return GetTableSize(self.t_id)
end

-- Получение данных из ячейки по номеру строки и имени столбца
function QTable:GetValue(row, name)
  local t = {}
  local col_ind = self.columns[name].id
  if col_ind == nil then
    return nil
  end
  t = GetCell(self.t_id, row, col_ind)
  return t
end

-- Установка положения окна
function QTable:SetPosition(x, y, dx, dy)
  return SetWindowPos(self.t_id, x, y, dx, dy)
end

-- Получение положения текущего окна
function QTable:GetPosition()
  top, left, bottom, right = GetWindowRect(self.t_id)
  return top, left, right - left, bottom - top
end

-- Установка цвета ячейки таблицы
function QTable:Red(row, col)
  SetColor(self.t_id, row, col, RGB(255, 0, 0), RGB(0, 0, 0), RGB(255, 0, 0), RGB(0, 0, 0))
end
function QTable:Yellow(row, col)
  SetColor(self.t_id, row, col, RGB(240, 240, 0), RGB(0, 0, 0), RGB(240, 240, 0), RGB(0, 0, 0))
end
function QTable:Green(row, col)
  SetColor(self.t_id, row, col, RGB(0, 200, 0), RGB(0, 0, 0), RGB(0, 200, 0), RGB(0, 0, 0))
end
function QTable:Default(row, col)
  SetColor(self.t_id, row, col, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR)
end

-- from sam_lie
-- Compatible with Lua 5.0 and 5.1.
-- Disclaimer : use at own risk especially for hedge fund reports :-)

---============================================================
-- add comma to separate thousands
--
function comma_value(amount)
  local formatted = amount
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1 %2")
    if k == 0 then
      break
    end
  end
  return formatted
end

---============================================================
-- rounds a number to the nearest decimal places
--
function round(val, decimal)
  val = val or 0
  if decimal then
    return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
  else
    return math.floor(val + 0.5)
  end
end

--===================================================================
-- given a numeric value formats output with comma to separate thousands
-- and rounded to given decimal places
--
--
function format_num(amount, decimal, prefix, neg_prefix)
  local str_amount, formatted, famount, remain

  amount = amount or 0
  decimal = decimal or 2 -- default 2 decimal places
  neg_prefix = neg_prefix or "-" -- default negative sign

  famount = math.abs(round(amount, decimal))
  famount = math.floor(famount)

  remain = round(math.abs(amount) - famount, decimal)

  -- comma to separate the thousands
  formatted = comma_value(famount)

  -- attach the decimal portion
  if decimal > 0 then
    remain = string.sub(tostring(remain), 3)
    formatted = formatted .. "." .. remain .. string.rep("0", decimal - string.len(remain))
  end

  -- attach prefix string e.g '$'
  formatted = (prefix or "") .. formatted

  -- if value is negative then format accordingly
  if amount < 0 then
    if neg_prefix == "()" then
      formatted = "(" .. formatted .. ")"
    else
      formatted = neg_prefix .. formatted
    end
  end

  return formatted
end
