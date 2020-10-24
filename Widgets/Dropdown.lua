local _NAME = "Dropdown"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class DropdownWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local CreateFrame = CreateFrame

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    self:SetScript("OnHide", self.OnHide)

    self.selectedValues = {}

    if isRetail then
        ---@type Button
        self.dropdownToggleButton = self.dropdownToggleButton or
                                        CreateFrame("DropDownToggleButton", nil, self,
                                                    "UIDropDownMenuButtonScriptTemplate")
    else
        ---@type Button
        self.dropdownToggleButton = self.dropdownToggleButton or CreateFrame("Button", nil, self)
        self.dropdownToggleButton:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
        self.dropdownToggleButton:SetScript("OnEnter", self.DropdownToggleButton_OnEnter)
        self.dropdownToggleButton:SetScript("OnLeave", self.DropdownToggleButton_OnLeave)
    end

    self.dropdownToggleButton:SetPoint("RIGHT")
    self.dropdownToggleButton:SetSize(24, 24)
    self.dropdownToggleButton:SetScript("OnMouseDown", self.DropdownToggleButton_OnMouseDown)
    self.dropdownToggleButton:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]])
    self.dropdownToggleButton:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]])
    self.dropdownToggleButton:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]])
    self.dropdownToggleButton:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]], "ADD")

    ---@type FontString
    self.text = self.text or self:CreateFontString()
    self.text:SetParent(self)
    self.text:SetDrawLayer("OVERLAY")
    self.text:ClearAllPoints()
    self.text:SetPoint("TOPLEFT", self, "TOP", 5, 0)
    self.text:SetPoint("BOTTOMRIGHT", -30, 0)
    --[[ self.text:SetPoint("LEFT", self, "CENTER", 5, 0)
    self.text:SetPoint("RIGHT", -30, 0) ]]
    self.text:SetFontObject("GameFontNormalSmall")
    self.text:SetJustifyH("RIGHT")

    ---@type Frame
    self.textHover = self.textHover or CreateFrame("Frame")
    self.textHover:SetParent(self)
    self.textHover:SetScript("OnEnter", self.TextHover_OnEnter)
    self.textHover:SetScript("OnLeave", self.TextHover_OnLeave)
    self.textHover:SetScript("OnMouseDown", self.TextHover_OnMouseDown)
    self.textHover:ClearAllPoints()
    self.textHover:SetPoint("TOPLEFT", self.text, "TOPLEFT")
    self.textHover:SetPoint("BOTTOMRIGHT", self.text, "BOTTOMRIGHT")
    self.textHover:SetFrameLevel(self.dropdownToggleButton:GetFrameLevel() + 1)
end

function WidgetMixin:OnDisable()
    self.dropdownToggleButton:Disable()
    self.text:SetFontObject("GameFontDisableSmall")
    self:ClearFocus()
end

function WidgetMixin:OnEnable()
    self.dropdownToggleButton:Enable()
    self.text:SetFontObject("GameFontNormalSmall")
end

---@param width number
---@param height number
function WidgetMixin:OnSizeChanged(width, height) self.dropdownToggleButton:SetHitRectInsets(-width * 0.5, 0, 0, 0) end

---@return any
function WidgetMixin:GetValue() return self.value end

local LibDropdown = LibMan1:Get("LibDropdown", 1)

---@param value any
---@param selected boolean
function WidgetMixin:OnSetValue(value, selected)
    if LibDropdown:IsOwned(self) then return end

    local selectedValues = self.selectedValues

    if type(value) == "nil" then
        self.text:SetText()
        self:TextHover_SetEnabled(false)
        return
    end
    if not self:IsMultiselect() then for k, v in pairs(selectedValues) do selectedValues[k] = nil end end
    selectedValues[value] = selected

    self:Update()
end

local wipe = wipe

---@param values table
function WidgetMixin:SetValues(values)
    if LibDropdown:IsOwned(self) then return end

    self.values = values
    wipe(self.selectedValues)
end

function WidgetMixin:OnHide() self:ClearFocus() end

local pairs = pairs
local tostring = tostring
local sort = sort

