itemRollFrame = CreateItemRollFrame()
itemRollFrame:RegisterEvent('ADDON_LOADED')
itemRollFrame:RegisterEvent('CHAT_MSG_SYSTEM')
itemRollFrame:RegisterEvent('CHAT_MSG_RAID_WARNING')
itemRollFrame:RegisterEvent('CHAT_MSG_RAID')
itemRollFrame:RegisterEvent('CHAT_MSG_RAID_LEADER')
itemRollFrame:RegisterEvent('CHAT_MSG_ADDON')
itemRollFrame:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')
itemRollFrame:SetScript('OnEvent',
                        function() HandleChatMessage(event, arg1, arg2) end)

-- Register the slash command
SLASH_LOOTBLARE1 = '/lootblare'
SLASH_LOOTBLARE2 = '/lb'

-- Command handler
SlashCmdList['LOOTBLARE'] = handle_config_command
