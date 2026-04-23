local ADDON = ...
local BASE = "Interface\\Minimap\\ObjectIconsAtlas"
local ICON = "Interface\\AddOns\\ColTrack\\Images\\logIcon.tga"
local CUSTOM_ATLAS_TOC = 120005

local rootPanel
local category
local presetsPanel
local minimapOptionsPanel
local profilesPanel
local vignettesPanel
local profileDropdown
local presetDropdown
local ldbObject
local presetPreviewButtons = {}
local overlayLoadWarned
local atlasCompatibilityWarned
local probeEnabled
local probeHooked
local probeLastText
local probeLastAt

local UNDERMINE_MAP_IDS = {
  -- Keep both parent/child IDs when known to handle micro-dungeons.
  [2346] = true,
  [2347] = true,
}

local UNDERMINE_VIGNETTE_FALLBACK = {
  trashcan = "lumber",
  dumpster = "ore",
  treasure = "ore",
}

-- Add your atlas files here (no extension)
local PRESETS = {
  {
    label = "Base (Blizzard)",
    tex = BASE,
  },
  {
    label = "Fish Pink / Herb Green / Ore Blue / Lumber Yellow",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishPink_herbGreen_oreBlue_lumberYellow",
  },
  {
    label = "Vivid: Fish Hot Pink / Herb Lime / Ore Blue / Lumber Yellow",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid_fishHotPink_herbLime_oreBlue_lumberYellow",
  },
  {
    label = "Vivid: Fish Yellow / Herb Green / Ore Blue / Lumber Pink",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishYellow_herbGreen_oreBlue_lumberPink_vivid",
  },
  {
    label = "Fish Blue / Herb Green / Ore Yellow / Lumber Pink",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishBlue_herbGreen_oreYellow_lumberPink",
  },
  {
    label = "Vivid: Fish Blue / Herb Lime / Ore Yellow / Lumber Hot Pink",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishBlue_herbLime_oreYellow_lumberHotPink",
  },
  {
    label = "Deuteranomaly",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_deuteranomaly",
  },
  {
    label = "Deuteranopia",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_deuteranopia",
  },
  {
    label = "Protanopia",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_protanopia",
  },
  {
    label = "Tritanopia",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_tritanopia",
  },
  {
    label = "White Outline / Black Fill",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_outlineWhite_fillBlack",
  },
}

local LEGACY_TEX_MAP = {
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_colorblindRG"] = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_deuteranopia",
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_colorblindBY"] = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_tritanopia",
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_colorblindCommunity"] = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_deuteranomaly",
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid_blp"] = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid_fishHotPink_herbLime_oreBlue_lumberYellow",
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid"] = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid_fishHotPink_herbLime_oreBlue_lumberYellow",
}

local VALID_TEX = {}
for _, p in ipairs(PRESETS) do
  VALID_TEX[p.tex] = true
end

local function NormalizeTex(tex)
  tex = LEGACY_TEX_MAP[tex] or tex
  if VALID_TEX[tex] then
    return tex
  end
  return BASE
end

local function GetCurrentTocVersion()
  local tocVersion = select(4, GetBuildInfo())
  return tonumber(tocVersion) or 0
end

local function IsCustomAtlasCompatible()
  local tocVersion = GetCurrentTocVersion()
  return tocVersion > 0 and tocVersion <= CUSTOM_ATLAS_TOC
end

local function GetAllowUnsupportedAtlas()
  ColTrackDB = ColTrackDB or {}
  if ColTrackDB.allowUnsupportedAtlas == nil then
    ColTrackDB.allowUnsupportedAtlas = false
  end
  return ColTrackDB.allowUnsupportedAtlas
end

local function SetAllowUnsupportedAtlas(v)
  ColTrackDB = ColTrackDB or {}
  ColTrackDB.allowUnsupportedAtlas = v and true or false
end

local function Apply(tex)
  if Minimap and Minimap.SetBlipTexture then
    if tex ~= BASE and not IsCustomAtlasCompatible() and not GetAllowUnsupportedAtlas() then
      if not atlasCompatibilityWarned then
        atlasCompatibilityWarned = true
        print(("ColTrack: custom tracking presets are disabled for this WoW client because Blizzard changed the minimap icon atlas after %s. Using Base (Blizzard) to avoid corrupting unrelated icons."):format(CUSTOM_ATLAS_TOC))
      end
      Minimap:SetBlipTexture(BASE)
      return
    end
    Minimap:SetBlipTexture(tex)
  end
end

local function HexToRGB(h)
  h = h:gsub("^#", "")
  local r = tonumber(h:sub(1, 2), 16) or 255
  local g = tonumber(h:sub(3, 4), 16) or 255
  local b = tonumber(h:sub(5, 6), 16) or 255
  return r / 255, g / 255, b / 255
