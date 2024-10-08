
KeybindWindow = class(Turbine.UI.Lotro.Window);

Mouse2 = 19;

function KeybindWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor( self )

    self:SetText("Set Birding Keybind");


    local width = 400;
    local height = 200;
    self:SetSize(width, height);

    local textBox = Turbine.UI.TextBox();
    textBox:SetParent(self);
    textBox:SetSize(width - 50, height - 50);
    textBox:SetPosition(25, 25);
    textBox:SetText("Press the key you use to activate the 'Birding' hobby.\n\nClick on this window to cancel.");
    textBox:SetFont(Turbine.UI.Lotro.Font.TrajanProBold22);
    textBox:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
    textBox:SetForeColor(Turbine.UI.Color.Yellow);
    textBox:SetMouseVisible(false);

    local displayWidth, displayHeight = Turbine.UI.Display:GetSize();
    self:SetPosition(displayWidth / 2 - width / 2, displayHeight / 2 - height / 2);

    self:SetWantsKeyEvents(false);
    self:SetMouseVisible(false);

    self.MouseClick = function(sender, args)
        self:SetVisible(false);
    end

    self.KeyDown = function(sender, args)
        -- Secondary mouse button also comes through KeyDown.
        if (args.Action == Mouse2) then
            self:SetVisible(false);
            return;
        end

        local actionName = GetActionName(args.Action);

        -- ignore unknown actions:
        if (not actionName) then return; end
        Turbine.Shell.WriteLine(actionName);

        -- Don't pay attention to QuickBar 1-5 Visibility:
        if (IsActionQuickbarVisibility(args.Action)) then
            return;
        end

        -- It not a special key, treat it as the new shortcut key:
        OP.KeybindTextbox:SetText(actionName);
        BirdingLogWindowInstance:SetActionKey(args.Action)

        -- Need to save it:
        CharacterSettings["BIRDING_ACTION"] = args.Action;

        self:SetVisible(false);

        -- Trigger the timer window:
        BirdingLogWindowInstance.TimerControl:TimerStart();
    end
end

---Returns the enum name as a string, or nil
---@param action number
---@return string?
function GetActionName(action)
    for key, value in pairs(Turbine.UI.Lotro.Action) do
        if (value == action) then
            return tostring(key);
        end
    end
    return nil;
end

---Returns true if the action is a quickbar visibility shortcut, or false.
---@param action number
---@return boolean
function IsActionQuickbarVisibility(action)
    if (
        action == Turbine.UI.Lotro.Action.Quickbar1Visibility or
        action == Turbine.UI.Lotro.Action.Quickbar2Visibility or
        action == Turbine.UI.Lotro.Action.Quickbar3Visibility or
        action == Turbine.UI.Lotro.Action.Quickbar4Visibility or
        action == Turbine.UI.Lotro.Action.Quickbar5Visibility
    ) then
        return true;
    end
    return false;
end

function KeybindWindow:SetVisible(visible)
	Turbine.UI.Lotro.Window.SetVisible( self, visible )
    self:SetWantsKeyEvents(visible);
    self:SetMouseVisible(visible);

    if (visible) then
        local width, height = self:GetSize();
        local displayWidth, displayHeight = Turbine.UI.Display:GetSize();
        self:SetPosition(displayWidth / 2 - width / 2, displayHeight / 2 - height / 2);
    end
end

KeybindWindowInstance = KeybindWindow();