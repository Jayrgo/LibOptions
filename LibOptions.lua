local _NAME = "LibOptions"
local _VERSION = "1.0.0" -- Don't change this. The version is updated automatically.
local _LICENSE = [[
    MIT License

    Copyright (c) 2020 Jayrgo

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

assert(LibMan1, format("%s requires LibMan-1.x.x.", _NAME))
assert(LibMan1._VERSION.minor >= 1,
       format("%s requires a minimum LibMan version of 1.1.0 (currently %s)", _NAME, tostring(LibMan1._VERSION)))
assert(LibMan1:Exists("LibMixin", 1), format("%s requires LibMixin-1.x.x.", _NAME))
assert(LibMan1:Exists("LibCallback", 1), format("%s requires LibCallback-1.x.x.", _NAME))

local Lib --[[ , oldVersion ]] = LibMan1:New(_NAME, _VERSION, "_LICENSE", _LICENSE)
if not Lib then return end

local safecall = Lib.safecall
local xsafecall = Lib.xsafecall

local tnew, tdel
do -- tnew, tdel

    local cache = setmetatable({}, {__mode = "k"})

    local next = next
    local select = select

    ---@return table
    function tnew(...)
        local t = next(cache)
        if t then
            cache[t] = nil
            local n = select("#", ...)
            for i = 1, n do t[i] = select(i, ...) end
            return t
        end
        return {...}
    end

    local wipe = wipe

    ---@param t table
    function tdel(t) cache[wipe(t)] = true end
end

local error = error
local format = format
local pairs = pairs
local tremove = tremove

---@type Frame
Lib.frame = Lib.frame or CreateFrame("Frame")
local frame = Lib.frame
frame:Hide()

---@type ScrollFrame
frame.scrollFrame = frame.scrollFrame or CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
frame.scrollFrame:SetAllPoints()
frame.scrollFrame.scrollBarHideable = true

---@type Frame
frame.container = frame.container or CreateFrame("Frame", nil, frame.scrollFrame, "VerticalLayoutFrame")
frame.container.spacing = 0

frame.scrollFrame:SetScrollChild(frame.container)
---@param self ScrollFrame
---@param width number
---@param height number
frame.scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
    local scrollChild = self:GetScrollChild()
    scrollChild.fixedWidth = width - 10
    scrollChild:MarkDirty()
end)
---@param self ScrollFrame
---@param elapsed number
frame.scrollFrame:SetScript("OnUpdate",
                            function(self, elapsed) self.ScrollBar:SetShown(self:GetVerticalScrollRange() ~= 0) end)

local container = frame.container

local LibMixin = LibMan1:Get("LibMixin", 1)

local tostring = tostring

local acquireWidget, releaseWidget
do -- Widgets
    Lib.widgets = Lib.widgets or {}

    Lib.widgets.mixins = Lib.widgets.mixins or {}
    Lib.widgets.versions = Lib.widgets.versions or {}
    Lib.widgets.caches = Lib.widgets.caches or {}

    local mixins = Lib.widgets.mixins
    local versions = Lib.widgets.versions
    local caches = Lib.widgets.caches

    ---@param widget Widget
    ---@return number
    local function canUpgradeWidget(widget)
        local name = widget._NAME
        local version = widget._VERSION

        if version == versions[name] then return 0 end
        if version ^ versions[name] and version > version[name] then return 1 end
        return -1
    end

    ---@param widget Widget
    ---@return number
    local function upgradeWidget(widget)
        local canUpgrade = canUpgradeWidget(widget)
        if canUpgrade == 1 then LibMixin:Mixin(widget, mixins[widget.name]) end
        return canUpgrade
    end

    local type = type

    ---@param name string
    ---@param version string
    ---@return Widget
    ---@return Version
    function Lib:RegisterWidget(name, version)
        if type(name) ~= "string" then
            error(format("Usage: %s:RegisterWidget(name, version): 'name' - string expected got %s", tostring(Lib),
                         type(name)), 2)
        end
        if type(version) ~= "string" then
            error(format("Usage: %s:RegisterWidget(name, version): 'version' - string expected got %s", tostring(Lib),
                         type(version)), 2)
        end

        version = LibMan1.Version:New(version)

        local oldVersion = versions[name]
        if oldVersion and oldVersion >= version then return end

        ---@type Widget
        local mixin = {_NAME = name, _VERSION = version}

        mixins[name] = mixin
        versions[name] = version

        local cache = caches[name]
        if cache then
            local i = 0
            while true do
                i = i + 1
                if i <= #cache then
                    if upgradeWidget(cache[i]) == -1 then
                        tremove(cache, i)
                        i = i - 1
                    end
                else
                    break
                end
            end
        end

        return mixin, oldVersion
    end

    ---@param name string
    ---@return boolean
    local function isWidgetRegistered(name) if mixins[name] then return true end end

    ---@class Widget: Frame
    local WidgetBaseMixin = {}
    do -- WidgetBaseMixin

        function WidgetBaseMixin:Acquire()
            self:SetIcon()
            self:SetText()
            self:OnAcquire()
        end

        function WidgetBaseMixin:Disable()
            self:EnableMouse(false)
            self.fontString:SetFontObject("GameFontDisableSmallLeft")
            self:OnDisable()
        end

        function WidgetBaseMixin:Enable()
            self:EnableMouse(true)
            self.fontString:SetFontObject(self:IsMouseOver() and "GameFontHighlightSmallLeft" or
                                              "GameFontNormalSmallLeft")
            self:OnEnable()
        end

        local GameTooltip = GameTooltip

        ---@param motion boolean
        function WidgetBaseMixin:Enter(motion)
            self.fontString:SetFontObject("GameFontHighlightSmallLeft")
            self.line:SetColorTexture(1, 1, 1, 0.5)

            if self.tooltip then
                --[[ GameTooltip:SetOwner(widget, "ANCHOR_RIGHT") ]]
                GameTooltip:ClearAllPoints()
                GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT")
                GameTooltip:SetOwner(self, "ANCHOR_PRESERVE")
                GameTooltip:SetText(self:GetText())
                GameTooltip:AddLine(self.tooltip, nil, nil, nil, true)
                GameTooltip:Show()
            end

            self:OnEnter(motion)
        end

        ---@return string
        function WidgetBaseMixin:GetText() return self.fontString:GetText() end

        ---@return any
        function WidgetBaseMixin:GetValue() end

        ---@return boolean
        function WidgetBaseMixin:IsEnabled() return self:IsMouseEnabled() end

        ---@param motion boolean
        function WidgetBaseMixin:Leave(motion)
            self.fontString:SetFontObject("GameFontNormalSmallLeft")
            self.line:SetColorTexture(1, 0.82, 0, 0.1)

            GameTooltip:Hide()

            self:OnLeave(motion)
        end

        function WidgetBaseMixin:OnAcquire() end

        function WidgetBaseMixin:OnDisable() end

        function WidgetBaseMixin:OnEnable() end

        ---@param motion boolean
        function WidgetBaseMixin:OnEnter(motion) end

        ---@param filename string
        ---@param coords table
        function WidgetBaseMixin:OnIconSet(filename, coords) end

        ---@param motion boolean
        function WidgetBaseMixin:OnLeave(motion) end

        local LibCallback = LibMan1:Get("LibCallback", 1)

        function WidgetBaseMixin:OnLoad()
            self.OnLoad = nil
            self.callbacks = self.callbacks or LibCallback:New(self)

            self:SetHeight(24)

            self.expand = true

            ---@type Texture
            self.icon = self.icon or self:CreateTexture()
            self.icon:SetParent(self)
            self.icon:SetDrawLayer("ARTWORK")
            self.icon:ClearAllPoints()
            self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
            self.icon:SetSize(20, 20)

            ---@type FontString
            self.fontString = self.fontString or self:CreateFontString()
            self.fontString:SetParent(self)
            self.fontString:SetDrawLayer("BORDER")
            self.fontString:ClearAllPoints()
            self.fontString:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", 4, 0)
            self.fontString:SetPoint("BOTTOMLEFT", self.icon, "BOTTOMRIGHT", 4, 0)
            self.fontString:SetFontObject("GameFontNormalSmallLeft")

            ---@type Line
            self.line = self.line or self:CreateLine()
            self.line:SetStartPoint("BOTTOMLEFT", self)
            self.line:SetEndPoint("BOTTOMRIGHT", self)
            self.line:SetThickness(1)
            self.line:SetColorTexture(1, 0.82, 0, 0.1)

            self:SetScript("OnEnter", self.Enter)
            self:SetScript("OnLeave", self.Leave)
            self:SetScript("OnSizeChanged", self.SizeChanged)
        end

        function WidgetBaseMixin:OnRelease() end

        ---@vararg any
        function WidgetBaseMixin:OnSetValue(...) end

        ---@param width number
        ---@param height number
        function WidgetBaseMixin:OnSizeChanged(width, height) end

        ---@param text string
        function WidgetBaseMixin:OnTextSet(text) end

        ---@param tooltip string
        function WidgetBaseMixin:OnTooltipSet(tooltip) end

        function WidgetBaseMixin:Release()
            self.callbacks:Wipe()
            self:OnRelease()
        end

        ---@param enabledFlag boolean
        function WidgetBaseMixin:SetEnabled(enabledFlag)
            if enabledFlag then
                self:Enable()
            else
                self:Disable()
            end
        end

        local unpack = unpack

        ---@param filename string
        ---@param coords table
        function WidgetBaseMixin:SetIcon(filename, coords)
            local icon = self.icon

            icon:SetTexture(filename)

            local left, right, top, bottom
            if coords then left, right, top, bottom = unpack(coords) end
            icon:SetTexCoord(left or 0, right or 1, top or 0, bottom or 1)

            icon:SetWidth(filename and 20 or 0.1)

            self:OnIconSet(filename, coords)
        end

        ---@param text string
        function WidgetBaseMixin:SetText(text)
            self.fontString:SetText(text)
            self:OnTextSet(text)
        end

        ---@param tooltip string
        function WidgetBaseMixin:SetTooltip(tooltip)
            self.tooltip = tooltip
            self:OnTooltipSet(tooltip)
        end

        ---@vararg any
        function WidgetBaseMixin:SetValue(...) self:OnSetValue(...) end

        ---@param width number
        ---@param height number
        function WidgetBaseMixin:SizeChanged(width, height) self:OnSizeChanged(width, height) end
    end

    ---@param name string
    ---@return Widget
    function acquireWidget(name)
        local widget
        if type(name) == "string" then
            local cache = caches[name]
            if cache then widget = tremove(cache) end
            if not widget then
                local mixin = mixins[name]
                if mixin then
                    widget = LibMixin:CreateFrame("Frame", nil, nil, nil, nil, WidgetBaseMixin, mixin)
                end
            end
        elseif type(name) == "table" then
            widget = name
        end
        if widget then
            widget:SetParent(container)
            widget:Show()
            widget:Acquire()
            widget:Enable()

            return widget
        end
    end

    ---@param widget Widget
    function releaseWidget(widget)
        local name = widget._NAME

        if name and isWidgetRegistered(name) then
            if upgradeWidget(widget) >= 0 then
                caches[name] = caches[name] or {}
                caches[name][#caches[name] + 1] = widget
            end
        end

        widget:Hide()
        widget:SetParent(nil)
        widget:ClearAllPoints()
        widget:Release()
    end
end

do -- Panels
    local type = type

    ---@param info table
    ---@param option table
    local function fillInfoPath(info, option)
        if option.parent then fillInfoPath(info, option.parent) end
        if type(option.path) == "table" then
            for i = 1, #option.path do info[#info + 1] = option.path[i] end
        else
            info[#info + 1] = option.path
        end
    end

    ---@param option table
    ---@return table
    local function getInfo(option)
        local info = tnew()

        info.type = option.type
        info.arg = option.arg
        info.widget = option.widget

        if option.type == "select" then
            info.isMulti = option.isMulti
        elseif option.type == "color" then
            info.hasAlpha = option.hasAlpha
        end

        fillInfoPath(info, option)

        return info
    end

    local packargs
    do -- packargs
        local select = select

        ---@vararg any
        ---@return table
        function packargs(...) return {n = select("#", ...), ...} end
    end

    local unpackargs
    do -- unpackargs
        local unpack = unpack

        ---@param t table
        ---@param i number
        ---@param j number
        ---@return any
        function unpackargs(t, i, j) return unpack(t, i or 1, j or t.n) end
    end

    ---@param option table
    ---@param key string
    ---@vararg any
    ---@return any
    local function getOptionValue(option, key, ...)
        local value = option[key]
        if type(value) == "function" then
            local info = getInfo(option)
            local results = packargs(xsafecall(value, info, ...))
            tdel(info)
            if results[1] then return unpackargs(results, 2) end
            tdel(results)
        elseif type(value) == "string" and type(option.handler) == "table" and option.handler[value] then
            local info = getInfo(option)
            local results = packargs(xsafecall(option.handler[value], option.handler, info, ...))
            tdel(info)
            if results[1] then return unpackargs(results, 2) end
            tdel(results)
        end
        return value
    end

    local LibProtectedCall = LibMan1:Get("LibProtectedCall", 1)

    ---@param option table
    local function setValue(option, ...)
        if getOptionValue(option, "noCombat") then
            LibProtectedCall:Call(getOptionValue, option, "set", ...)
        else
            getOptionValue(option, "set", ...)
        end
    end

    ---@param optionList table
    local function setDefaults(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]

            if option.type == "select" and option.isMulti then
                for k, v in pairs(getOptionValue(option, "values") or tnew()) do -- luacheck: ignore 213
                    setValue(option, k, getOptionValue(option, "default", k))
                end
            elseif option.type == "color" then
                local r, g, b, a = getOptionValue(option, "default")
                if option.hasAlpha then
                    setValue(option, r, g, b, a)
                else
                    setValue(option, r, g, b)
                end
            else
                setValue(option, getOptionValue(option, "default"))
            end

            if option.optionList then setDefaults(option.optionList) end
        end
    end

    local LOCKDOWN_ICON = [[Interface\CharacterFrame\UI-StateIcon]]
    local LOCKDOWN_ICON_COORDS = {0.5, 1, 0, 0.5}
    local InCombatLockdown = InCombatLockdown

    ---@param widgets table<number, Widget>
    local function updateWidgets(widgets)
        -- luacheck: push ignore 431
        local safecall = safecall
        local getOptionValue = getOptionValue
        -- luacheck: pop

        local inLockdown = InCombatLockdown()

        for i = 1, #widgets do
            local widget = widgets[i]
            local option = widget.option

            safecall(widget.PauseUpdates, widget)

            local hidden = getOptionValue(option, "hidden") or
                               ((widget.parent and not widget.parent:IsShown()) or false)
            if hidden and widget:IsShown() then
                widget:Hide()
            elseif not hidden and not widget:IsShown() then
                widget:Show()
            end

            safecall(widget.SetText, widget, getOptionValue(option, "text"))
            safecall(widget.SetTooltip, widget, getOptionValue(option, "tooltip"))

            local optionType = option.type
            if optionType == "boolean" then
                safecall(widget.SetValue, widget, getOptionValue(option, "get"))
            elseif optionType == "header" then
            elseif optionType == "number" then
                safecall(widget.SetMinMaxValues, widget, getOptionValue(option, "min"), getOptionValue(option, "max"))
                safecall(widget.SetIsPercent, widget, getOptionValue(option, "isPercent"))
                safecall(widget.SetStep, widget, getOptionValue(option, "step"))
                safecall(widget.SetMinMaxValues, widget, getOptionValue(option, "min"), getOptionValue(option, "max"))
                safecall(widget.SetMinMaxTexts, widget, getOptionValue(option, "minText"),
                         getOptionValue(option, "maxText"))
                safecall(widget.SetValue, widget, getOptionValue(option, "get"))
            elseif optionType == "function" then
                safecall(widget.SetFunc, widget, option.func)
            elseif optionType == "string" then
                safecall(widget.SetReadOnly, widget, getOptionValue(option, "isReadOnly"))
                safecall(widget.SetMaxLetters, widget, getOptionValue(option, "maxLetters"))
                safecall(widget.SetJustifyH, widget, getOptionValue(option, "justifyH") or "LEFT")
                safecall(widget.SetMultiLine, widget, getOptionValue(option, "isMultiLine"))
                safecall(widget.SetValue, widget, getOptionValue(option, "get"))
            elseif optionType == "select" then
                safecall(widget.SetMultiselect, widget, option.isMulti)
                local values = getOptionValue(option, "values")
                safecall(widget.SetValues, widget, values)
                if option.isMulti then
                    for k, v in pairs(values) do -- luacheck: ignore 213
                        safecall(widget.SetValue, widget, k, getOptionValue(option, "get", k))
                    end
                else
                    safecall(widget.SetValue, widget, getOptionValue(option, "get"), true)
                end
                safecall(widget.SetSortByKeys, widget, getOptionValue(option, "sortByKeys"))
                safecall(widget.SetIcons, widget, getOptionValue(option, "icons"))
            elseif optionType == "color" then
                local hasAlpha = option.hasAlpha
                safecall(widget.SetHasAlpha, widget, hasAlpha)
                local r, g, b, a = getOptionValue(option, "get")
                if hasAlpha then
                    safecall(widget.SetValue, widget, r, g, b, a)
                else
                    safecall(widget.SetValue, widget, r, g, b)
                end
            end

            if inLockdown and getOptionValue(option, "noCombat") then
                safecall(widget.Disable, widget)
                safecall(widget.SetIcon, widget, LOCKDOWN_ICON, LOCKDOWN_ICON_COORDS)
            else
                safecall(widget[getOptionValue(option, "disabled") and "Disable" or "Enable"], widget)
                safecall(widget.SetIcon, widget, getOptionValue(option, "icon"), getOptionValue(option, "iconCoords"))
            end

            safecall(widget.ResumeUpdates, widget)
        end

        container:MarkDirty()
    end

    local wipe = wipe

    ---@param option table
    ---@param widgets table<number, Widget>
    ---@param widget Widget
    ---@vararg any
    local function Widget_OnValueChanged(option, widgets, widget, ...)
        local values = packargs(...)
        local set = true

        local onSet = option.onSet
        if type(onSet) == "function" then
            local info = getInfo(option)
            local result = packargs(safecall(onSet, info, ...))
            if result[1] then
                wipe(values)
                for i = 2, result.n do values[#values + 1] = result[i] end
            else
                set = false
            end
            tdel(result)
            tdel(info)
        end

        if set then
            local validate = option.validate
            if type(validate) == "function" then
                local info = getInfo(option)
                local success, result = safecall(validate, info, unpackargs(values))
                set = (success and result) and true
                tdel(info)
            end
        end

        if set then setValue(option, unpackargs(values)) end
        tdel(values)
        updateWidgets(widgets)

        if option.type == "select" and option.isMulti then
            local values = getOptionValue(option, "values") -- luacheck: ignore 421
            safecall(widget.SetValues, widget, values)
            for k, v in pairs(values) do
                safecall(widget.SetValue, widget, k, getOptionValue(option, "get", k))
            end
        end
    end

    local OPTIONTYPE_TO_WIDGET = {
        ["boolean"] = "CheckButton",
        ["color"] = "ColorSelect",
        ["function"] = "Button",
        ["header"] = "Header",
        ["number"] = "Slider",
        ["select"] = "Dropdown",
        ["string"] = "EditBox",
    }

    ---@param optionList table
    ---@param leftPadding number | nil
    ---@param widgets table<number, Widget> | nil
    ---@return table<number, Widget>
    local function createWidgets(optionList, leftPadding, widgets)
        leftPadding = leftPadding or 0
        widgets = widgets or tnew()

        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local optionType = option.type

                local widget

                widget = option.widget
                if type(widget) == "string" then widget = acquireWidget(widget) end

                if not widget or type(widget) ~= "table" or type(widget.GetObjectType) ~= "function" or
                    not widget:GetObjectType("Region") then
                    widget = acquireWidget(OPTIONTYPE_TO_WIDGET[optionType])
                end

                if widget then
                    widget.option = option -- TODO: create a table to hold the option for the widgets (eg. table<widget, option>)

                    safecall(widget.RegisterCallback, widget, "OnValueChanged", Widget_OnValueChanged, option, widgets)

                    widget.layoutIndex = #widgets
                    widget.leftPadding = leftPadding
                    widgets[#widgets + 1] = widget
                end

                if type(option.optionList) == "table" then
                    createWidgets(option.optionList, leftPadding + 15, widgets)
                end
            end
        end

        return widgets
    end

    ---@param widgets table<number, Widget>
    local function releaseAllWidgets(widgets)
        if widgets then
            -- luacheck: push ignore 431
            local tremove = tremove
            local releaseWidget = releaseWidget
            -- luacheck: pop
            for i = #widgets, 1, -1 do releaseWidget(tremove(widgets, i)) end
        end
    end

    ---@type table<number, Panel>
    Lib.panels = Lib.panels or {}
    local panels = Lib.panels

    ---@class Panel : Frame
    local PanelMixin = {}

    local CreateFrame = CreateFrame
    local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory

    function PanelMixin:OnLoad()
        self.widgets = self.widgets or {}

        self:Hide()

        ---@type FontString
        self.text = self.text or self:CreateFontString()
        self.text:SetParent(self)
        self.text:SetDrawLayer("ARTWORK")
        self.text:SetFontObject("GameFontNormalHuge")
        self.text:Show()
        self.text:ClearAllPoints()

        if self.parent then
            ---@type Button
            self.parentButton = self.parentButton or CreateFrame("Button")
            self.parentButton:SetParent(self)
            self.parentButton:Show()
            self.parentButton:SetNormalFontObject("GameFontNormalHuge")
            self.parentButton:SetText(self.parent)
            self.parentButton:ClearAllPoints()
            self.parentButton:SetPoint("TOPLEFT", 16, -16)
            self.parentButton:SetSize(self.parentButton:GetTextWidth(), self.parentButton:GetTextHeight())
            self.parentButton:SetScript("OnClick", function()
                InterfaceOptionsFrame_OpenToCategory(self.parent)
            end)
            self.text:SetPoint("LEFT", self.parentButton, "RIGHT")
            self.text:SetText(" > " .. self.name)
        else
            if self.parentButton then self.parentButton:Hide() end
            self.text:SetPoint("TOPLEFT", 16, -16)
            self.text:SetText(self.name)
        end

        self:SetScript("OnShow", self.OnShow)
        self:SetScript("OnHide", self.OnHide)
        self:SetScript("OnUpdate", self.OnUpdate)
        self:SetScript("OnEvent", self.OnEvent)
    end

    ---@param optionList table
    local function onShow(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onShow, info)
                tdel(info)
                if option.optionList then onShow(option.optionList) end
            end
        end
    end

    local UPDATE_INTERVAL = 0.2 -- should be enough

    ---@param self Panel
    local function OnShow(self)
        frame:SetParent(self)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", 16, -40)
        frame:SetPoint("BOTTOMRIGHT", -26, 3)
        frame:Show()

        if self.refreshed then
            releaseAllWidgets(self._widgets)
            self._widgets = createWidgets(self._optionList)
            onShow(self._optionList)
        end
        self.lastUpdate = UPDATE_INTERVAL
    end

    ---@type table<number, string>
    local EVENTS = {"PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"}

    function PanelMixin:OnShow()
        for i = 1, #EVENTS do self:RegisterEvent(EVENTS[i]) end
        xsafecall(OnShow, self)
    end

    ---@param optionList table
    local function onHide(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onHide, info)
                tdel(info)
                if option.optionList then onHide(option.optionList) end
            end
        end
    end

    ---@param self Panel
    local function OnHide(self) releaseAllWidgets(self._widgets) end

    function PanelMixin:OnHide()
        self:UnregisterAllEvents()
        xsafecall(OnHide, self)
    end

    ---@param optionList table
    ---@param elapsed number
    local function onUpdate(optionList, elapsed)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                option.lastUpdate = (option.lastUpdate or (option.onUpdateInterval or UPDATE_INTERVAL)) + elapsed
                if option.lastUpdate >= (option.onUpdateInterval or UPDATE_INTERVAL) then
                    option.lastUpdate = 0
                    local info = getInfo(option)
                    safecall(option.onUpdate, info)
                    tdel(info)
                end
                if type(option.optionList) == "table" then onUpdate(option.optionList, elapsed) end
            end
        end
    end

    ---@param self table
    ---@param elapsed number
    local function OnUpdate(self, elapsed)
        onUpdate(self._optionList, elapsed)

        self.lastUpdate = (self.lastUpdate or 0) + elapsed
        if self.lastUpdate >= UPDATE_INTERVAL then
            self.lastUpdate = 0
            updateWidgets(self._widgets)
        end
    end

    ---@param elapsed number
    function PanelMixin:OnUpdate(elapsed) xsafecall(OnUpdate, self, elapsed) end

    ---@param event string
    ---@vararg any
    function PanelMixin:OnEvent(event, ...) updateWidgets(self._widgets) end

    ---@param optionList table
    local function onOkay(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onOkay, info)
                tdel(info)
                if type(option.optionList) == "table" then onOkay(option.optionList) end
            end
        end
    end

    ---@param self Panel
    local function okay(self)
        self.refreshed = nil

        onOkay(self._optionList)

        self._optionList = tdel(self._optionList)
        self._oldValues = tdel(self._oldValues)
    end

    function PanelMixin:okay() xsafecall(okay, self) end

    ---@param optionList table
    local function onCancel(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onCancel, info)
                tdel(info)
                if option.optionList then onCancel(option.optionList) end
            end
        end
    end

    ---@param values table
    local function setValues(values)
        for option, value in pairs(values) do
            if option.type == "select" and option.isMulti then
                for k, v in pairs(value) do setValue(option, k, v) end
            elseif option.type == "color" then
                if option.hasAlpha then
                    setValue(option, value.r, value.g, value.b, value.a)
                else
                    setValue(option, value.r, value.g, value.b)
                end
            else
                setValue(option, value)
            end
        end
    end

    ---@param self Panel
    local function cancel(self)
        self.refreshed = nil

        onCancel(self._optionList)
        setValues(self._oldValues)

        self._optionList = tdel(self._optionList)
        self._oldValues = tdel(self._oldValues)
    end

    function PanelMixin:cancel() xsafecall(cancel, self) end

    ---@param optionList table
    local function onDefault(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onDefault, info)
                tdel(info)
                if type(option.optionList) == "table" then onDefault(option.optionList) end
            end
        end
    end

    ---@param self Panel
    local function default(self)
        self.refreshed = nil

        onDefault(self._optionList)
        setDefaults(self._optionList)

        self._optionList = tdel(self._optionList)
        self._oldValues = tdel(self._oldValues)
        releaseAllWidgets(self._widgets)
    end

    function PanelMixin:default() xsafecall(default, self) end

    ---@param optionList table
    local function onRefresh(optionList)
        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local info = getInfo(option)
                safecall(option.onRefresh, info)
                tdel(info)
                if type(option.optionList) == "table" then onRefresh(option.optionList) end
            end
        end
    end

    ---@param optionList table
    ---@param parent any
    ---@return table
    local function copyOptionList(optionList, parent)
        local newOptionList = tnew()

        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]
            if option then
                local newOption = tnew()
                newOption.handler = option.handler or optionList.handler or (parent and parent.handler)
                newOption.parent = parent or optionList
                for k, v in pairs(option) do
                    if k ~= "handler" and k ~= "parent" and k ~= "optionList" then newOption[k] = v end
                end
                if option.optionList then
                    newOption.optionList = copyOptionList(option.optionList, newOption)
                end
                newOptionList[i] = newOption
            end
        end

        return newOptionList
    end

    ---@param optionList table
    ---@param values table | nil
    ---@return table
    local function getValues(optionList, values)
        if not values then values = tnew() end

        for i = 1, (optionList.n or #optionList) do
            local option = optionList[i]

            if option.type == "select" and option.isMulti then
                values[option] = tnew()
                for k, v in pairs(getOptionValue(option, "values") or tnew()) do
                    values[option][k] = getOptionValue(option, "get", k)
                end
            elseif option.type == "color" then
                values[option] = tnew()
                values[option].r, values[option].g, values[option].b, values[option].a = getOptionValue(option, "get")
                if not option.hasAlpha then values[option].a = nil end
            else
                values[option] = getOptionValue(option, "get")
            end

            if option.optionList then getValues(option.optionList, values) end
        end

        return values
    end

    ---@param self Panel
    local function refresh(self)
        local optionList = copyOptionList(self.optionList)
        self._optionList = optionList

        onRefresh(optionList)
        self._oldValues = getValues(optionList)

        self.refreshed = true

        if self:IsVisible() then
            releaseAllWidgets(self._widgets)
            self._widgets = createWidgets(optionList)
            onShow(optionList)
        end
    end

    function PanelMixin:refresh() xsafecall(refresh, self) end

    for i = 1, #panels do LibMixin:Mixin(panels[i], PanelMixin) end -- upgrade

    local InterfaceAddOnsList_Update = InterfaceAddOnsList_Update
    local InterfaceOptionsFrame = InterfaceOptionsFrame
    local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory

    --[[ List of option attributes
    ==============================================================================
    Note: All functions are called with 'info' as first argument.
    ------------------------------------------------------------------------------
    option.type = [string]
    option.widget = [string, frame, nil]
    option.text = [string, function]
    option.get = [any]
    option.set = [any]
    option.default = [any]
    option.arg = [any]
    option.tooltip = [string, function]
    option.noCombat = [boolean, function]
    option.hidden = [boolean, function]
    option.disabled = [boolean, function]
    option.icon = [string, function]
    option.iconCoords = [number[], function]
    option.optionList = [table]
    option.handler = [table] -- inherited
    option.path = [any]

        --------------------------------------------------------------------------
        -- type == "boolean"
        --------------------------------------------------------------------------
        option.isRadio = [boolean, function] -- not implemented yet

        --------------------------------------------------------------------------
        -- type == "header"
        --------------------------------------------------------------------------

        --------------------------------------------------------------------------
        -- type == "number"
        --------------------------------------------------------------------------
        option.isPercent = [boolean, function]
        option.step = [number, function]
        option.min = [number, function]
        option.max = [number, function]
        option.minText = [string, function]
        option.maxText = [string, function]

        --------------------------------------------------------------------------
        -- type == "function"
        --------------------------------------------------------------------------
        option.func = [function]

        --------------------------------------------------------------------------
        -- type == "string"
        --------------------------------------------------------------------------
        option.isReadOnly = [boolean, function]
        option.maxLetters = [number, function]
        option.justifyH = [string, function]
        option.isMultiLine = [boolean, function]

        --------------------------------------------------------------------------
        -- type == "select"
        --------------------------------------------------------------------------
        option.values = [table<any, string>, function]
        option.isMulti = [boolean]

        --------------------------------------------------------------------------
        -- type == "color"
        --------------------------------------------------------------------------
        option.hasAlpha = [boolean]
    ]]

    ---@param name string
    ---@param parent string
    ---@param optionList table
    function Lib:New(name, parent, optionList)
        if type(name) ~= "string" then
            error(format("Usage: %s:New(name[, parent], optionList): 'name' - string expected got %s", tostring(Lib),
                         type(name)), 2)
        end
        if type(parent) == "table" then optionList, parent = parent, nil end
        if type(parent) ~= "string" and type(parent) ~= "nil" then
            error(format("Usage: %s:New(name[, parent], optionList): 'parent' - string or nil expected got %s",
                         tostring(Lib), type(parent)), 2)
        end
        if type(optionList) ~= "table" then
            error(format("Usage: %s:New(name[, parent], optionList): 'optionList' - table expected got %s",
                         tostring(Lib), type(optionList)), 2)
        end

        ---@type Panel
        local panel = LibMixin:Mixin(CreateFrame("Frame"), {name = name, parent = parent, optionList = optionList},
                                     PanelMixin)

        panels[#panels + 1] = panel

        InterfaceOptions_AddCategory(panel)

        if InterfaceOptionsFrame:IsShown() then
            panel:refresh()
            InterfaceAddOnsList_Update()
        end
    end
    setmetatable(Lib, {__call = Lib.New})
end

--[[ do -- InterfaceOptionsFrame
    local OptionsListButtonToggle_OnClick = OptionsListButtonToggle_OnClick

    ---@param self Button
    ---@param button string
    local function OnDoubleClick(self, button)
        ---@type Button
        local toggle = self.toggle
        if toggle:IsShown() and button == "LeftButton" then OptionsListButtonToggle_OnClick(toggle) end
    end

    do
        local i = 1
        while _G["InterfaceOptionsFrameAddOnsButton" .. i] do
            (_G["InterfaceOptionsFrameAddOnsButton" .. i]):HookScript("OnDoubleClick", OnDoubleClick)
            i = i + 1
        end
    end
end ]]
