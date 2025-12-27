LootTrackerDB = LootTrackerDB or {}

local BASE_ICON_SIZE = 34
local BASE_SPACING = 8
local ICON_LIFETIME = 15
local SAFE_TIME = 2.5

local DEFAULT_SCALE = 1.0
local DRAG_PADDING = 16
local LOOT_SOUND_PATH = "Interface\\AddOns\\LootBlare\\assets\\notification.mp3"

local lastSoundTime = 0
local SOUND_COOLDOWN = 1.0

local QUALITY_COLORS = {
  [0] = "ff9d9d9d",
  [1] = "ffffffff",
  [2] = "ff1eff00",
  [3] = "ff0070dd",
  [4] = "ffa335ee",
  [5] = "ffff8000"
}

local lootItems = {}
local lootCount = 0
local currentScale = DEFAULT_SCALE

lootTrackerFrame = nil
lootTrackerCenter = nil

local isMoving = false

local scanner = CreateFrame("GameTooltip", "LootTrackerScanner", nil,
                            "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")

local function BuildItemLink(itemString)
  local name, _, quality = GetItemInfo(itemString)
  if not name then return nil end
  local hex = QUALITY_COLORS[quality or 1]
  return "|c" .. hex .. "|H" .. itemString .. "|h[" .. name .. "]|h|r"
end

local function initDB()
  LootTrackerDB.scale = LootTrackerDB.scale or DEFAULT_SCALE
  LootTrackerDB.horizontal = LootTrackerDB.horizontal ~= false
  LootTrackerDB.showText = LootTrackerDB.showText ~= false
  LootTrackerDB.soundEnabled = LootTrackerDB.soundEnabled ~= false

  LootTrackerDB.point = LootTrackerDB.point or "CENTER"
  LootTrackerDB.relativePoint = LootTrackerDB.relativePoint or "CENTER"
  LootTrackerDB.x = LootTrackerDB.x or 300
  LootTrackerDB.y = LootTrackerDB.y or 0
end

local function createLootRow(parent)
  local row = CreateFrame("Button", nil, parent)
  row:EnableMouse(true)

  row:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1
  })
  row:SetBackdropColor(0.08, 0.08, 0.08, 0.85)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.text:SetJustifyH("LEFT")

  row.highlight = row:CreateTexture(nil, "OVERLAY")
  row.highlight:SetAllPoints(row)
  row.highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  row.highlight:SetVertexColor(1, 1, 1, 0.12)
  row.highlight:Hide()

  row:SetScript("OnEnter", function()
    if not this.item then return end
    this.highlight:Show()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(this.item.itemString)
  end)

  row:SetScript("OnLeave", function()
    this.highlight:Hide()
    if GameTooltip:IsOwned(this) then GameTooltip:Hide() end
  end)

  row:SetScript("OnMouseDown", function()
    if not this.item then return end

    if IsShiftKeyDown() and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
      local link = BuildItemLink(this.item.itemString)
      if link then ChatFrameEditBox:Insert(link) end
    elseif IsControlKeyDown() and DressUpItemLink then
      DressUpItemLink(this.item.itemString)
    end
  end)

  return row
end

function updateLootTrackerLayout()
  if not lootTrackerFrame or lootCount == 0 then
    if lootTrackerFrame then lootTrackerFrame:Hide() end
    return
  end

  local size = BASE_ICON_SIZE * currentScale
  local spacing = BASE_SPACING * currentScale
  local pad = 6 * currentScale
  local textPad = 8 * currentScale

  local horizontal = LootTrackerDB.horizontal
  local showText = LootTrackerDB.showText

  lootTrackerFrame.rows = lootTrackerFrame.rows or {}

  for i = 1, lootCount do
    local item = lootItems[i]
    local row = lootTrackerFrame.rows[i]

    if not row then
      row = createLootRow(lootTrackerFrame)
      lootTrackerFrame.rows[i] = row
    end

    row:Show()
    row:SetAlpha(1)
    row:ClearAllPoints()

    row.item = item
    item.row = row

    local name, _, quality, _, _, _, _, _, tex = GetItemInfo(item.itemString)
    local r, g, b = GetItemQualityColor(quality or 1)

    row:SetBackdropBorderColor(r * 0.9, g * 0.9, b * 0.9)

    row.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.icon:SetWidth(size)
    row.icon:SetHeight(size)

    row.text:SetText(name or "Loading...")
    row.text:SetTextColor(r, g, b)

    local rowWidth, rowHeight
    if showText then
      row.text:Show()
      row.icon:SetPoint("LEFT", row, "LEFT", pad, 0)
      row.text:SetPoint("LEFT", row.icon, "RIGHT", textPad, 0)

      local textWidth = row.text:GetStringWidth()
      if textWidth < 40 then textWidth = 40 end

      rowWidth = size + textPad + textWidth + pad * 2
      rowHeight = size + pad * 2
    else
      row.text:Hide()
      row.icon:SetPoint("CENTER", row, "CENTER")
      rowWidth = size + pad * 2
      rowHeight = size + pad * 2
    end

    row:SetWidth(rowWidth)
    row:SetHeight(rowHeight)
  end

  local rowCount = getn(lootTrackerFrame.rows)
  for i = lootCount + 1, rowCount do lootTrackerFrame.rows[i]:Hide() end

  local total = 0
  for i = 1, lootCount do
    total = total + (horizontal and lootTrackerFrame.rows[i]:GetWidth() or
              lootTrackerFrame.rows[i]:GetHeight())
    if i < lootCount then total = total + spacing end
  end

  local cursor = -total / 2
  for i = 1, lootCount do
    local row = lootTrackerFrame.rows[i]
    if horizontal then
      row:SetPoint("LEFT", lootTrackerCenter, "CENTER", cursor, 0)
      cursor = cursor + row:GetWidth() + spacing
    else
      row:SetPoint("TOP", lootTrackerCenter, "CENTER", 0, -cursor)
      cursor = cursor + row:GetHeight() + spacing
    end
  end

  lootTrackerFrame:SetWidth((horizontal and total or
                              lootTrackerFrame.rows[1]:GetWidth()) +
                              DRAG_PADDING * 2)
  lootTrackerFrame:SetHeight((horizontal and
                               lootTrackerFrame.rows[1]:GetHeight() or total) +
                               DRAG_PADDING * 2)
  lootTrackerFrame:Show()
