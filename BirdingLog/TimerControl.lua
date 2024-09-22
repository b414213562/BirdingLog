-- Inspired by the TimerControl from Festival Buddy II

-- This class shows the 30-second birding timer plus 3 second skill cooldown divided into four sections.
-- Seconds:
--    0-10       10-20      20-30    30-33
-- [          |          |          |   ]

TimerControl = class( Turbine.UI.Control )

function TimerControl:Constructor()
    Turbine.UI.Control.Constructor( self )

    self.SkillDuration = 30;
    self.SkillCooldownTime = 2.75;
    self.PrecisionPoint = 0; -- seconds
    self.activateAction = nil;
    self.IsStopped = true;
    self.IsBirdingEquipped = self:IsBirdingEquipmentEquipped();
    self.PreviousUpdateTime = 0;
    self.ElapsedTime = 0;

    local equipment = player:GetEquipment();
    equipment.ItemEquipped = function(sender, args)
        self:ItemEquipped(sender, args);
    end
    equipment.ItemUnequipped = function(sender, args)
        self:ItemUnequipped(sender, args);
    end

    local width = 200;

    local lefts = self:GetLefts(width);

    -- Create sections of a visual timer for the Birding Skill:
    -- 30 seconds plus a 3 second cooldown
    self.stopwatchControls = {};
    for i=1, 4 do
        self.stopwatchControls[i] = self:CreateTimerSection(lefts[i], lefts[i+1] - lefts[i], Turbine.UI.Color.Green);
    end
    self.stopwatchControls[4]:SetBackColor(Turbine.UI.Color.Red);

    -- Vertical lines to divide sections:
    self.timeLines = {
        [1] = self:CreateTimeLine(lefts[2]);
        [2] = self:CreateTimeLine(lefts[3]);
        [3] = self:CreateTimeLine(lefts[4]);
    };

    self.timerText = Turbine.UI.Label();
    self.timerText:SetParent(self);
    self.timerText:SetFont(Turbine.UI.Lotro.Font.TrajanPro20);
    self.timerText:SetFontStyle(Turbine.UI.FontStyle.Outline);
    self.timerText:SetForeColor(Turbine.UI.Color.White);
    self.timerText:SetOutlineColor(Turbine.UI.Color.Black);
    self.timerText:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
    self.timerText:SetSize(lefts[4], 40);

    self:SetWantsKeyEvents( true )
    self.KeyDown = function(sender, args)
        if (self.activateAction) then
            local keyMatches =
                self.activateAction == args.Action and
                self.activateActionCtrl == args.Control and
                self.activateActionAlt == args.Alt and
                self.activateActionShift == args.Shift;

            if (keyMatches and self.IsBirdingEquipped) then
                -- Either we need to start the timer, or mark the current birding chance completed
                self:ActionKeyRecieved();
            end
        end
    end

    self.Update = function(sender, args)
        if (self.IsStopped) then
            self:SetWantsUpdates(false);
            self:SetVisible(false);
        end

        local duration = self.SkillDuration + self.SkillCooldownTime;
        local currentTime = Turbine.Engine.GetGameTime();
        self.ElapsedTime = currentTime - self.TimerStartTime;
        local remainingTime = duration - self.ElapsedTime;

        local isPrecise = remainingTime < self.PrecisionPoint;
        local updateInterval = 0.1;
        if (isPrecise) then updateInterval = 0.05; end

        -- Timer is done, shut it off:
        if (self.ElapsedTime > duration) then
            self:TimerStop();
        -- Update the UI, but not every frame:
        elseif (currentTime > self.PreviousUpdateTime + updateInterval) then
            self.PreviousUpdateTime = currentTime;

            -- We have four sections that can act independently.
            -- The following logic updates the correct section.
            local controlDetails = self:GetCurrentTimerControl(self.ElapsedTime);

            local missingWidth = ((controlDetails.timeInSection / controlDetails.sectionDuration) * controlDetails.control.TotalWidth);
            local width = controlDetails.control.TotalWidth - missingWidth;
            controlDetails.control:SetWidth(width);
            controlDetails.control:SetLeft(controlDetails.control.Left + missingWidth);

            self.timerText:SetText(string.format("%.1f", self.ElapsedTime));
        end

    end

end

---Gets the current section plus other information based on the elapsed time.
---@param elapsedTime number
---@return table
function TimerControl:GetCurrentTimerControl(elapsedTime)
    local result = {};
    result.control = nil;
    result.sectionDuration = 10;
    result.timeInSection = elapsedTime;

    if (elapsedTime < 10) then
        -- first section
        result.control = self.stopwatchControls[1];
    elseif (elapsedTime < 20) then
        -- second section
        result.control = self.stopwatchControls[2];
        result.timeInSection = elapsedTime - 10;
    elseif (elapsedTime < 30) then
        -- third section
        result.control = self.stopwatchControls[3];
        result.timeInSection = elapsedTime - 20;
    else
        -- final section
        result.control = self.stopwatchControls[4];
        result.sectionDuration = self.SkillCooldownTime;
        result.timeInSection = elapsedTime - 30;
    end
    return result;
