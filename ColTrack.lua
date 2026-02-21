local ADDON = ...
local BASE = "Interface\\Minimap\\ObjectIconsAtlas"
local ICON = "Interface\\AddOns\\ColTrack\\Images\\log2.tga"

local rootPanel
local category
local presetsPanel
local profilesPanel
local profileDropdown
local presetDropdown
local ldbObject
local presetPreviewButtons = {}

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
    label = "Fish Blue / Herb Green / Ore Yellow / Lumber Pink",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_fishBlue_herbGreen_oreYellow_lumberPink",
  },
  {
    label = "White Outline / Black Fill",
    tex = "Interface\\AddOns\\ColTrack\\Textures\\ObjectIconsAtlas_outlineWhite_fillBlack",
  },
}

local function Apply(tex)
  if Minimap and Minimap.SetBlipTexture then
    Minimap:SetBlipTexture(tex)
  end
end

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
  return (profile and profile.tex) or BASE
end

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
          UIDropDownMenu_SetText(presetDropdown, LabelForTex(LoadPreset()))
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
  presetsPanel.name = "Presets"
  presetsPanel.parent = "ColTrack"

  local presetsTitle = presetsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  presetsTitle:SetPoint("TOPLEFT", 16, -16)
  presetsTitle:SetText("Presets")

  local presetLabel = presetsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  presetLabel:SetPoint("TOPLEFT", presetsTitle, "BOTTOMLEFT", 0, -12)
  presetLabel:SetText("Preset")

  presetDropdown = CreateFrame("Frame", "ColTrackPresetDropdown", presetsPanel, "UIDropDownMenuTemplate")
  presetDropdown:SetPoint("TOPLEFT", presetLabel, "BOTTOMLEFT", -16, -2)
  UIDropDownMenu_SetWidth(presetDropdown, 320)

  UIDropDownMenu_Initialize(presetDropdown, function()
    for _, p in ipairs(PRESETS) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = p.label
      info.checked = (LoadPreset() == p.tex)
      info.func = function()
        Apply(p.tex)
        SavePreset(p.tex)
        UIDropDownMenu_SetText(presetDropdown, p.label)
        for _, b in ipairs(presetPreviewButtons) do
          b.selected:SetShown(b.tex == p.tex)
        end
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  local previewLabel = presetsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  previewLabel:SetPoint("TOPLEFT", presetDropdown, "BOTTOMLEFT", 16, -12)
  previewLabel:SetText("Preview")

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

  for i, p in ipairs(PRESETS) do
    local row = CreateFrame("Button", nil, presetsPanel)
    row:SetSize(440, 26)
    row:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -6 - (i - 1) * 30)
    row.tex = p.tex

    local sel = row:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints(row)
    sel:SetColorTexture(0.12, 0.45, 0.9, 0.15)
    row.selected = sel
    row.selected:SetShown(false)

    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 4, 0)
    label:SetText(p.label)

    local x = 300
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
      UIDropDownMenu_SetText(presetDropdown, p.label)
      for _, b in ipairs(presetPreviewButtons) do
        b.selected:SetShown(b.tex == p.tex)
      end
    end)

    presetPreviewButtons[#presetPreviewButtons + 1] = row
  end

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
    UIDropDownMenu_SetText(presetDropdown, LabelForTex(LoadPreset()))
  end)

  local showMinimap = CreateFrame("CheckButton", nil, profilesPanel, "InterfaceOptionsCheckButtonTemplate")
  showMinimap:SetPoint("TOPLEFT", globalCheck, "BOTTOMLEFT", 0, -8)
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

  local profileLabel = profilesPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  profileLabel:SetPoint("TOPLEFT", showMinimap, "BOTTOMLEFT", 0, -8)
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
        UIDropDownMenu_SetText(presetDropdown, LabelForTex(LoadPreset()))
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
  UIDropDownMenu_SetText(presetDropdown, LabelForTex(LoadPreset()))
  for _, b in ipairs(presetPreviewButtons) do
    b.selected:SetShown(b.tex == LoadPreset())
  end

  if Settings and Settings.RegisterCanvasLayoutCategory then
    category = Settings.RegisterCanvasLayoutCategory(rootPanel, "ColTrack")
    Settings.RegisterAddOnCategory(category)
    if Settings.RegisterCanvasLayoutSubcategory then
      Settings.RegisterCanvasLayoutSubcategory(category, presetsPanel, "Presets")
      Settings.RegisterCanvasLayoutSubcategory(category, profilesPanel, "Profiles")
    end
  else
    InterfaceOptions_AddCategory(rootPanel)
    InterfaceOptions_AddCategory(presetsPanel)
    InterfaceOptions_AddCategory(profilesPanel)
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  Apply(LoadPreset())
  CreatePanels()
  InitMinimapIcon()
end)
