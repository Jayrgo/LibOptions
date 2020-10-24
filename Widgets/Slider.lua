local _NAME = "Slider"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class SliderWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local LibMixin = LibMan1:Get("LibMixin", 1)
local BackdropTemplateMixin = BackdropTemplateMixin
local BACKDROP_SLIDER_8_8 = isRetail and BACKDROP_SLIDER_8_8 or {
    bgFile = [[Interface\Buttons\UI-SliderBar-Background]],
    edgeFile = [[Interface\Buttons\UI-SliderBar-Border]],
    tile = true,
    tileEdge = true,
    tileSize = 8,
    edgeSize = 8,
    insets = {left = 3, right = 3, top = 6, bottom = 6},
}

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    ---@type Slider
    self.slider = self.slider or LibMixin:CreateFrame("Slider", nil, self, nil, nil, isRetail and BackdropTemplateMixin or {})
    self.slider:SetParent(self)
    self.slider:ClearAllPoints()
    self.slider:SetPoint("LEFT", self, "CENTER", 4, 0)
    self.slider:SetPoint("RIGHT", -5, 0)
    self.slider:SetOrientation("HORIZONTAL")
    self.slider.backdropInfo = BACKDROP_SLIDER_8_8
    if isRetail then
        self.slider:ApplyBackdrop()
    else
        self.slider:SetBackdrop(self.slider.backdropInfo)
    end
    self.slider:SetObeyStepOnDrag(true)

    self.slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Horizontal]])
    self.slider:SetHeight(18)

    self.slider:SetScript("OnValueChanged", self.Slider_OnValueChanged)
    self.slider:SetScript("OnMinMaxChanged", self.Slider_OnMinMaxChanged)
    self.slider:SetScript("OnMouseWheel", self.Slider_OnMouseWheel)
    self.slider:SetScript("OnMouseDown", self.Slider_OnMouseDown)
    self.slider:SetScript("OnSizeChanged", self.Slider_OnSizeChanged)

    ---@type FontString
    self.text = self.text or self:CreateFontString()
    self.text:SetParent(self)
    self.text:SetFontObject("GameFontNormalSmall")
    self.text:SetDrawLayer("OVERLAY")
    self.text:ClearAllPoints()
    self.text:SetPoint("TOPRIGHT", self, "TOP", 2, 0)
    self.text:SetPoint("BOTTOMRIGHT", self, "BOTTOM", 2, 0)

    self.step = 0
end

function WidgetMixin:OnDisable()
    self.slider:Disable()
    self.text:SetFontObject("GameFontDisableSmall")
end

function WidgetMixin:OnEnable()
    self.slider:Enable()
    self.text:SetFontObject("GameFontNormalSmall")
end

---@return number
function WidgetMixin:GetValue() return self.slider:GetValue() end

---@param value number
function WidgetMixin:OnSetValue(value)
    local slider = self.slider
    if not slider:IsDraggingThumb() then slider:SetValue(value) end
end

---@param min number
---@param max number
function WidgetMixin:SetMinMaxValues(min, max) self.slider:SetMinMaxValues(min, max) end

---@param isPercent boolean
function WidgetMixin:SetIsPercent(isPercent)
    self.isPercent = isPercent

    self:UpdateText()
end

---@param step number
function WidgetMixin:SetStep(step)
    self.step = step or (self.isPercent and 0.01 or 1)

    local slider = self.slider
    slider:SetValueStep(self.step)
    slider:SetStepsPerPage(self.step)

    self:UpdateText()
end

---@param min string
---@param max string
function WidgetMixin:SetMinMaxTexts(min, max)
    self.minText = min
    self.maxText = max

    self:UpdateText()
end

---@param value number
---@param isUserInput boolean
function WidgetMixin:Slider_OnValueChanged(value, isUserInput)
    -- self == slider
    local parent = self:GetParent()

    parent:UpdateText()

    if isUserInput then parent.callbacks:TriggerEvent("OnValueChanged", parent, value) end
end

---@param min number
---@param max number
function WidgetMixin:Slider_OnMinMaxChanged(min, max)
    -- self == slider
    self:GetParent().Slider_OnValueChanged(self, self:GetValue(), false)
end

---@param delta number
function WidgetMixin:Slider_OnMouseWheel(delta)
    -- self == slider
    self:SetValue(self:GetValue() + (delta * self:GetParent().step), true)
end

---@param button string
function WidgetMixin:Slider_OnMouseDown(button)
    -- self == slider
    self:GetParent().Slider_OnValueChanged(self, self:GetValue(), true)
end

---@param width number
---@param height number
function WidgetMixin:Slider_OnSizeChanged(width, height)
    -- self == slider
    if isRetail then self:SetupTextureCoordinates() end
end

local select = select
local strlen = strlen
local strsplit = strsplit

function WidgetMixin:UpdateText()
    local text = self.text
    local slider = self.slider

    local value = slider:GetValue()
    local min, max = slider:GetMinMaxValues()

    if value == min and self.minText then
        text:SetText(self.minText)
    elseif value == max and self.maxText then
        text:SetText(self.maxText)
    else
        if self.isPercent then
            local places = select(2, strsplit(".", self.step * 100))
            text:SetFormattedText("%." .. (places and strlen(places) or 0) .. "f %%", value * 100)
        else
            local places = select(2, strsplit(".", self.step))
            text:SetFormattedText("%." .. (places and strlen(places) or 0) .. "f", value)
        end
    end
    slider:SetHitRectInsets(-text:GetStringWidth(), 0, 0, 0)
end
