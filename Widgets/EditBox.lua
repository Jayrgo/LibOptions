local _NAME = "EditBox"
local _VERSION = "1.0.0" -- The version is updated automatically.
_VERSION = LibMan1.Version:New(_VERSION)

---@class EditBoxWidget : Widget
local WidgetMixin --[[ , oldVersion ]] = LibMan1:Get("LibOptions", _VERSION.major):RegisterWidget(_NAME,
                                                                                                  tostring(_VERSION))
if not WidgetMixin then return end -- return if no upgrade is needed

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local LibMixin = LibMan1:Get("LibMixin", 1)
local BackdropTemplateMixin = BackdropTemplateMixin
local CreateFrame = CreateFrame

function WidgetMixin:OnLoad()
    self.OnLoad = nil

    ---@type Frame
    self.backdropFrame = self.backdropFrame or
                             LibMixin:CreateFrame("Frame", nil, self, nil, nil, isRetail and BackdropTemplateMixin or {})
    self.backdropFrame:SetParent(self)
    self.backdropFrame.backdropInfo = {
        bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = false,
        tileEdge = false,
        tileSize = 16,
        edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    }
    if isRetail then
        self.backdropFrame:ApplyBackdrop()
    else
        self.backdropFrame:SetBackdrop(self.backdropFrame.backdropInfo)
    end
    self.backdropFrame:SetBackdropColor(0, 0, 0, 0.5)
    self.backdropFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    ---@type EditBox
    self.editBox = self.editBox or CreateFrame("EditBox", nil, self)
    self.editBox:SetParent(self)
    self.editBox:SetFontObject("GameFontHighlightSmall")
    self.editBox:SetAutoFocus(false)
    self.editBox:EnableMouse(true)
    self.editBox:SetCountInvisibleLetters(true)
    self.editBox:SetTextInsets(4, 4, 4, 4)
    self.editBox:ClearAllPoints()
    self.editBox:SetPoint("TOPLEFT", self, "TOP", 2, -2)
    self.editBox:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, -2)
    self.editBox.UpdateTooltip = self.EditBox_UpdateTooltip
    self.editBox:SetScript("OnEscapePressed", self.EditBox_OnEscapePressed)
    self.editBox:SetScript("OnEnterPressed", self.EditBox_OnEnterPressed)
    self.editBox:SetScript("OnTextChanged", self.EditBox_OnTextChanged)
    self.editBox:SetScript("OnTextSet", self.EditBox_OnTextSet)
    self.editBox:SetScript("OnEditFocusGained", self.EditBox_OnEditFocusGained)
    self.editBox:SetScript("OnEditFocusLost", self.EditBox_OnEditFocusLost)

    ---@type FontString
    self.charLimitText = self.charLimitText or self:CreateFontString()
    self.charLimitText:SetParent(self)
    self.charLimitText:SetDrawLayer("OVERLAY")
    self.charLimitText:ClearAllPoints()
    self.charLimitText:SetPoint("BOTTOMLEFT", self, "BOTTOM", 2, 2)
    self.charLimitText:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 2)
    self.charLimitText:SetFontObject("GameFontHighlightSmall")
    self.charLimitText:Hide()

    ---@type FontString
    self.readOnlyText = self.readOnlyText or self:CreateFontString()
    self.readOnlyText:SetParent(self)
    self.readOnlyText:SetDrawLayer("OVERLAY")
    self.readOnlyText:ClearAllPoints()
    self.readOnlyText:SetPoint("LEFT", self, "CENTER", 2, 0)
    self.readOnlyText:SetPoint("RIGHT", self, "RIGHT", -2, 0)
    self.readOnlyText:SetFontObject("GameFontHighlightSmall")

    self.backdropFrame:ClearAllPoints()
    self.backdropFrame:SetPoint("TOPLEFT", self.editBox, "TOPLEFT", 0, 0)
    self.backdropFrame:SetPoint("BOTTOMRIGHT", self.editBox, "BOTTOMRIGHT", 0, 0)
end

function WidgetMixin:OnDisable()
    self.editBox:Disable()
    self.editBox:SetFontObject("GameFontDisableSmall")
    self.charLimitText:SetFontObject("GameFontDisableSmall")
    self.readOnlyText:SetFontObject("GameFontDisableSmall")
end

function WidgetMixin:OnEnable()
    self.editBox:Enable()
    self.editBox:SetFontObject("GameFontHighlightSmall")
    self.charLimitText:SetFontObject("GameFontHighlightSmall")
    self.readOnlyText:SetFontObject("GameFontHighlightSmall")
end

---@return string
function WidgetMixin:GetValue() return self.editBox:GetText() end

---@param value string
function WidgetMixin:OnSetValue(value)
    local editBox = self.editBox
    if not editBox:HasFocus() then
        value = value or ""
        if value ~= editBox:GetText() then
            editBox:SetText(value)
            editBox:SetCursorPosition(0)
        end
    end
end

---@param isReadOnly boolean
function WidgetMixin:SetReadOnly(isReadOnly)
    self.editBox:SetShown(not isReadOnly)
    self.readOnlyText:SetShown(isReadOnly)
    self.backdropFrame:SetShown(not isReadOnly)

    self:UpdateSize()