end

function addLootToTracker(itemString)
  if not itemString then return end
  if not lootTrackerFrame then initializeLootTracker() end

  table.insert(lootItems, {
    itemString = itemString,
    time = GetTime(),
    resolved = false,
    scanned = false
  })

  lootCount = lootCount + 1
  updateLootTrackerLayout()

  if LootTrackerDB.soundEnabled then
    local now = GetTime()
    if now - lastSoundTime >= SOUND_COOLDOWN then
      PlaySoundFile(LOOT_SOUND_PATH)
      lastSoundTime = now
    end
  end
end

local cleanup = CreateFrame("Frame")
cleanup:SetScript("OnUpdate", function()
  if isMoving then return end

  local now = GetTime()
  local needsUpdate = false

  for i = lootCount, 1, -1 do
    local item = lootItems[i]
    local row = item.row
    local elapsed = now - item.time

    if not item.resolved then
      if GetItemInfo(item.itemString) then
        item.resolved = true
        needsUpdate = true
      elseif not item.scanned then
        scanner:SetHyperlink(item.itemString)
        item.scanned = true
      end
    end

    if elapsed > ICON_LIFETIME then
      if row then row:Hide() end
      table.remove(lootItems, i)
      lootCount = lootCount - 1
      needsUpdate = true
    elseif row and elapsed > ICON_LIFETIME - SAFE_TIME then
      local t = (elapsed - (ICON_LIFETIME - SAFE_TIME)) / SAFE_TIME
      if t < 0 then t = 0 end
      if t > 1 then t = 1 end
      row:SetAlpha(1 - t)
    end
  end

  if needsUpdate then updateLootTrackerLayout() end
end)

function createLootTrackerFrame()
  initDB()

  lootTrackerCenter = CreateFrame("Frame", nil, UIParent)
  lootTrackerCenter:SetPoint(LootTrackerDB.point, UIParent,
                             LootTrackerDB.relativePoint, LootTrackerDB.x,
                             LootTrackerDB.y)
  lootTrackerCenter:SetWidth(1)
  lootTrackerCenter:SetHeight(1)
  lootTrackerCenter:SetMovable(true)
  lootTrackerCenter:SetClampedToScreen(true)

  local f = CreateFrame("Frame", nil, UIParent)
  f:SetPoint("CENTER", lootTrackerCenter)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:EnableMouseWheel(true)
  f:RegisterForDrag("LeftButton")

  f:SetScript("OnDragStart", function()
    isMoving = true
    lootTrackerCenter:StartMoving()
  end)

  f:SetScript("OnDragStop", function()
    isMoving = false
    lootTrackerCenter:StopMovingOrSizing()
    local p, _, rp, x, y = lootTrackerCenter:GetPoint()
    LootTrackerDB.point, LootTrackerDB.relativePoint = p, rp
    LootTrackerDB.x, LootTrackerDB.y = x, y
  end)

  f:SetScript("OnMouseWheel", function()
    if isMoving then return end
    if not arg1 then return end

    local step = 0.05
    local minScale, maxScale = 0.5, 2.0

    if arg1 > 0 then
      currentScale = currentScale + step
    else
      currentScale = currentScale - step
    end

    if currentScale < minScale then currentScale = minScale end
    if currentScale > maxScale then currentScale = maxScale end

    LootTrackerDB.scale = currentScale
    updateLootTrackerLayout()
  end)

  currentScale = LootTrackerDB.scale
  return f
end

function initializeLootTracker()
  if not lootTrackerFrame then lootTrackerFrame = createLootTrackerFrame() end
end
