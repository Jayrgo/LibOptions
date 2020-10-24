local _NAME = "CheckButton"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class CheckButtonWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    self:SetHeight(28)

    ---@type CheckButton
    self.checkButton = self.checkButton or CreateFrame("CheckButton", nil, self)
    self.checkButton:SetSize(26, 26)
    self.checkButton:SetPoint("RIGHT")
    self.checkButton:SetScript("OnClick", self.CheckButton_OnClick)
    self.checkButton:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
    self.checkButton:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])
    self.checkButton:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]], "ADD")
    self.checkButton:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]])
    self.checkButton:SetDisabledCheckedTexture([[Interface\Buttons\UI-CheckBox-Check-Disabled]])
end

function WidgetMixin:OnDisable() self.checkButton:Disable() end

function WidgetMixin:OnEnable() self.checkButton:Enable() end

---@param width number
---@param height number
function WidgetMixin:OnSizeChanged(width, height) self.checkButton:SetHitRectInsets(-width * 0.5, 0, 0, 0) end

---@return any
function WidgetMixin:GetValue() return self.checkButton:GetChecked() end

---@param value boolean
function WidgetMixin:OnSetValue(value) self.checkButton:SetChecked(value) end

local SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
local SOUND_IG_MAINMENU_OPTION_CHECKBOX_OFF = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
local PlaySound = PlaySound

---@param button string
---@param down boolean
function WidgetMixin:CheckButton_OnClick(button, down)
    -- self == checkButton
    local value = self:GetChecked()
    PlaySound(value and SOUND_IG_MAINMENU_OPTION_CHECKBOX_ON or SOUND_IG_MAINMENU_OPTION_CHECKBOX_OFF)

    local parent = self:GetParent()
    parent.callbacks:TriggerEvent("OnValueChanged", parent, value)
end
