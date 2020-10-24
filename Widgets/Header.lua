local _NAME = "Header"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class HeaderWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    self.fontString:ClearAllPoints()
    self.fontString:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 12, 0)
    self.fontString:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 4, 0)

    self.fontString:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 4, 0)
            self.fontString:SetPoint("BOTTOMLEFT", self.icon, "BOTTOMRIGHT", 4, 0)
end
