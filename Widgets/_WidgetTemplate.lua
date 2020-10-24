local _NAME = "NewWidget" -- Set the name of the Widget
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class NewWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

function WidgetMixin:OnLoad()
    self.OnLoad = nil
    -- Insert code here...
end

function WidgetMixin:OnAcquire()
    -- Insert code here...
end

function WidgetMixin:OnRelease()
    -- Insert code here...
end

function WidgetMixin:OnEnable()
    -- Insert code here...
end

function WidgetMixin:OnDisable()
    -- Insert code here...
end

---@param motion boolean
function WidgetMixin:OnEnter(motion)
    -- Insert code here...
end

---@param motion boolean
function WidgetMixin:OnLeave(motion)
    -- Insert code here...
end

---@param filename string
---@param coords table
function WidgetMixin:OnIconSet(filename, coords)
    -- Insert code here...
end

---@param width number
---@param height number
function WidgetMixin:OnSizeChanged(width, height)
    -- Insert code here...
end

---@param text string
function WidgetMixin:OnTextSet(text)
    -- Insert code here...
end

---@param tooltip string
function WidgetMixin:OnTooltipSet(tooltip)
    -- Insert code here...
end

---@vararg any
function WidgetMixin:OnSetValue(...)
    -- Insert code here...
end

---@return any
function WidgetMixin:GetValue()
    -- Insert code here...
end

-- Insert code here...
