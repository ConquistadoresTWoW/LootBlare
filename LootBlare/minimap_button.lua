local minimap_button = CreateFrame("Button", "minimap_button", Minimap)
minimap_button:SetHeight(32)
minimap_button:SetWidth(32)
minimap_button:SetFrameStrata("MEDIUM")
minimap_button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
minimap_button:SetMovable(true)

minimap_button.texture = minimap_button:CreateTexture(nil, "BACKGROUND")
minimap_button.texture:SetTexture("Interface\\AddOns\\LootBlare\\assets\\icon")
minimap_button.texture:SetHeight(20)
minimap_button.texture:SetWidth(20)
minimap_button.texture:SetPoint("CENTER", minimap_button, "CENTER", 0, 0)

-- border
minimap_button.border = minimap_button:CreateTexture(nil, "OVERLAY")
minimap_button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimap_button.border:SetHeight(54)
minimap_button.border:SetWidth(54)
minimap_button.border:SetPoint("TOPLEFT", minimap_button, "TOPLEFT", 0, 0)

-- highlight
minimap_button.highlight = minimap_button:CreateTexture(nil, "HIGHLIGHT")
minimap_button.highlight:SetTexture(
  "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimap_button.highlight:SetBlendMode("ADD")
minimap_button.highlight:SetHeight(32)
minimap_button.highlight:SetWidth(32)
minimap_button.highlight:SetPoint("CENTER", minimap_button, "CENTER", 0, 0)

-- set the minimap button to be draggable
minimap_button:SetMovable(true)
minimap_button:EnableMouse(true)
minimap_button:RegisterForDrag("LeftButton")
minimap_button:SetScript("OnDragStart",
                         function() minimap_button:StartMoving() end)
minimap_button:SetScript("OnDragStop",
                         function() minimap_button:StopMovingOrSizing() end)

-- open or close the main frame
minimap_button:SetScript("OnClick", function()
  if item_roll_frame:IsShown() then
    item_roll_frame:Hide()
  else
    item_roll_frame:Show()
  end
end)

-- tooltip 
minimap_button:SetScript("OnEnter", function()
  GameTooltip:SetOwner(minimap_button, "ANCHOR_LEFT")
  GameTooltip:SetText("LootBlare", 1, 1, 1)
  GameTooltip:AddLine("Click to toggle main frame", nil, nil, nil, 1)
  GameTooltip:Show()
end)

minimap_button:SetScript("OnLeave", function() GameTooltip:Hide() end)
