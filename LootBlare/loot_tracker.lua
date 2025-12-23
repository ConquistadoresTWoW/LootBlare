LootTrackerDB = LootTrackerDB or {}

local BASE_ICON_SIZE = 34
local BASE_SPACING = 8
local ICON_LIFETIME = 15
local REMOVE_FADE_TIME = 0.4

local SCALE_MIN = 0.4
local SCALE_MAX = 2.0
local SCALE_STEP = 0.1
local DEFAULT_SCALE = 1.0

local lootItems = {}
local lootCount = 0
local currentScale = DEFAULT_SCALE

lootTrackerFrame = nil
lootTrackerCenter = nil

local function initDB()
  LootTrackerDB.scale = LootTrackerDB.scale or DEFAULT_SCALE
  LootTrackerDB.horizontal = LootTrackerDB.horizontal ~= false

  if LootTrackerDB.showText == nil then LootTrackerDB.showText = true end

  LootTrackerDB.point = LootTrackerDB.point or "CENTER"
  LootTrackerDB.relativePoint = LootTrackerDB.relativePoint or "CENTER"
  LootTrackerDB.x = LootTrackerDB.x or 300
  LootTrackerDB.y = LootTrackerDB.y or 0
end

local function buildItemLink(item)
  if item.realLink or not item.itemID then return end

  local name, _, quality = GetItemInfo(item.itemID)
  if not name then return end

  local r, g, b = GetItemQualityColor(quality or 1)
  local color = string.format("ff%02x%02x%02x", r * 255, g * 255, b * 255)

  item.realLink = "|c" .. color .. "|Hitem:" .. item.itemID .. "|h[" .. name ..
                    "]|h|r"
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
    GameTooltip:Show()
  end)

  row:SetScript("OnLeave", function()
    this.highlight:Hide()
    GameTooltip:Hide()
  end)

  row:SetScript("OnClick", function()
    if not this.item then return end
    buildItemLink(this.item)

    if IsShiftKeyDown() and this.item.realLink then
      if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
        ChatFrameEditBox:Insert(this.item.realLink)
      else
        ChatFrame_OpenChat(this.item.realLink)
      end
    elseif IsControlKeyDown() then
      DressUpItemLink(this.item.itemString)
    end
  end)

  return row
end

function updateLootTrackerLayout()
  if not lootTrackerFrame or lootCount == 0 then
    lootTrackerFrame:Hide()
    return
  end

  local size = BASE_ICON_SIZE * currentScale
  local spacing = BASE_SPACING * currentScale
  local pad = 6 * currentScale
  local textPad = 8 * currentScale
  local horizontal = LootTrackerDB.horizontal
  local showText = LootTrackerDB.showText == true

  lootTrackerFrame.rows = lootTrackerFrame.rows or {}

  for i = 1, lootCount do
    local item = lootItems[i]
    local row = lootTrackerFrame.rows[i]

    if not row then
      row = createLootRow(lootTrackerFrame)
      lootTrackerFrame.rows[i] = row
    end

    row.item = item
    item.icon = row

    local name, _, quality = GetItemInfo(item.itemID)
    local r, g, b = GetItemQualityColor(quality or 1)

    row.icon:SetWidth(size)
    row.icon:SetHeight(size)
    row.icon:ClearAllPoints()

    row.text:SetText(name or "Unknown")
    row.text:SetTextColor(r, g, b)
    row.text:ClearAllPoints()

    local rowWidth, rowHeight

    if showText then
      row.text:Show()
      row.icon:SetPoint("LEFT", row, "LEFT", pad, 0)
      row.text:SetPoint("LEFT", row.icon, "RIGHT", textPad, 0)

      local textWidth = row.text:GetStringWidth() or 0
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
    row:SetAlpha(item.alpha or 1)
    row:SetBackdropBorderColor(r * 0.9, g * 0.9, b * 0.9, 1)

    local _, _, _, _, _, _, _, _, tex = GetItemInfo(item.itemID)
    row.icon:SetTexture(tex)

    row:Show()
  end

  local total = 0
  for i = 1, lootCount do
    local r = lootTrackerFrame.rows[i]
    total = total + (horizontal and r:GetWidth() or r:GetHeight())
    if i < lootCount then total = total + spacing end
  end

  local cursor = -total / 2
  for i = 1, lootCount do
    local row = lootTrackerFrame.rows[i]
    row:ClearAllPoints()

    if horizontal then
      row:SetPoint("LEFT", lootTrackerCenter, "CENTER", cursor, 0)
      cursor = cursor + row:GetWidth() + spacing
    else
      row:SetPoint("TOP", lootTrackerCenter, "CENTER", 0, -cursor)
      cursor = cursor + row:GetHeight() + spacing
    end
  end

  for i = lootCount + 1, getn(lootTrackerFrame.rows) do
    lootTrackerFrame.rows[i]:Hide()
  end

  lootTrackerFrame:SetWidth(horizontal and total or
                              lootTrackerFrame.rows[1]:GetWidth())
  lootTrackerFrame:SetHeight(
    horizontal and lootTrackerFrame.rows[1]:GetHeight() or total)

  lootTrackerFrame:Show()
end

function addLootToTracker(itemString)
  if not Settings or not Settings.LootTrackerEnabled then return end
  if not lootTrackerFrame then initializeLootTracker() end

  local itemID = tonumber(string_match(itemString, "item:(%d+)"))

  table.insert(lootItems, {
    itemString = itemString,
    itemID = itemID,
    time = GetTime(),
    alpha = 1
  })

  lootCount = lootCount + 1
  updateLootTrackerLayout()
end

local cleanup = CreateFrame("Frame")
cleanup:SetScript("OnUpdate", function()
  local elapsed = arg1
  if not elapsed then return end

  local now = GetTime()

  for i = lootCount, 1, -1 do
    local item = lootItems[i]
    if now - item.time > ICON_LIFETIME then
      item.alpha = item.alpha - (elapsed / REMOVE_FADE_TIME)
      if item.icon then item.icon:SetAlpha(item.alpha) end
      if item.alpha <= 0 then
        table.remove(lootItems, i)
        lootCount = lootCount - 1
        updateLootTrackerLayout()
      end
    end
  end
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

  local f = CreateFrame("Frame", nil, UIParent)
  f:SetPoint("CENTER", lootTrackerCenter, "CENTER")
  f:SetWidth(1)
  f:SetHeight(1)
  f:SetClampedToScreen(true)

  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")

  f:SetScript("OnDragStart", function() lootTrackerCenter:StartMoving() end)

  f:SetScript("OnDragStop", function()
    lootTrackerCenter:StopMovingOrSizing()
    local p, _, rp, x, y = lootTrackerCenter:GetPoint()
    LootTrackerDB.point = p
    LootTrackerDB.relativePoint = rp
    LootTrackerDB.x = x
    LootTrackerDB.y = y
  end)

  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function()
    local delta = arg1
    currentScale = math.max(SCALE_MIN, math.min(SCALE_MAX, currentScale +
                                                  (delta > 0 and SCALE_STEP or
                                                    -SCALE_STEP)))
    LootTrackerDB.scale = currentScale
    updateLootTrackerLayout()
  end)

  f:Hide()
  currentScale = LootTrackerDB.scale
  return f
end

function initializeLootTracker()
  if not lootTrackerFrame then lootTrackerFrame = createLootTrackerFrame() end
end
