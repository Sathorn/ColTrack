local HBDpins = LibStub("HereBeDragons-Pins-2.0", true)

local provider = {}
local frame = CreateFrame("Frame")
local pool = {}
local used = {}
local enabled = false
local warnedMissing = false

local ICON_RECTS = {
  fish = { x = 928, y = 517, w = 32, h = 32 },
  herb = { x = 963, y = 520, w = 32, h = 32 },
  ore = { x = 520, y = 554, w = 32, h = 32 },
  lumber = { x = 928, y = 453, w = 32, h = 32 },
}

local SPECIAL_REPLACEMENTS = {
  ["shiny trash can"] = "lumber",
  ["overflowing dumpster"] = "ore",
  ["overflowing dampster"] = "ore",
}

local SPECIAL_ATLAS_REPLACEMENTS = {
  ["VignetteLoot"] = "ore",
}

local function TexCoord(rect)
  local inset = 0.5
  local u1 = (rect.x + inset) / 1024
  local v1 = (rect.y + inset) / 1024
  local u2 = (rect.x + rect.w - inset) / 1024
  local v2 = (rect.y + rect.h - inset) / 1024
  return u1, u2, v1, v2
end

local function ClearPins()
  if HBDpins then
    HBDpins:RemoveAllMinimapIcons(provider)
  end
  for i = 1, #used do
    local icon = used[i]
    icon:Hide()
    pool[#pool + 1] = icon
  end
  wipe(used)
end

local function AcquireIcon()
  local icon = tremove(pool)
  if icon then
    return icon
  end

  icon = CreateFrame("Frame", nil, Minimap)
  icon:SetFrameStrata("TOOLTIP")
  icon:SetFrameLevel(9999)
  icon:SetSize(16, 16)
  icon:SetPoint("CENTER", Minimap, "CENTER")
  local texture = icon:CreateTexture(nil, "OVERLAY")
  icon.texture = texture
  texture:SetAllPoints(icon)
  texture:SetTexelSnappingBias(0)
  texture:SetSnapToPixelGrid(false)
  return icon
end

local function Classify(info)
  local name = strlower((info and info.name) or "")
  local replacement = SPECIAL_REPLACEMENTS[name]
  if replacement then
    if name:find("trash can") then
      return replacement, false, "trashcan"
    end
    if name:find("dumpster") or name:find("dampster") then
      return replacement, false, "dumpster"
    end
    return replacement, false, nil
  end

  local atlasReplacement = info and SPECIAL_ATLAS_REPLACEMENTS[info.atlasName]
  if atlasReplacement then
    return atlasReplacement, false, "treasure"
  end

  local s = name .. " " .. strlower((info and info.atlasName) or "")
  s = strlower(s)

  -- Undermine treasure/object vignettes that are not standard gather-node words.
  if s:find("trash") or s:find("can") or s:find("dumpster") or s:find("dampster")
    or s:find("cache") or s:find("chest") or s:find("crate") or s:find("scrap") then
    return "ore", false, "treasure"
  end

  if s:find("fish") or s:find("pool") or s:find("shoal") then
    return "fish", false, nil
  end
  if s:find("herb") or s:find("flower") or s:find("bloom") or s:find("spore") then
    return "herb", false, nil
  end
  if s:find("ore") or s:find("deposit") or s:find("seam") then
    return "ore", false, nil
  end
  if s:find("wood") or s:find("lumber") or s:find("timber") or s:find("log") then
    return "lumber", false, nil
  end
  return nil, false, nil
end

local function Refresh()
  if not enabled then
    return
  end
  if not HBDpins then
    if not warnedMissing then
      warnedMissing = true
      print("ColTrack: HereBeDragons-Pins-2.0 not found, vignette overlay disabled.")
    end
    return
  end

  local getColors = _G.ColTrack_GetCurrentPresetColors
  local colors = getColors and getColors()
  if not colors then
    return
  end

  local mapID = C_Map.GetBestMapForUnit("player")
  if not mapID then
    ClearPins()
    return
  end

  ClearPins()

  local vignettes = C_VignetteInfo.GetVignettes() or {}
  for i = 1, #vignettes do
    local id = vignettes[i]
    local info = C_VignetteInfo.GetVignetteInfo(id)
    if info and info.onMinimap and info.atlasName then
      local key, useReplacement, customKind = Classify(info)
      if not key then
        -- Temporary broad fallback: tint any vignette not explicitly classified.
        key = "ore"
      end
      local color
      local getCustom = _G.ColTrack_GetUndermineVignetteColor
      if customKind and getCustom then
        color = getCustom(customKind)
      end
      if not color then
        color = key and colors[key]
      end
      if color then
        local pos = C_VignetteInfo.GetVignettePosition(id, mapID)
        if pos then
          local icon = AcquireIcon()
          if useReplacement then
            local getTex = _G.ColTrack_GetCurrentPresetTexture
            local presetTex = getTex and getTex()
            local rect = ICON_RECTS[key] or ICON_RECTS.ore
            icon.texture:SetAtlas(nil)
            icon.texture:SetTexture(presetTex)
            icon.texture:SetTexCoord(TexCoord(rect))
            if icon.texture.SetDesaturated then
              icon.texture:SetDesaturated(false)
            end
            icon.texture:SetVertexColor(1, 1, 1, 1)
          else
            icon.texture:SetAtlas(info.atlasName)
            icon.texture:SetTexCoord(0, 1, 0, 1)
            if icon.texture.SetDesaturated then
              icon.texture:SetDesaturated(true)
            end
            icon.texture:SetVertexColor(color[1], color[2], color[3], 1)
          end
          icon:Show()
          HBDpins:AddMinimapIconMap(provider, icon, mapID, pos.x, pos.y, true, true)
          used[#used + 1] = icon
        end
      end
    end
  end

end

function _G.ColTrackVignetteOverlay_Refresh()
  if enabled then
    Refresh()
  end
end

function _G.ColTrackVignetteOverlay_SetEnabled(v)
  enabled = v and true or false
  if enabled then
    frame:RegisterEvent("VIGNETTES_UPDATED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("MINIMAP_UPDATE_TRACKING")
    Refresh()
  else
    frame:UnregisterEvent("VIGNETTES_UPDATED")
    frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:UnregisterEvent("MINIMAP_UPDATE_TRACKING")
    ClearPins()
  end
end

frame:SetScript("OnEvent", function()
  if enabled then
    Refresh()
  end
end)