end

local PRESET_COLORS = {
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishPink_herbGreen_oreBlue_lumberYellow"] = {
    fish = { HexToRGB("#FF69B4") },
    herb = { HexToRGB("#3ECF3E") },
    ore = { HexToRGB("#238DF7") },
    lumber = { HexToRGB("#CFAF08") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishBlue_herbGreen_oreYellow_lumberPink"] = {
    fish = { HexToRGB("#238DF7") },
    herb = { HexToRGB("#3ECF3E") },
    ore = { HexToRGB("#CFAF08") },
    lumber = { HexToRGB("#FF69B4") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid"] = {
    fish = { HexToRGB("#FF00A0") },
    herb = { HexToRGB("#35FF00") },
    ore = { HexToRGB("#0091FF") },
    lumber = { HexToRGB("#FDFF00") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid_fishHotPink_herbLime_oreBlue_lumberYellow"] = {
    fish = { HexToRGB("#FF00A0") },
    herb = { HexToRGB("#35FF00") },
    ore = { HexToRGB("#0091FF") },
    lumber = { HexToRGB("#FDFF00") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishYellow_herbGreen_oreBlue_lumberPink_vivid"] = {
    fish = { HexToRGB("#FDFF00") },
    herb = { HexToRGB("#35FF00") },
    ore = { HexToRGB("#0091FF") },
    lumber = { HexToRGB("#FF00A0") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishBlue_herbLime_oreYellow_lumberHotPink"] = {
    fish = { HexToRGB("#0091FF") },
    herb = { HexToRGB("#35FF00") },
    ore = { HexToRGB("#FDFF00") },
    lumber = { HexToRGB("#FF00A0") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_deuteranomaly"] = {
    fish = { HexToRGB("#0C7BDC") },
    herb = { HexToRGB("#40B0A6") },
    ore = { HexToRGB("#FFC20A") },
    lumber = { HexToRGB("#D41159") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_deuteranopia"] = {
    fish = { HexToRGB("#1A85FF") },
    herb = { HexToRGB("#00A087") },
    ore = { HexToRGB("#FEFE62") },
    lumber = { HexToRGB("#E76BF3") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_protanopia"] = {
    fish = { HexToRGB("#006CD1") },
    herb = { HexToRGB("#40B0A6") },
    ore = { HexToRGB("#FFC20A") },
    lumber = { HexToRGB("#5D3A9B") },
  },
  ["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_cb_tritanopia"] = {
    fish = { HexToRGB("#005AB5") },
    herb = { HexToRGB("#29AF7F") },
    ore = { HexToRGB("#E1BE6A") },
    lumber = { HexToRGB("#8E5DCC") },
  },
}

local function GetUseGlobal()
  ColTrackDB = ColTrackDB or {}
  if ColTrackDB.useGlobal == nil then
    ColTrackDB.useGlobal = true
  end
  return ColTrackDB.useGlobal
end

local function SetUseGlobal(v)
  ColTrackDB = ColTrackDB or {}
  ColTrackDB.useGlobal = v and true or false
end

local function MinimapConfig()
  ColTrackDB = ColTrackDB or {}
  ColTrackDB.minimap = ColTrackDB.minimap or {}
  local mm = ColTrackDB.minimap
  if mm.hide == nil then
    mm.hide = false
  end
  return mm
end

local function GetDebugProbeEnabled()
  ColTrackDB = ColTrackDB or {}
  if ColTrackDB.debugProbeEnabled == nil then
    ColTrackDB.debugProbeEnabled = false
  end
  return ColTrackDB.debugProbeEnabled
end

local function SetDebugProbeEnabled(v)
  ColTrackDB = ColTrackDB or {}
  ColTrackDB.debugProbeEnabled = v and true or false
end

local function GetUndermineOverlayEnabled()
  ColTrackDB = ColTrackDB or {}
  if ColTrackDB.enableUndermineOverlay == nil then
    ColTrackDB.enableUndermineOverlay = false
  end
  return ColTrackDB.enableUndermineOverlay
end

local function SetUndermineOverlayEnabled(v)
  ColTrackDB = ColTrackDB or {}
  ColTrackDB.enableUndermineOverlay = v and true or false
end

local function UndermineVignetteColorsConfig()
  ColTrackDB = ColTrackDB or {}
  ColTrackDB.undermineVignetteColors = ColTrackDB.undermineVignetteColors or {}
  return ColTrackDB.undermineVignetteColors
end

local function IsAddonLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then
    return C_AddOns.IsAddOnLoaded(name)
  end
  return IsAddOnLoaded and IsAddOnLoaded(name)
end

local function TryLoadAddon(name)
  if C_AddOns and C_AddOns.LoadAddOn then
    local ok, reason = C_AddOns.LoadAddOn(name)
    return ok, reason
  end
  return LoadAddOn(name)
end

local function IsInUndermine()
  local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  while mapID and mapID > 0 do
    if UNDERMINE_MAP_IDS[mapID] then
      return true
    end
    local info = C_Map.GetMapInfo(mapID)
    if info and info.name == "Undermine" then
      return true
    end
    mapID = info and info.parentMapID
  end
  return false
end

local function RefreshUndermineOverlayState()
  if not GetUndermineOverlayEnabled() then
    if _G.ColTrackVignetteOverlay_SetEnabled then
      _G.ColTrackVignetteOverlay_SetEnabled(false)
    end
    return
  end

  local shouldEnable = IsInUndermine()
  if shouldEnable and not IsAddonLoaded("ColTrack_Vignettes") then
    local loaded, reason = TryLoadAddon("ColTrack_Vignettes")
    if not loaded and not overlayLoadWarned then
      overlayLoadWarned = true
      print("ColTrack: unable to load optional module ColTrack_Vignettes (" .. tostring(reason) .. ").")
    end
  end

  if _G.ColTrackVignetteOverlay_SetEnabled then
    _G.ColTrackVignetteOverlay_SetEnabled(shouldEnable)
  end
end

local function ProbePrint(msg)
  print("ColTrack Probe: " .. msg)
end

local function ProbeHookTooltip()
  if probeHooked or not GameTooltip then
    return
  end

  probeHooked = true
  GameTooltip:HookScript("OnShow", function(tt)
    if not probeEnabled or not Minimap or not MouseIsOver(Minimap) then
      return
    end

    local text = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
    if not text or text == "" then
      return
    end

    local now = GetTime and GetTime() or 0
    if text == probeLastText and probeLastAt and (now - probeLastAt) < 0.75 then
      return
    end

    probeLastText = text
    probeLastAt = now

    local owner = tt:GetOwner()
    local ownerName = owner and owner.GetName and owner:GetName() or "unknown"
    ProbePrint(("minimap tooltip: '%s' (owner=%s)"):format(text, tostring(ownerName)))
  end)
end

local function ProbeScanMinimapChildren()
  if not Minimap then
    ProbePrint("Minimap frame unavailable.")
    return
  end

  local children = { Minimap:GetChildren() }
  local textureStats = {}
  local totalTextures = 0

  for _, child in ipairs(children) do
    local regions = { child:GetRegions() }
    for _, region in ipairs(regions) do
      if region and region.GetObjectType and region:GetObjectType() == "Texture" then
        local atlas = region.GetAtlas and region:GetAtlas() or nil
        local tex = region.GetTexture and region:GetTexture() or nil
        if atlas or tex then
          totalTextures = totalTextures + 1
          local texKey = (atlas and ("atlas:" .. atlas)) or (type(tex) == "string" and ("tex:" .. tex) or ("tex:" .. tostring(tex)))
          textureStats[texKey] = (textureStats[texKey] or 0) + 1
        end
      end
    end
  end

  ProbePrint(("children=%d, textured_regions=%d"):format(#children, totalTextures))

  local rows = {}
  for key, count in pairs(textureStats) do
    rows[#rows + 1] = { key = key, count = count }
  end
  table.sort(rows, function(a, b)
    if a.count == b.count then
      return a.key < b.key
    end
    return a.count > b.count
  end)

  local shown = math.min(#rows, 12)
  for i = 1, shown do
    ProbePrint(("[%d] %s (x%d)"):format(i, rows[i].key, rows[i].count))
  end
end

local function RegisterProbeSlash()
  if SlashCmdList.COLTRACKPROBE then
    return
  end

  SLASH_COLTRACKPROBE1 = "/coltrackprobe"
  SLASH_COLTRACKPROBE2 = "/ctprobe"
  SlashCmdList.COLTRACKPROBE = function(msg)
    local arg = strlower(strtrim(msg or ""))
    if arg == "" or arg == "help" then
      ProbePrint("commands: /ctprobe on | off | status | scan")
      ProbePrint("while ON, hovering minimap icons prints tooltip names to chat.")
      return
    end
    if arg == "on" then
      if not GetDebugProbeEnabled() then
        ProbePrint("disabled in options. Enable 'Debug: allow /ctprobe commands' first.")
        return
      end
      probeEnabled = true
      ProbeHookTooltip()
      ProbePrint("enabled.")
      return
    end
    if arg == "off" then
      probeEnabled = false
      ProbePrint("disabled.")
      return
    end
    if arg == "status" then
      ProbePrint("status: " .. (probeEnabled and "ON" or "OFF"))
      return
    end
    if arg == "scan" then
      if not GetDebugProbeEnabled() then
        ProbePrint("disabled in options. Enable 'Debug: allow /ctprobe commands' first.")
        return
      end
      ProbeScanMinimapChildren()
      return
    end
    ProbePrint("unknown command. use /ctprobe help")
  end
end

local function ActiveStore()
  if GetUseGlobal() then
    ColTrackDB = ColTrackDB or {}
    return ColTrackDB
  end
  ColTrackDBPC = ColTrackDBPC or {}
  return ColTrackDBPC
end

local function EnsureStore(store)
  store.profiles = store.profiles or {}
  store.currentProfile = store.currentProfile or "Default"
  if not store.profiles[store.currentProfile] then
    store.profiles[store.currentProfile] = { tex = BASE }
  end
  return store
end

local function GetProfileNames(store)
  local names = {}
  for name in pairs(store.profiles) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

local function SavePreset(tex)
  local store = EnsureStore(ActiveStore())
  local profileName = store.currentProfile or "Default"
  store.profiles[profileName] = store.profiles[profileName] or {}
  store.profiles[profileName].tex = tex
end

local function LoadPreset()
  local store = EnsureStore(ActiveStore())
  local profile = store.profiles[store.currentProfile]
  local tex = (profile and profile.tex) or BASE
  local normalized = NormalizeTex(tex)
  if normalized ~= tex then
    SavePreset(normalized)
  end
  return normalized
end

local function GetCurrentPresetColors()
  local colors = PRESET_COLORS[LoadPreset()]
  if colors then
    return colors
  end
  return PRESET_COLORS["Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_vivid"]
end

_G.ColTrack_GetCurrentPresetColors = GetCurrentPresetColors
_G.ColTrack_GetCurrentPresetTexture = LoadPreset

local function GetUndermineVignetteColor(kind)
  local cfg = UndermineVignetteColorsConfig()
  local c = cfg[kind]
  if c and c.r and c.g and c.b then
    return { c.r, c.g, c.b }
  end

  local fallbackKey = UNDERMINE_VIGNETTE_FALLBACK[kind] or "ore"
  local preset = GetCurrentPresetColors()
  return (preset and preset[fallbackKey]) or { 1, 1, 1 }
end

local function SetUndermineVignetteColor(kind, r, g, b)
  local cfg = UndermineVignetteColorsConfig()
  cfg[kind] = { r = r, g = g, b = b }
end

_G.ColTrack_GetUndermineVignetteColor = GetUndermineVignetteColor

local function LabelForTex(tex)
  for _, p in ipairs(PRESETS) do
    if p.tex == tex then
      return p.label
    end
  end
  return PRESETS[1].label
end

local function NextPreset()
  local current = LoadPreset()
  local idx = 1
  for i, p in ipairs(PRESETS) do
    if p.tex == current then
      idx = i
      break
    end
  end
  local nextIdx = idx % #PRESETS + 1
  local nextPreset = PRESETS[nextIdx]
  Apply(nextPreset.tex)
  SavePreset(nextPreset.tex)
  if presetDropdown then
    UIDropDownMenu_SetText(presetDropdown, nextPreset.label)
  end
  for _, b in ipairs(presetPreviewButtons) do
    b.selected:SetShown(b.tex == nextPreset.tex)
  end
end

local function SyncPresetUI()
  local current = LoadPreset()
  if presetDropdown then
    UIDropDownMenu_SetText(presetDropdown, LabelForTex(current))
  end
  for _, b in ipairs(presetPreviewButtons) do
    b.selected:SetShown(b.tex == current)
  end
end

local function OpenOptions()
  if Settings and Settings.OpenToCategory then
    if category and category.ID then
      Settings.OpenToCategory(category.ID)
    else
      Settings.OpenToCategory("ColTrack")
    end
    return
  end
  InterfaceOptionsFrame_OpenToCategory("ColTrack")
  InterfaceOptionsFrame_OpenToCategory("ColTrack")
end

local function InitMinimapIcon()
  local ldb = LibStub("LibDataBroker-1.1", true)
  local ldbi = LibStub("LibDBIcon-1.0", true)
  if not ldb or not ldbi then
    return
  end

  if not ldbObject then
    ldbObject = ldb:NewDataObject("ColTrack", {
      type = "data source",
      text = "ColTrack",
      icon = ICON,
      OnClick = function(_, button)
        if button == "RightButton" then
          OpenOptions()
        else
          NextPreset()
        end
      end,
      OnTooltipShow = function(tooltip)
        tooltip:AddLine("ColTrack")
        tooltip:AddLine("Left-click: next preset", 0.9, 0.9, 0.9)
        tooltip:AddLine("Right-click: options", 0.9, 0.9, 0.9)
      end,
    })
  else
    ldbObject.icon = ICON
  end

  local mm = MinimapConfig()
  ldbi:Register("ColTrack", ldbObject, mm)
  if mm.hide then
    ldbi:Hide("ColTrack")
  end
end

local function CreateProfile(name)
  local store = EnsureStore(ActiveStore())
  name = strtrim(name or "")
  if name == "" then
    return nil
  end
  local base = name
  local n = 2
  while store.profiles[name] do
    name = base .. " " .. n
    n = n + 1
  end
  store.profiles[name] = { tex = BASE }
  store.currentProfile = name
  return name
end

local function CreatePanels()
  rootPanel = CreateFrame("Frame")
  rootPanel.name = "ColTrack"

  rootPanel.title = rootPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  rootPanel.title:SetPoint("TOPLEFT", 16, -16)
  rootPanel.title:SetText("ColTrack")

  rootPanel.desc = rootPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  rootPanel.desc:SetPoint("TOPLEFT", rootPanel.title, "BOTTOMLEFT", 0, -8)
  rootPanel.desc:SetText("Configure minimap tracking presets and profiles.")

  if not StaticPopupDialogs["COLTRACK_NEW_PROFILE"] then
    StaticPopupDialogs["COLTRACK_NEW_PROFILE"] = {
      text = "New profile name",
      button1 = ACCEPT,
      button2 = CANCEL,
      hasEditBox = true,
      maxLetters = 32,
      OnAccept = function(self)
        local name = CreateProfile(self.editBox:GetText())
        if name then
          Apply(LoadPreset())
          UIDropDownMenu_SetText(profileDropdown, name)
          SyncPresetUI()
        end
      end,
      OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
      end,
      EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        parent.button1:Click()
      end,
    }
  end

  presetsPanel = CreateFrame("Frame")
  presetsPanel.name = "Tracking Presets"
  presetsPanel.parent = "ColTrack"

  local presetsTitle = presetsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  presetsTitle:SetPoint("TOPLEFT", 16, -16)
  presetsTitle:SetText("Tracking Presets Preview")

  local atlasStatus = presetsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  atlasStatus:SetPoint("TOPLEFT", presetsTitle, "BOTTOMLEFT", 0, -6)
  atlasStatus:SetWidth(560)
  atlasStatus:SetJustifyH("LEFT")
  if IsCustomAtlasCompatible() or GetAllowUnsupportedAtlas() then
    atlasStatus:SetText("")
  else
    atlasStatus:SetText(("Custom presets are temporarily disabled on this WoW client because the minimap atlas changed after %s. Base (Blizzard) is used for safety."):format(CUSTOM_ATLAS_TOC))
    atlasStatus:SetTextColor(1, 0.82, 0, 1)
  end

  local ICON_RECTS = {
    { label = "Fish", x = 928, y = 517, w = 32, h = 32, oy = 0 },
    { label = "Herb", x = 963, y = 520, w = 32, h = 32, oy = 0 },
    { label = "Ore", x = 520, y = 554, w = 32, h = 32, oy = 0 },
    { label = "Lumber", x = 928, y = 453, w = 32, h = 32, oy = 0 },
  }

  local function TexCoord(r)
    local inset = 0.5
    local u1 = (r.x + inset) / 1024
    local v1 = (r.y + inset) / 1024
    local u2 = (r.x + r.w - inset) / 1024
    local v2 = (r.y + r.h - inset) / 1024
    return u1, u2, v1, v2
  end

  local function IsAccessibilityPreset(p)
    return p.tex:find("ObjectIconsAtlas_cb_") ~= nil
      or p.tex == "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_outlineWhite_fillBlack"
  end

  local function CreatePresetRow(p, y)
    local row = CreateFrame("Button", nil, presetsPanel)
    row:SetSize(560, 26)
    row:SetPoint("TOPLEFT", presetsTitle, "BOTTOMLEFT", 0, y)
    row.tex = p.tex

    local sel = row:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints(row)
    sel:SetColorTexture(0.12, 0.45, 0.9, 0.15)
    row.selected = sel
    row.selected:SetShown(false)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 4, 0)
    label:SetWidth(390)
    label:SetJustifyH("LEFT")
    label:SetText(p.label)

    local x = row:GetWidth() - (#ICON_RECTS * 24) + 2
    for _, r in ipairs(ICON_RECTS) do
      local t = row:CreateTexture(nil, "ARTWORK")
      t:SetSize(20, 20)
      t:SetPoint("LEFT", row, "LEFT", x, r.oy or 0)
      t:SetTexture(p.tex)
      t:SetTexCoord(TexCoord(r))
      x = x + 24
    end

    row:SetScript("OnClick", function()
      Apply(p.tex)
      SavePreset(p.tex)
      SyncPresetUI()
      if _G.ColTrackVignetteOverlay_Refresh then
        _G.ColTrackVignetteOverlay_Refresh()
      end
    end)

    presetPreviewButtons[#presetPreviewButtons + 1] = row
  end

  local function CreateSectionHeader(text, y)
    local h = presetsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    h:SetPoint("TOPLEFT", presetsTitle, "BOTTOMLEFT", 0, y)
    h:SetText(text)
  end

  local y = atlasStatus:GetText() ~= "" and -46 or -14
  CreateSectionHeader("Standard Presets", y)
  y = y - 28
  for _, p in ipairs(PRESETS) do
    if not IsAccessibilityPreset(p) then
      CreatePresetRow(p, y)
      y = y - 30
    end
  end

  y = y - 4
  CreateSectionHeader("Accessibility Presets", y)
  y = y - 28
  for _, p in ipairs(PRESETS) do
    if IsAccessibilityPreset(p) then
      CreatePresetRow(p, y)
      y = y - 30
    end
  end

  minimapOptionsPanel = CreateFrame("Frame")
  minimapOptionsPanel.name = "Minimap Options"
  minimapOptionsPanel.parent = "ColTrack"

  local minimapTitle = minimapOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  minimapTitle:SetPoint("TOPLEFT", 16, -16)
  minimapTitle:SetText("Minimap Options")

  local showMinimap = CreateFrame("CheckButton", nil, minimapOptionsPanel, "InterfaceOptionsCheckButtonTemplate")
  showMinimap:SetPoint("TOPLEFT", minimapTitle, "BOTTOMLEFT", 0, -12)
  showMinimap.Text:SetText("Show minimap button")
  showMinimap:SetChecked(not MinimapConfig().hide)
  showMinimap:SetScript("OnClick", function(self)
    local mm = MinimapConfig()
    mm.hide = not self:GetChecked()
    local ldbi = LibStub("LibDBIcon-1.0", true)
    if ldbi then
      if mm.hide then
        ldbi:Hide("ColTrack")
      else
        ldbi:Show("ColTrack")
      end
    end
  end)

  local unsafeAtlas = CreateFrame("CheckButton", nil, minimapOptionsPanel, "InterfaceOptionsCheckButtonTemplate")
  unsafeAtlas:SetPoint("TOPLEFT", showMinimap, "BOTTOMLEFT", 0, -8)
  unsafeAtlas.Text:SetText("Allow custom presets on unsupported WoW client (unsafe)")
  unsafeAtlas:SetChecked(GetAllowUnsupportedAtlas())
  unsafeAtlas:SetScript("OnClick", function(self)
    SetAllowUnsupportedAtlas(self:GetChecked())
    atlasCompatibilityWarned = false
    Apply(LoadPreset())
  end)

  local unsafeAtlasHint = minimapOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  unsafeAtlasHint:SetPoint("TOPLEFT", unsafeAtlas, "BOTTOMLEFT", 24, -2)
  unsafeAtlasHint:SetWidth(520)
  unsafeAtlasHint:SetJustifyH("LEFT")
  unsafeAtlasHint:SetText("Use only for diagnostics. Unsupported atlas presets can change unrelated icons such as chests, traps, or stable masters.")
  unsafeAtlasHint:SetTextColor(0.8, 0.8, 0.8, 1)

  local debugProbe = CreateFrame("CheckButton", nil, minimapOptionsPanel, "InterfaceOptionsCheckButtonTemplate")
  debugProbe:SetPoint("TOPLEFT", unsafeAtlasHint, "BOTTOMLEFT", -24, -8)
  debugProbe.Text:SetText("Debug: allow /ctprobe commands")
  debugProbe:SetChecked(GetDebugProbeEnabled())
  debugProbe:SetScript("OnClick", function(self)
    local enabled = self:GetChecked()
    SetDebugProbeEnabled(enabled)
    if not enabled and probeEnabled then
      probeEnabled = false
      ProbePrint("auto-disabled because debug option was turned off.")
    end
  end)

  local debugProbeHint = minimapOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  debugProbeHint:SetPoint("TOPLEFT", debugProbe, "BOTTOMLEFT", 24, -2)
  debugProbeHint:SetText("Advanced diagnostics for minimap icon API checks.")
  debugProbeHint:SetTextColor(0.8, 0.8, 0.8, 1)

  profilesPanel = CreateFrame("Frame")
  profilesPanel.name = "Profiles"
  profilesPanel.parent = "ColTrack"

  local profilesTitle = profilesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  profilesTitle:SetPoint("TOPLEFT", 16, -16)
  profilesTitle:SetText("Profiles")

  local globalCheck = CreateFrame("CheckButton", nil, profilesPanel, "InterfaceOptionsCheckButtonTemplate")
  globalCheck:SetPoint("TOPLEFT", profilesTitle, "BOTTOMLEFT", 0, -12)
  globalCheck.Text:SetText("Use one profile for all characters")
  globalCheck:SetChecked(GetUseGlobal())
  globalCheck:SetScript("OnClick", function(self)
    SetUseGlobal(self:GetChecked())
    Apply(LoadPreset())
    local store = EnsureStore(ActiveStore())
    UIDropDownMenu_SetText(profileDropdown, store.currentProfile)
    SyncPresetUI()
  end)

  local profileLabel = profilesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  profileLabel:SetPoint("TOPLEFT", globalCheck, "BOTTOMLEFT", 0, -8)
  profileLabel:SetText("Profile")

  profileDropdown = CreateFrame("Frame", "ColTrackProfileDropdown", profilesPanel, "UIDropDownMenuTemplate")
  profileDropdown:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", -16, -2)
  UIDropDownMenu_SetWidth(profileDropdown, 200)

  UIDropDownMenu_Initialize(profileDropdown, function()
    local store = EnsureStore(ActiveStore())
    for _, name in ipairs(GetProfileNames(store)) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = name
      info.checked = (store.currentProfile == name)
      info.func = function()
        store.currentProfile = name
        Apply(LoadPreset())
        UIDropDownMenu_SetText(profileDropdown, name)
        SyncPresetUI()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  local newProfile = CreateFrame("Button", nil, profilesPanel, "UIPanelButtonTemplate")
  newProfile:SetSize(60, 22)
  newProfile:SetPoint("LEFT", profileDropdown, "RIGHT", -8, 2)
  newProfile:SetText("New")
  newProfile:SetScript("OnClick", function()
    StaticPopup_Show("COLTRACK_NEW_PROFILE")
  end)

  local store = EnsureStore(ActiveStore())
  UIDropDownMenu_SetText(profileDropdown, store.currentProfile)
  SyncPresetUI()

  vignettesPanel = CreateFrame("Frame")
  vignettesPanel.name = "Undermine Vignettes"
  vignettesPanel.parent = "ColTrack"

  local function OpenColorPicker(initial, onChanged)
    if not ColorPickerFrame then
      return
    end

    if ColorPickerFrame.SetupColorPickerAndShow then
      local info = {
        r = initial[1],
        g = initial[2],
        b = initial[3],
        hasOpacity = false,
        swatchFunc = function()
          local r, g, b = ColorPickerFrame:GetColorRGB()
          onChanged(r, g, b)
        end,
        cancelFunc = function(prev)
          if prev then
            onChanged(prev.r, prev.g, prev.b)
          end
        end,
      }
      ColorPickerFrame:SetupColorPickerAndShow(info)
      return
    end

    ColorPickerFrame:SetColorRGB(initial[1], initial[2], initial[3])
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.opacity = 0
    ColorPickerFrame.previousValues = { r = initial[1], g = initial[2], b = initial[3] }
    ColorPickerFrame.func = function()
      local r, g, b = ColorPickerFrame:GetColorRGB()
      onChanged(r, g, b)
    end
    ColorPickerFrame.cancelFunc = function(prev)
      onChanged(prev.r, prev.g, prev.b)
    end
    ColorPickerFrame:Show()
  end

  local vigTitle = vignettesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  vigTitle:SetPoint("TOPLEFT", 16, -16)
  vigTitle:SetText("Undermine Vignettes")

  local undermineOverlay = CreateFrame("CheckButton", nil, vignettesPanel, "InterfaceOptionsCheckButtonTemplate")
  undermineOverlay:SetPoint("TOPLEFT", vigTitle, "BOTTOMLEFT", 0, -12)
  undermineOverlay.Text:SetText("Enable Undermine vignette recolor overlay")
  undermineOverlay:SetChecked(GetUndermineOverlayEnabled())
  undermineOverlay:SetScript("OnClick", function(self)
    SetUndermineOverlayEnabled(self:GetChecked())
    RefreshUndermineOverlayState()
  end)

  local undermineDep = vignettesPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  undermineDep:SetPoint("TOPLEFT", undermineOverlay, "BOTTOMLEFT", 24, -2)
  undermineDep:SetText("Requires HereBeDragons (HereBeDragons-Pins-2.0).")
  undermineDep:SetTextColor(0.8, 0.8, 0.8, 1)

  local colorsLabel = vignettesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  colorsLabel:SetPoint("TOPLEFT", undermineDep, "BOTTOMLEFT", 0, -6)
  colorsLabel:SetText("Custom colors")

  local function CreateUndermineColorPickerRow(anchor, labelText, kind)
    local row = CreateFrame("Frame", nil, vignettesPanel)
    row:SetSize(430, 22)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(180)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    local button = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    button:SetSize(72, 20)
    button:SetPoint("LEFT", label, "RIGHT", 8, 0)
    button:SetText("Color")

    local swatchBG = row:CreateTexture(nil, "BORDER")
    swatchBG:SetSize(32, 16)
    swatchBG:SetPoint("LEFT", button, "RIGHT", 10, 0)
    swatchBG:SetColorTexture(0, 0, 0, 1)

    local swatch = row:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(28, 12)
    swatch:SetPoint("CENTER", swatchBG, "CENTER", 0, 0)

    local borderTop = row:CreateTexture(nil, "OVERLAY")
    borderTop:SetColorTexture(1, 1, 1, 0.85)
    borderTop:SetHeight(1)
    borderTop:SetPoint("TOPLEFT", swatchBG, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", swatchBG, "TOPRIGHT", 0, 0)

    local borderBottom = row:CreateTexture(nil, "OVERLAY")
    borderBottom:SetColorTexture(1, 1, 1, 0.85)
    borderBottom:SetHeight(1)
    borderBottom:SetPoint("BOTTOMLEFT", swatchBG, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", swatchBG, "BOTTOMRIGHT", 0, 0)

    local borderLeft = row:CreateTexture(nil, "OVERLAY")
    borderLeft:SetColorTexture(1, 1, 1, 0.85)
    borderLeft:SetWidth(1)
    borderLeft:SetPoint("TOPLEFT", swatchBG, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", swatchBG, "BOTTOMLEFT", 0, 0)

    local borderRight = row:CreateTexture(nil, "OVERLAY")
    borderRight:SetColorTexture(1, 1, 1, 0.85)
    borderRight:SetWidth(1)
    borderRight:SetPoint("TOPRIGHT", swatchBG, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", swatchBG, "BOTTOMRIGHT", 0, 0)

    local function RefreshSwatch()
      local c = GetUndermineVignetteColor(kind)
      swatch:SetColorTexture(c[1], c[2], c[3], 1)
    end

    button:SetScript("OnClick", function()
      local c = GetUndermineVignetteColor(kind)
      OpenColorPicker(c, function(r, g, b)
        SetUndermineVignetteColor(kind, r, g, b)
        RefreshSwatch()
        if _G.ColTrackVignetteOverlay_Refresh then
          _G.ColTrackVignetteOverlay_Refresh()
        end
      end)
    end)

    RefreshSwatch()
    return row
  end

  local rowTrash = CreateUndermineColorPickerRow(colorsLabel, "Shiny Trash Can", "trashcan")
  local rowDump = CreateUndermineColorPickerRow(rowTrash, "Overflowing Dumpster", "dumpster")
  CreateUndermineColorPickerRow(rowDump, "One-time Treasures", "treasure")

  if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(rootPanel, "ColTrack")
    Settings.RegisterAddOnCategory(category)
    if Settings.RegisterCanvasLayoutSubcategory then
      Settings.RegisterCanvasLayoutSubcategory(category, presetsPanel, "Tracking Presets")
      Settings.RegisterCanvasLayoutSubcategory(category, minimapOptionsPanel, "Minimap Options")
      Settings.RegisterCanvasLayoutSubcategory(category, vignettesPanel, "Undermine Vignettes")
      Settings.RegisterCanvasLayoutSubcategory(category, profilesPanel, "Profiles")
    end
  else
    InterfaceOptions_AddCategory(rootPanel)
    InterfaceOptions_AddCategory(presetsPanel)
    InterfaceOptions_AddCategory(minimapOptionsPanel)
    InterfaceOptions_AddCategory(vignettesPanel)
    InterfaceOptions_AddCategory(profilesPanel)
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("MINIMAP_UPDATE_TRACKING")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    Apply(LoadPreset())
    RegisterProbeSlash()
    CreatePanels()
    InitMinimapIcon()
    RefreshUndermineOverlayState()
    return
  end

  -- Tracking updates and zone loads can reset minimap blip texture.
  Apply(LoadPreset())
  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    RefreshUndermineOverlayState()
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      Apply(LoadPreset())
    end)
  end
end)