end

--- Returns true if a birding kit is equipped
---@return boolean #true if birding kit is equipped, false if not
function TimerControl:IsBirdingEquipmentEquipped()
    local equipment = player:GetEquipment();
    local item = equipment:GetItem(Turbine.Gameplay.Equipment.PrimaryWeapon);

    -- If nothing is equipped, don't look further:
    if (item == nil) then return false; end

    -- Otherwise, check for a matching item:
    local name = item:GetName();
    local toolPattern = "Birding Kit";

    local isBirdingEquipped = string.find(name, toolPattern) ~= nil;

    return isBirdingEquipped;
end

function TimerControl:ItemEquipped(sender, args)
    if (args.Index == Turbine.Gameplay.Equipment.PrimaryWeapon) then
        self.IsBirdingEquipped = self:IsBirdingEquipmentEquipped();
    end
end

function TimerControl:ItemUnequipped(sender, args)
    -- If our primary weapon is unequipped, 
    -- then either it is being swapped and this will be followed by an ItemEquipped call,
    -- or it is being removed and there will not be another event.
    -- Either way, until that other item is equipped there cannot be a birding kit equipped.
    if (args.Index == Turbine.Gameplay.Equipment.PrimaryWeapon) then
        self.IsBirdingEquipped = false;
    end
end

function TimerControl:CreateTimerSection(left, width, color)
    local stopwatchControl = Turbine.UI.Control();
    stopwatchControl:SetParent(self);
    stopwatchControl:SetTop(10);
    stopwatchControl:SetLeft(left);
    stopwatchControl:SetSize(width, 20);
    stopwatchControl:SetBackColor(color);
    stopwatchControl.Left = left;
    stopwatchControl.TotalWidth = width;

    return stopwatchControl;
end

function TimerControl:SetActionKey(action, hasCtrl, hasAlt, hasShift)
    self.activateAction = action;
    self.activateActionCtrl = hasCtrl;
    self.activateActionAlt = hasAlt;
    self.activateActionShift = hasShift;
end

function TimerControl:GetLefts(width)
    local totalDuration = self.SkillDuration + self.SkillCooldownTime;

    local lefts = {
        [1] = 0;
        [2] = width * 10 / totalDuration;
        [3] = width * 20 / totalDuration;
        [4] = width * 30 / totalDuration;
        [5] = width;
    }
    return lefts;
end

function TimerControl:CreateTimeLine(left)
    -- Vertical line for first 10 seconds:
    local timeLine = Turbine.UI.Control();
    timeLine:SetParent(self);
    timeLine:SetBackColor(Turbine.UI.Color.White);
    timeLine:SetSize(2, 40);
    timeLine:SetLeft(left);

    return timeLine;
end

function TimerControl:SetWidth(width)
    Turbine.UI.Control.SetWidth( self, width )

    -- Do our custom width stuff:
    self:UpdateControlWidths(width);
end

function TimerControl:SetSize(width, height)
    Turbine.UI.Control.SetSize( self, width, height )

    -- Do our custom size stuff:
    self:UpdateControlWidths(width);
end

function TimerControl:UpdateControlWidths(width)
    local lefts = self:GetLefts(width);

    for i=1,#self.stopwatchControls do
        self.stopwatchControls[i]:SetLeft(lefts[i]);
        local width = lefts[i+1]-lefts[i];
        self.stopwatchControls[i]:SetWidth(width);
        self.stopwatchControls[i].TotalWidth = width;
        self.stopwatchControls[i].Left = lefts[i];
    end
    for i=1,#self.timeLines do
        self.timeLines[i]:SetLeft(lefts[i+1] - 1);
    end
    self.timerText:SetWidth(lefts[4]);
end

function TimerControl:ActionKeyRecieved()
    if (self.IsStopped) then
        -- Activate the timer!
        self:TimerStart();
    else
        -- Mark the current section complete:
        self:MarkSectionComplete();
    end
end

function TimerControl:TimerStart()
    -- Birding is a go!
    self.TimerStartTime = Turbine.Engine.GetGameTime();
    self.IsStopped = false;

    self:SetVisible(true);

    for i=1, 4 do
        self.stopwatchControls[i]:SetBackColor(Turbine.UI.Color.Orange);
        self.stopwatchControls[i]:SetWidth(self.stopwatchControls[i].TotalWidth);
        self.stopwatchControls[i]:SetLeft(self.stopwatchControls[i].Left);
    end
    self.stopwatchControls[4]:SetBackColor(Turbine.UI.Color.Red);

    self:SetWantsUpdates(true);
end

function TimerControl:MarkSectionComplete()
    -- Re-birding observed!
    local controlDetails = self:GetCurrentTimerControl(self.ElapsedTime - 0.25);
    controlDetails.control:SetBackColor(Turbine.UI.Color.DarkGreen);
end

function TimerControl:TimerStop()
    self.IsStopped = true;
end

function TimerControl:BirdFound()
    self:TimerStop();
end
