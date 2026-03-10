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

-- ─── Auto-roll queue ────────────────────────────────────────────────────────
-- Maps itemId (number) → queued roll type ("MS", "OS", "TM", or nil)
-- Using item ID as the key means the queue survives any link-format differences
-- between what the tracker stores and what the ML raid-warning produces.
local autoRollQueue = {}

-- Helper: pull the numeric item ID out of any item link or plain itemString
local function extractItemId(str)
  if not str then return nil end
  return tonumber(string_match(str, "item:(%d+)"))
end

-- Roll-type configuration
local ROLL_TYPES = {
  { key = "MS", max = 100, label = "MS", activeR = 1,   activeG = 0.45, activeB = 0,   inactiveR = 0.25, inactiveG = 0.12, inactiveB = 0.0  },
  { key = "OS", max = 99,  label = "OS", activeR = 0,   activeG = 0.8,  activeB = 0,   inactiveR = 0.0,  inactiveG = 0.20, inactiveB = 0.0  },
  { key = "TM", max = 50,  label = "TM", activeR = 0,   activeG = 0.7,  activeB = 0.9, inactiveR = 0.0,  inactiveG = 0.18, inactiveB = 0.22 },
}

local ROLL_BTN_W  = 28
local ROLL_BTN_H  = 13
local ROLL_BTN_GAP = 3

-- Update the visual state of the three roll buttons on a row
local function refreshRollButtons(row)
  if not row or not row.item then return end
  local itemId = extractItemId(row.item.itemString)
  local queued = itemId and autoRollQueue[itemId]
  for _, btn in ipairs(row.rollBtns or {}) do
    local rt = btn.rollType
    local isActive = (queued == rt.key)
    if isActive then
      btn:SetBackdropColor(rt.activeR, rt.activeG, rt.activeB, 0.90)
      btn:SetBackdropBorderColor(rt.activeR * 1.4, rt.activeG * 1.4, rt.activeB * 1.4, 1)
      btn.label:SetTextColor(1, 1, 1, 1)
    else
      btn:SetBackdropColor(rt.inactiveR, rt.inactiveG, rt.inactiveB, 0.75)
      btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
      btn.label:SetTextColor(0.6, 0.6, 0.6, 1)
    end
  end
end

-- Called from chat_handler when LB_START_ROLL arrives.
-- itemId is the plain numeric ID embedded in the addon message.
function triggerQueuedRoll(itemId)
  if not itemId then return end
  itemId = tonumber(itemId)
  if not itemId then return end

  local queuedType = autoRollQueue[itemId]
  if not queuedType then return end

  -- Find the max roll for this type
  local maxRoll = 100
  for _, rt in ipairs(ROLL_TYPES) do
    if rt.key == queuedType then maxRoll = rt.max end
  end

  -- Clear the queue entry immediately so it can't double-fire
  autoRollQueue[itemId] = nil

  -- Refresh buttons on any tracker row showing this item
  if lootTrackerFrame and lootTrackerFrame.rows then
    for _, row in ipairs(lootTrackerFrame.rows) do
      if row.item and extractItemId(row.item.itemString) == itemId then
        refreshRollButtons(row)
      end
    end
  end

  -- Fire after a random 1–3 second delay
  local delay = 1.0 + math.random() * 2.0
  local elapsed = 0
  local fireFrame = CreateFrame("Frame")
  fireFrame:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed >= delay then
      this:SetScript("OnUpdate", nil)
      RandomRoll(1, maxRoll)
    end
  end)
end
-- ─────────────────────────────────────────────────────────────────────────────

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

local function createRollButton(parent, rollType)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(ROLL_BTN_W)
  btn:SetHeight(ROLL_BTN_H)
  btn:EnableMouse(true)
  btn.rollType = rollType

  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
  })
  btn:SetBackdropColor(rollType.inactiveR, rollType.inactiveG, rollType.inactiveB, 0.75)
  btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

  btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btn.label:SetAllPoints(btn)
  btn.label:SetJustifyH("CENTER")
  btn.label:SetJustifyV("MIDDLE")
  btn.label:SetText(rollType.label)
  btn.label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  btn.label:SetTextColor(0.6, 0.6, 0.6, 1)

  btn:SetScript("OnClick", function()
    local strip = this:GetParent()
    local row = strip and strip.row
    if not row or not row.item then return end
    local itemId = extractItemId(row.item.itemString)
    if not itemId then return end
    local rt = this.rollType

    if autoRollQueue[itemId] == rt.key then
      autoRollQueue[itemId] = nil
    else
      autoRollQueue[itemId] = rt.key
    end

    refreshRollButtons(row)
  end)

  -- Tooltip on hover
  btn:SetScript("OnEnter", function()
    local rt = this.rollType
    local strip = this:GetParent()
    local row = strip and strip.row
    local itemId = row and row.item and extractItemId(row.item.itemString)
    local queued = itemId and autoRollQueue[itemId]

    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    if queued == rt.key then
      GameTooltip:SetText("|cFFFFFF00" .. rt.label .. " roll queued|r\nClick to cancel", nil, nil, nil, nil, 1)
    else
      GameTooltip:SetText("Queue |cFFFFFF00" .. rt.label .. "|r roll (1/" .. rt.max .. ")\nWill auto-roll when ML opens this item", nil, nil, nil, nil, 1)
    end
    GameTooltip:Show()
  end)

  btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return btn
