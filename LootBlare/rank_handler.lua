lb_guild_info = {}
function lb_load_guild_info()
  GuildRoster() -- Request guild roster update

  for i = 1, GetNumGuildMembers(true) do
    local name, rank, rankIndex = GetGuildRosterInfo(i)
	if not name then break end
    -- ranks start at 0
    lb_guild_info[name] = rankIndex
  end
end

function lb_get_player_rank(player_name)
  if lb_guild_info[player_name] then
    return lb_guild_info[player_name]
  else
    return nil -- Player not found in guild
  end
end

function lb_is_high_rank(player_name)
  local rankIndex = lb_get_player_rank(player_name)
  if rankIndex and rankIndex <= 4 then
    return true
  else
    return false
  end
end

-- /run print(tostring(lb_is_high_rank("Segismundo")))
-- /run print(lb_get_player_rank("Segismundo"))
