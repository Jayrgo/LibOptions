local _NAME = "ColorSelect"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class ColorSelectWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local CreateFrame = CreateFrame
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local BLACK_FONT_COLOR = BLACK_FONT_COLOR
local ColorPickerFrame = ColorPickerFrame
local OpacitySliderFrame = OpacitySliderFrame

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    if isRetail then
        ---@type Button
        self.button = self.button or CreateFrame("Button", nil, self, "ColorSwatchTemplate")
    else
        ---@type Button
        self.button = self.button or CreateFrame("Button", nil, self)
        self.button:SetSize(16, 16)

        ---@type Texture
        self.button.SwatchBg = self.button.SwatchBg or self.button:CreateTexture(nil, "BACKGROUND")
        self.button.SwatchBg:SetTexelSnappingBias(0)
        self.button.SwatchBg:SetSnapToPixelGrid(false)
        self.button.SwatchBg:SetSize(14, 14)
        self.button.SwatchBg:ClearAllPoints()
        self.button.SwatchBg:SetPoint("CENTER")
        self.button.SwatchBg:SetColorTexture(HIGHLIGHT_FONT_COLOR:GetRGBA())

        ---@type Texture
        self.button.InnerBorder = self.button.InnerBorder or self.button:CreateTexture(nil, "BORDER")
        self.button.InnerBorder:SetTexelSnappingBias(0)
        self.button.InnerBorder:SetSnapToPixelGrid(false)
        self.button.InnerBorder:SetSize(12, 12)
        self.button.InnerBorder:ClearAllPoints()
        self.button.InnerBorder:SetPoint("CENTER")
        self.button.InnerBorder:SetColorTexture(BLACK_FONT_COLOR:GetRGBA())

        ---@type Texture
        self.button.Color = self.button.Color or self.button:CreateTexture(nil, "OVERLAY")
        self.button.Color:SetTexelSnappingBias(0)
        self.button.Color:SetSnapToPixelGrid(false)
        self.button.Color:SetSize(10, 10)
        self.button.Color:ClearAllPoints()
        self.button.Color:SetPoint("CENTER")
        self.button.Color:SetColorTexture(HIGHLIGHT_FONT_COLOR:GetRGBA())
    end

    self.button:SetParent(self)
    self.button:SetScript("OnClick", self.Button_OnClick)
    self.button:ClearAllPoints()
    self.button:SetPoint("RIGHT", -2, 0)

    ---@param previousValues number[] | nil
    self.callback = function(previousValues)
        local r, g, b, a
        if previousValues then
            r, g, b, a = unpack(previousValues)
        else
            r, g, b = ColorPickerFrame:GetColorRGB()
        end
        if self.hasAlpha then
            self.callbacks:TriggerEvent("OnValueChanged", self, r, g, b, a and a or (1 - OpacitySliderFrame:GetValue()))
        else
            self.callbacks:TriggerEvent("OnValueChanged", self, r, g, b)
        end
    end
end

function WidgetMixin:OnDisable()
    self.button:Disable()
    self:UpdateBorderColor()
    if ColorPickerFrame.func == self.callback then ColorPickerFrame:Hide() end
end

function WidgetMixin:OnEnable()
    self.button:Enable()
    self:UpdateBorderColor()
end

---@param motion boolean
function WidgetMixin:OnEnter(motion) self:UpdateBorderColor() end

---@param motion boolean
function WidgetMixin:OnLeave(motion) self:UpdateBorderColor() end

---@param width number
---@param height number
function WidgetMixin:OnSizeChanged(width, height) self.button:SetHitRectInsets(-width * 0.5, 0, 0, 0) end

---@return number
---@return number
---@return number
---@return number
function WidgetMixin:GetValue() return self.r, self.g, self.b, self.hasAlpha and self.a end

---@param r number
---@param g number
---@param b number
---@param a number
function WidgetMixin:OnSetValue(r, g, b, a)
    self.r = r
    self.g = g
    self.b = b
    self.a = a
    self.button.Color:SetVertexColor(r, g, b, a)
end

---@param hasAlpha boolean
function WidgetMixin:SetHasAlpha(hasAlpha) self.hasAlpha = hasAlpha end

---@param button string
---@param down boolean
function WidgetMixin:Button_OnClick(button, down)
    -- self == button
    local parent = self:GetParent()

    ColorPickerFrame:SetColorRGB(parent.r, parent.g, parent.b)
    -- luacheck: push ignore 122
    ColorPickerFrame.func = parent.callback
    ColorPickerFrame.hasOpacity = parent.hasAlpha
    ColorPickerFrame.opacity = parent.hasAlpha and 1 - parent.a or 0
    ColorPickerFrame.opacityFunc = parent.callback
    ColorPickerFrame.cancelFunc = parent.callback
    ColorPickerFrame.previousValues = {parent.r, parent.g, parent.b, parent.hasAlpha and parent.a}
    -- luacheck: pop

    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
end

local DISABLED_FONT_COLOR = DISABLED_FONT_COLOR
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR

function WidgetMixin:UpdateBorderColor()
    local button = self.button
    button.SwatchBg:SetVertexColor((self:IsEnabled() and
                                       (button:IsMouseOver(0, 0, -self:GetWidth() * 0.5, 0) and NORMAL_FONT_COLOR or
                                           HIGHLIGHT_FONT_COLOR) or DISABLED_FONT_COLOR):GetRGBA())
end