end

local ScrollingEdit_SetCursorOffsets = ScrollingEdit_SetCursorOffsets

---@param isMultiLine boolean
function WidgetMixin:SetMultiLine(isMultiLine)
    local editBox = self.editBox
    if editBox:IsMultiLine() ~= isMultiLine then

        editBox:SetMultiLine(isMultiLine)

        if isMultiLine then
            editBox:SetScript("OnEnterPressed", nil)
            editBox:SetScript("OnKeyDown", self.EditBox_OnKeyDown)
            editBox:SetScript("OnEnter", self.EditBox_OnEnter)
            editBox:SetScript("OnLeave", self.EditBox_OnLeave)
        else
            editBox:SetScript("OnEnterPressed", self.EditBox_OnEnterPressed)
            editBox:SetScript("OnKeyDown", nil)
            editBox:SetScript("OnEnter", nil)
            editBox:SetScript("OnLeave", nil)
        end
    end
    self:UpdateSize()
end

---@param justifyH string | "\"LEFT\"" | "\"CENTER\"" | "\"RIGHT\""
function WidgetMixin:SetJustifyH(justifyH)
    local editBox = self.editBox
    local readOnlyText = self.readOnlyText
    if editBox:GetJustifyH() ~= justifyH then editBox:SetJustifyH(justifyH) end
    if readOnlyText:GetJustifyH() ~= justifyH then readOnlyText:SetJustifyH(justifyH) end
end

---@param maxLetters number
function WidgetMixin:SetMaxLetters(maxLetters)
    maxLetters = maxLetters or 255
    local editBox = self.editBox
    if editBox:GetMaxLetters() ~= maxLetters then editBox:SetMaxLetters(maxLetters) end
end

local max = max

function WidgetMixin:UpdateSize()
    local editBox = self.editBox
    if editBox:IsShown() then
        local charLimitText = self.charLimitText

        if editBox:IsMultiLine() then
            self:SetHeight(editBox:GetHeight() + 4 + (charLimitText:IsShown() and charLimitText:GetHeight() or 0))
        else
            editBox:SetHeight(18.3)
            self:SetHeight(22.3 + (charLimitText:IsShown() and charLimitText:GetHeight() or 0))
        end
    else
        local height = max(20, self.readOnlyText:GetHeight())
        if (self:GetHeight() - 4) ~= height then self:SetHeight(height + 4) end
    end
end

function WidgetMixin:EditBox_OnEscapePressed()
    -- self == editBox
    self:ClearFocus()
end

function WidgetMixin:EditBox_OnEnterPressed()
    -- self == editBox
    local parent = self:GetParent()

    parent.callbacks:TriggerEvent("OnValueChanged", parent, self:GetText())

    self:ClearFocus()
end

local gsub = gsub
local CHAR_LIMIT_TEXT = gsub(gsub(MACROFRAME_CHAR_LIMIT, "255", "{max_chars}"), "%%d", "{current_chars}")

---@param isUserInput boolean
function WidgetMixin:EditBox_OnTextChanged(isUserInput)
    -- self == editBox
    local parent = self:GetParent()

    parent.readOnlyText:SetText(self:GetText())
    parent.charLimitText:SetText(gsub(gsub(CHAR_LIMIT_TEXT, "{current_chars}", self:GetNumLetters()), "{max_chars}", self:GetMaxLetters()))
    if isUserInput then parent:UpdateSize() end
end

function WidgetMixin:EditBox_OnTextSet()
    -- self == editBox
    local parent = self:GetParent()

    parent.readOnlyText:SetText(self:GetText())
    parent:UpdateSize()
end

function WidgetMixin:EditBox_OnEditFocusGained()
    -- self == editBox
    local parent = self:GetParent()

    parent.charLimitText:Show()
end

function WidgetMixin:EditBox_OnEditFocusLost()
    -- self == editBox
    local parent = self:GetParent()

    parent.charLimitText:Hide()
    self:HighlightText(0, 0)
end

local IsAltKeyDown = IsAltKeyDown

---@param key string
function WidgetMixin:EditBox_OnKeyDown(key)
    -- self == editBox
    if key == "ENTER" and not IsAltKeyDown() then self:GetParent().EditBox_OnEnterPressed(self) end
end

local GameTooltip = GameTooltip
local LINE_BREAK = "Line break: ALT+Enter"
if GetLocale() == "deDE" then LINE_BREAK = "Zeilenumbruch: Alt+Eingabe" end

---@param motion boolean
function WidgetMixin:EditBox_OnEnter(motion)
    -- self == editBox
    if not self:HasFocus() then return end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -self:GetHeight())
    GameTooltip:SetText(LINE_BREAK)
    GameTooltip:Show()
end

---@param motion boolean
function WidgetMixin:EditBox_OnLeave(motion)
    -- self == editBox
    GameTooltip:Hide()
end

function WidgetMixin:EditBox_UpdateTooltip()
    -- self == editBox
    if not self:HasFocus() then return end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, -self:GetHeight())
    GameTooltip:SetText(LINE_BREAK)
    GameTooltip:Show()
end