---@param values table
---@return table
local function getSortedValues(values)
    local sortedList = {}
    for key in pairs(values) do sortedList[#sortedList + 1] = key end
    sort(sortedList, function(a, b) return tostring(values[a]) < tostring(values[b]) end)
    return sortedList
end

-- Insert your code here...
local SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
local PlaySound = PlaySound
local UIParent = UIParent

---@param button string
function WidgetMixin:DropdownToggleButton_OnMouseDown(button)
    -- self == dropdownToggleButton
    PlaySound(SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON)

    if LibDropdown:IsOwned(self) then
        LibDropdown:Close()
        return
    end

    local parent = self:GetParent()

    local values = parent.values
    if values then
        local menuList = {}

        local selectedValues = parent.selectedValues
        local checked = function(info, arg) return selectedValues[arg] end

        local func = function(info, arg, checked) -- luacheck: ignore 431
            parent:SetValue(arg, checked)
            parent.callbacks:TriggerEvent("OnValueChanged", parent, arg, checked)
        end

        local icons = parent.icons
        local function getIcon(info, arg) if icons then return icons[arg] end end

        local sortedValues
        if parent.sortByKeys then
            sortedValues = {}
            for k in pairs(values) do sortedValues[#sortedValues + 1] = k end
            sort(sortedValues)
        else
            sortedValues = getSortedValues(values)
        end
        for i = 1, #sortedValues do
            local key = sortedValues[i]

            menuList[#menuList + 1] = {
                arg = key,
                text = tostring(values[key]),
                checked = checked,
                func = func,
                isNotRadio = parent:IsMultiselect(),
                keepShownOnClick = parent:IsMultiselect(),
                icon = getIcon,
            }
        end

        local title = parent:GetText()
        title = title ~= "" and title

        local uiHeight = UIParent:GetHeight() * UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        LibDropdown:SetOwner(self, "ANCHOR_" .. ((y < (uiHeight * 0.5)) and "TOP" or "BOTTOM") .. "RIGHT")
        LibDropdown:Open(menuList, title)
    end
end

function WidgetMixin:ClearFocus() if LibDropdown:IsOwned(self.dropdownToggleButton) then LibDropdown:Close() end end

local getTextureString
do -- getTextureString
    local TEXTURE_STRING = "|T%s:0|t "
    local format = format

    ---@param icon string
    ---@return string
    function getTextureString(icon) return format(TEXTURE_STRING, icon) end
end

local L = {}
L.NONE = "none"
if GetLocale() == "deDE" then L.NONE = "keine" end

local tconcat = table.concat

function WidgetMixin:Update()
    if self.pauseUpdates then return end

    local selectedValues = self.selectedValues
    local icons = self.icons
    local displayText
    local hoverText

    local values = self.values
    if values then
        if self:IsMultiselect() then
            local sortedValues = getSortedValues(values)
            displayText, hoverText = {}, {}
            for i = 1, #sortedValues do
                local key = sortedValues[i]

                if selectedValues[key] then
                    local valueText = tostring(values[key])
                    displayText[#displayText + 1] = valueText
                    if icons and icons[key] then
                        valueText = getTextureString(icons[key]) .. valueText
                    end
                    hoverText[#hoverText + 1] = valueText
                end
            end
            displayText = #displayText > 0 and tconcat(displayText, ", ")
            hoverText = tconcat(hoverText, "\n")
        else
            for k, v in pairs(values) do
                if selectedValues[k] then
                    displayText = tostring(v)
                    hoverText = displayText
                    break
                end
            end
        end
    end

    local text = self.text
    text:SetText(displayText or L["none"])
    self:TextHover_SetEnabled(text:IsTruncated(), hoverText)
end

---@param icons table
function WidgetMixin:SetIcons(icons) self.icons = icons end

function WidgetMixin:PauseUpdates() self.pauseUpdates = true end

function WidgetMixin:ResumeUpdates()
    self.pauseUpdates = false
    self:Update()
end

---@param state boolean
function WidgetMixin:SetMultiselect(state) self.isMultiselect = state end

---@return boolean
function WidgetMixin:IsMultiselect() return self.isMultiselect end

---@param sortByKeys boolean
function WidgetMixin:SetSortByKeys(sortByKeys)
    self.sortByKeys = sortByKeys
    self:Update()
end

---@param state boolean
---@param text string
function WidgetMixin:TextHover_SetEnabled(state, text)
    local textHover = self.textHover

    textHover.text = text
    textHover:EnableMouse(state)
end

local GameTooltip = GameTooltip

---@param motion boolean
function WidgetMixin:TextHover_OnEnter(motion)
    -- self == textHover
    local parent = self:GetParent()

    parent.dropdownToggleButton:LockHighlight()

    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText(parent:GetText())
    GameTooltip:AddLine(self.text)
    GameTooltip:Show()
end

---@param motion boolean
function WidgetMixin:TextHover_OnLeave(motion)
    -- self == textHover
    self:GetParent().dropdownToggleButton:UnlockHighlight()

    GameTooltip:Hide()
end

---@param button string
function WidgetMixin:TextHover_OnMouseDown(button)
    -- self == textHover
    local parent = self:GetParent()
    parent.DropdownToggleButton_OnMouseDown(parent.dropdownToggleButton, button)
end

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    local ExecuteFrameScript = ExecuteFrameScript

    ---@param motion boolean
    function WidgetMixin:DropdownToggleButton_OnEnter(motion)
        -- self == dropdownToggleButton
        ExecuteFrameScript(self:GetParent(), "OnEnter", motion)
    end

    ---@param motion boolean
    function WidgetMixin:DropdownToggleButton_OnLeave(motion)
        -- self == dropdownToggleButton
        ExecuteFrameScript(self:GetParent(), "OnLeave", motion)
    end
end
