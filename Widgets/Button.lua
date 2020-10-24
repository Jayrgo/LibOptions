local _NAME = "Button"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class ButtonWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

local CreateFrame = CreateFrame

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    ---@type Button
    self.button = self.button or CreateFrame("Button", nil, self)
    self.button:SetPoint("TOPLEFT", self, "TOP")
    self.button:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
    self.button:SetScript("OnClick", self.Button_OnClick)

    ---@type Texture
    self.leftTexture = self.leftTexture or self.button:CreateTexture()
    self.leftTexture:SetParent(self)
    self.leftTexture:SetDrawLayer("BACKGROUND")
    self.leftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.leftTexture:SetTexCoord(0, 0.09375, 0, 0.6875)
    self.leftTexture:ClearAllPoints()
    self.leftTexture:SetPoint("TOPLEFT", self.button, "TOPLEFT", 2, 0)
    self.leftTexture:SetPoint("BOTTOMLEFT", self.button, "BOTTOMLEFT", 2, 0)
    self.leftTexture:SetWidth(12)

    ---@type Texture
    self.rightTexture = self.rightTexture or self.button:CreateTexture()
    self.rightTexture:SetParent(self)
    self.rightTexture:SetDrawLayer("BACKGROUND")
    self.rightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.rightTexture:SetTexCoord(0.53125, 0.625, 0, 0.6875)
    self.rightTexture:ClearAllPoints()
    self.rightTexture:SetPoint("TOPRIGHT", self.button, "TOPRIGHT", -2, 0)
    self.rightTexture:SetPoint("BOTTOMRIGHT", self.button, "BOTTOMRIGHT", -2, 0)
    self.rightTexture:SetWidth(12)

    ---@type Texture
    self.middleTexture = self.middleTexture or self.button:CreateTexture()
    self.middleTexture:SetParent(self)
    self.middleTexture:SetDrawLayer("BACKGROUND")
    self.middleTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.middleTexture:SetTexCoord(0.09375, 0.53125, 0, 0.6875)
    self.middleTexture:ClearAllPoints()
    self.middleTexture:SetPoint("TOPLEFT", self.leftTexture, "TOPRIGHT")
    self.middleTexture:SetPoint("BOTTOMRIGHT", self.rightTexture, "BOTTOMLEFT")

    ---@type Texture
    local highlightTexture = self.button:GetHighlightTexture() or
                                 self.button:CreateTexture(nil, nil, "UIPanelButtonHighlightTexture")
    self.button:SetHighlightTexture(highlightTexture, "ADD")
end

function WidgetMixin:OnDisable()
    self.button:Disable()
    self.leftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
    self.middleTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
    self.rightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
end

function WidgetMixin:OnEnable()
    self.button:Enable()
    self.leftTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.middleTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
    self.rightTexture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
end

---@param button string
---@param down boolean
function WidgetMixin:Button_OnClick(button, down)
    -- self == button
    if self:GetParent().func then self:GetParent().func(button, down) end
end

---@param func function
function WidgetMixin:SetFunc(func) self.func = func end