end

local function createRollButtonStrip()
  local strip = CreateFrame("Frame", nil, UIParent)
  strip:SetFrameStrata("HIGH")
  strip:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1,
  })
  strip:SetBackdropColor(0.05, 0.05, 0.05, 0.90)
  strip:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.9)

  strip.btns = {}
  for i, rt in ipairs(ROLL_TYPES) do
    local btn = createRollButton(strip, rt)
    strip.btns[i] = btn
  end

  strip:Hide()
  return strip
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

  -- Button strip is a separate frame floating below this row
  row.rollStrip = createRollButtonStrip()
  -- Keep a back-reference so buttons can find their row
  row.rollStrip.row = row
  -- Alias so refreshRollButtons still works
  row.rollBtns = row.rollStrip.btns

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

  local size     = BASE_ICON_SIZE * currentScale
  local spacing  = BASE_SPACING * currentScale
  local pad      = 6 * currentScale
  local textPad  = 8 * currentScale
  local btnH     = ROLL_BTN_H * currentScale
  local btnW     = ROLL_BTN_W * currentScale
  local btnGap   = ROLL_BTN_GAP * currentScale
  local numRollTypes = getn(ROLL_TYPES)

  local horizontal = LootTrackerDB.horizontal
  local showText   = LootTrackerDB.showText

  lootTrackerFrame.rows = lootTrackerFrame.rows or {}

  for i = 1, lootCount do
    local item = lootItems[i]
    local row  = lootTrackerFrame.rows[i]

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

    -- Button strip sits outside/below the row, anchored to its bottom
    local totalBtnW = numRollTypes * btnW + (numRollTypes - 1) * btnGap
    local stripPad  = 3 * currentScale

    local rowWidth, rowHeight

    if showText then
      row.text:Show()
      row.icon:SetPoint("LEFT", row, "LEFT", pad, 0)
      row.text:SetPoint("LEFT", row.icon, "RIGHT", textPad, 0)

      local textWidth = row.text:GetStringWidth()
      if textWidth < 40 then textWidth = 40 end

      rowWidth  = size + textPad + textWidth + pad * 2
      rowHeight = size + pad * 2
    else
      row.text:Hide()
      row.icon:SetPoint("CENTER", row, "CENTER", 0, 0)

      rowWidth  = size + pad * 2
      rowHeight = size + pad * 2
    end

    -- Make sure row is wide enough for the button strip
    if rowWidth < totalBtnW + pad * 2 then rowWidth = totalBtnW + pad * 2 end

    row:SetWidth(rowWidth)
    row:SetHeight(rowHeight)

    -- Position and size the floating button strip below the row
    local strip = row.rollStrip
    strip:ClearAllPoints()
    strip:SetPoint("TOP", row, "BOTTOM", 0, -2)
    strip:SetWidth(totalBtnW + stripPad * 2)
    strip:SetHeight(btnH + stripPad * 2)
    strip:Show()
    strip:SetAlpha(row:GetAlpha())

    for j, btn in ipairs(strip.btns) do
      btn:SetWidth(btnW)
      btn:SetHeight(btnH)
      btn:ClearAllPoints()
      btn:SetPoint("LEFT", strip, "LEFT", stripPad + (j - 1) * (btnW + btnGap), 0)
    end

    refreshRollButtons(row)
  end

  local rowCount = getn(lootTrackerFrame.rows)
  for i = lootCount + 1, rowCount do
    lootTrackerFrame.rows[i]:Hide()
    if lootTrackerFrame.rows[i].rollStrip then
      lootTrackerFrame.rows[i].rollStrip:Hide()
    end
  end

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
  if Settings.LootTrackerEnabled == false then return end

  table.insert(lootItems, {
    itemString = itemString,
    time       = GetTime(),
    resolved   = false,
    scanned    = false
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
    local item    = lootItems[i]
    local row     = item.row
    local elapsed = now - item.time

    if not item.resolved then
      if GetItemInfo(item.itemString) then
        item.resolved = true
        needsUpdate   = true
      elseif not item.scanned and not (LootFrame and LootFrame:IsShown()) then
        scanner:SetHyperlink(item.itemString)
        item.scanned = true
      end
    end

    if elapsed > ICON_LIFETIME then
      -- Clean up any queued roll for this item when it expires
      local itemId = extractItemId(item.itemString)
      if itemId then autoRollQueue[itemId] = nil end
      if row then
        row:Hide()
        if row.rollStrip then row.rollStrip:Hide() end
      end
      table.remove(lootItems, i)
      lootCount     = lootCount - 1
      needsUpdate   = true
    elseif row and elapsed > ICON_LIFETIME - SAFE_TIME then
      local t = (elapsed - (ICON_LIFETIME - SAFE_TIME)) / SAFE_TIME
      if t < 0 then t = 0 end
      if t > 1 then t = 1 end
      row:SetAlpha(1 - t)
      if row.rollStrip then row.rollStrip:SetAlpha(1 - t) end
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
