-- save the original ChatFrame_OnEvent
local orig_ChatFrame_OnEvent = ChatFrame_OnEvent

local function is_friend(player_name)
  for i = 1, GetNumFriends() do
    local friend_name = GetFriendInfo(i)
    if friend_name == player_name then return true end
  end
  return false
end

local function ignore_message(event, arg1, arg2, arg3, arg4)
  if event == 'CHAT_MSG_WHISPER' then
    if is_friend(arg2) then return false end
    if Settings.DNDMode and is_master_looter(UnitName("player")) then
      return true
    end
    return false
  end
end

-- overwite the ChatFrame_OnEvent function with custom filter function
ChatFrame_OnEvent = function(event)
  if not ignore_message(event, arg1, arg2, arg3, arg4) then
    orig_ChatFrame_OnEvent(event)
  end
end
