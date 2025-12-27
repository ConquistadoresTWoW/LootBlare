item_roll_frame = create_item_roll_frame()
item_roll_frame:RegisterEvent('ADDON_LOADED')
item_roll_frame:RegisterEvent('CHAT_MSG_SYSTEM')
item_roll_frame:RegisterEvent('CHAT_MSG_RAID_WARNING')
item_roll_frame:RegisterEvent('CHAT_MSG_RAID')
item_roll_frame:RegisterEvent('CHAT_MSG_RAID_LEADER')
item_roll_frame:RegisterEvent('CHAT_MSG_ADDON')
item_roll_frame:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')
item_roll_frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
item_roll_frame:RegisterEvent('LOOT_OPENED')
item_roll_frame:RegisterEvent('CHAT_MSG_WHISPER')
item_roll_frame:RegisterEvent('GUILD_ROSTER_UPDATE')
item_roll_frame:SetScript('OnEvent', function()
  handle_chat_message(event, arg1, arg2, arg3, arg4)
end)

import_sr_frame = create_import_sr_frame()
settings_frame = create_settings_frame()

-- Initialize Loot Tracker
local function initAll()
  if createLootTrackerFrame and initializeLootTracker then
    if not lootTrackerFrame then lootTrackerFrame = createLootTrackerFrame() end
    initializeLootTracker()
  end
end

local initFrame = CreateFrame("Frame")
initFrame:SetScript("OnUpdate", function()
  this:SetScript("OnUpdate", nil) -- Run once
  initAll()
end)

-- Register the slash command
SLASH_LOOTBLARE1 = '/lootblare'
SLASH_LOOTBLARE2 = '/lb'

-- Command handler
SlashCmdList['LOOTBLARE'] = handle_config_command
