-- Birding Log window handler
-- coding: utf-8 '�

import "Turbine.UI.Lotro"
import "Vinny.Common"
import "Vinny.Common.DropMenu"
import "Vinny.Common.ToolTip"
import "Vinny.BirdingLog.TimerControl"

local labelFont = Turbine.UI.Lotro.Font.Verdana14
local foreColor = Turbine.UI.Color( 0.9, 0.9, 0 )
local whiteColor = Turbine.UI.Color( 1.0, 1.0, 1.0 )
local backColor = Turbine.UI.Color( 0.0, 0.0, 0.0 )
local greyColor = Turbine.UI.Color( 0.1, 0.1, 0.1 )
local Button = Turbine.UI.Lotro.Button
local Label = Turbine.UI.Label
local TextBox = Turbine.UI.TextBox
local CheckBox = Turbine.UI.Lotro.CheckBox
local DropMenu = Vinny.Common.DropMenu
local Item = Turbine.UI.Lotro.ShortcutType.Item
local Hobby = Turbine.UI.Lotro.ShortcutType.Hobby
local Alias = Turbine.UI.Lotro.ShortcutType.Alias
local Shortcut = Turbine.UI.Lotro.Shortcut
local Quickslot = Turbine.UI.Lotro.Quickslot
local Qsize = 34
local Blank

BirdingLogWindow = class( Turbine.UI.Lotro.Window )

function BirdingLogWindow:AddField(control, text, pos, size)
	local field = control()
	field:SetParent( self )
	if text then field:SetText( text ) end
	field:SetPosition( pos.x,pos.y )
	field:SetSize( size.x,size.y )
	if control==Button or control==DropMenu or not text then return field end
	field:SetFont( labelFont )
	field:SetForeColor( text=="" and whiteColor or foreColor )
	local grey = control==TextBox or control==Quickslot
	field:SetBackColor( grey and greyColor or backColor )
	field:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft )
	return field
end

function BL_Shortcut(sender,name,iname)
	local shortcut = sender:GetShortcut()
	local itemType = shortcut:GetType()
	if itemType==0 then return end
	local itemData = shortcut:GetData()
	if sender:IsAltKeyDown() then print("Type="..itemType..", Data="..itemData) end
	if itemType~=Item then 
		sender:SetShortcut(Blank) 
		print(name.." reset.")
		return 
	end
	local Item = shortcut:GetItem()
	if not Item then printe("Item is null.") return end
	if iname and Item:GetName():sub(-#iname)~=iname then
		printe(Item:GetName().." is not a "..iname)
		sender:SetShortcut(Blank)
		return
	end
	print(name.." set to "..Item:GetName())
	return itemData
end

function BirdingLogWindow:Constructor()
	Turbine.UI.Lotro.Window.Constructor( self )

	-- Position the window near the top center of the screen.
	self:SetSize( 340,300 )
--	self:SetBackColor( Turbine.UI.Color() )
	self:SetPosition( CharacterSettings["BL_Window"]["X"], CharacterSettings["BL_Window"]["Y"] )
	self:SetText( "Birding Log" )
	self:SetVisible( CharacterSettings["BL_Window"]["VISIBLE"] )

-- Hobby:Birding action is Type=Hobby(9), Data=0x7000EE1E

	-- Create a Name field
	self.name = self:AddField(Label, "Birding kit:", {x=37,y=47}, {x=80,y=16} )
	self.name:SetFont(Turbine.UI.Lotro.Font.TrajanPro18)

	-- Create an kit field
	self.kit = self:AddField(Quickslot, nil, {x=115,y=40}, {x=Qsize,y=Qsize} )
	Blank = self.kit:GetShortcut()
	if Totals.kit then self.kit:SetShortcut( Shortcut(Item,Totals.kit) ) 
	else self.kit:SetBackground("Vinny/BirdingLog/Kit.tga") end
	self.kit.ShortcutChanged = function( sender, args )
		Totals.kit = BL_Shortcut(sender,"Birding Kit","Birding Kit")
	end

	-- Create a birding label
	self:AddField(Label, "Spot bird:", {x=185,y=45}, {x=70,y=16} )

	-- Create an birding field
	self.fish = self:AddField(Quickslot, nil, {x=255,y=40}, {x=Qsize,y=Qsize} )
	self.fish:SetShortcut( Shortcut(Hobby,"0x7006B1F4") )
    self.fish:SetAllowDrop( false )
	self.fish.MouseEnter = function( sender, args ) Track = true end
	self.fish.MouseLeave = function( sender, args ) Track = false end

	-- Create a weapon label
	self:AddField(Label, "Weapon:", {x=45,y=95}, {x=70,y=16} )

	-- Create an weapon field, weapon slot=16, cat=104
	self.weapon = self:AddField(Quickslot, nil, {x=115,y=90}, {x=Qsize,y=Qsize} )
	if Totals.wpn then self.weapon:SetShortcut( Shortcut(Item,Totals.wpn) ) 
	else self.weapon:SetBackground("Vinny/BirdingLog/Sword.tga") end
	self.weapon.ShortcutChanged = function( sender, args )
		Totals.wpn = BL_Shortcut(sender,"Weapon")
	end

	-- Create a Shield label
	self:AddField(Label, "2nd slot:", {x=190,y=95}, {x=60,y=16} )

	-- Create an shield field, shield slot=17
	self.shield = self:AddField(Quickslot, nil, {x=255,y=90}, {x=Qsize,y=Qsize} )
	if Totals.shl then self.shield:SetShortcut( Shortcut(Item,Totals.shl) ) 
	else self.shield:SetBackground("Vinny/BirdingLog/Shield.tga") end
	self.shield.ShortcutChanged = function( sender, args )
		Totals.shl = BL_Shortcut(sender,"2nd")
	end

	-- Create a set location button
	self.locButton = self:AddField(Button, "Set Zone", {x=30,y=140}, {x=125,y=20} )
	local slot = Turbine.UI.Lotro.Quickslot()
	slot:SetParent( self.locButton )
    slot:SetPosition( -40,0 )
    slot:SetSize( 165, 20 )
    slot:SetShortcut(Turbine.UI.Lotro.Shortcut( Alias,"/bll ;loc" ))
    slot:SetAllowDrop( false )

	-- Create a Zone menu button
	self.zoneMenu = self:AddField(DropMenu, "", {x=175,y=140}, {x=135,y=20} )
	local action = function(args)
        SetLocStr(Zname[args]);
	end
	self.zoneMenu.Menu.Click = function()
		self.zoneMenu:BuildMenu(Zlist,action)
	end
    if (locStr) then
        self.zoneMenu:SetText(locStr);
    end

	-- Create a sighting listing button
	self.birdsButton = self:AddField(Button, "Zone Birds", {x=30,y=170}, {x=125,y=20} )
	self.birdsButton.Click = function( sender,args )
        BL_Command:Execute("bll","zone")
	end

	-- Create a zones button
	self.zonesButton = self:AddField(Button, "List Zones", {x=175,y=170}, {x=135,y=20} )
	self.zonesButton.Click = function( sender,args )
        BL_Command:Execute("bl","zones")
	end

	-- Create a sighting listing button
	self.birdsButton = self:AddField(Button, "Birds Seen", {x=30,y=200}, {x=125,y=20} )
	self.birdsButton.Click = function( sender,args )
        BL_Command:Execute("bll","list")
	end

	-- Create a totals button
	self.totalsButton = self:AddField(Button, "Personal Totals", {x=175,y=200}, {x=135,y=20} )
	self.totalsButton.Click = function( sender,args )
        BL_Command:Execute("bl","sight")
	end

    -- Show how long for the birding action:
    local timerControl = TimerControl();
    self.TimerControl = timerControl;
    timerControl:SetParent(self);
    timerControl:SetPosition(10, 230);
    --timerControl:SetBackColor(Turbine.UI.Color.DarkGreen);
    timerControl:SetSize(320, 40);
    timerControl:SetVisible(false);

    ---comment
    ---@param sender Window
    ---@param args table 
    self.PositionChanged = function(sender, args)
        local x, y = sender:GetPosition();
        CharacterSettings["BL_Window"]["X"] = x;
        CharacterSettings["BL_Window"]["Y"] = y;
    end
end

function BirdingLogWindow:SetItem(id,item,xname)
    if not item then item = Mats[id] end
    if not xname then xname = string.format(xlink,id,item.N) end
	self.id = id
	self.item = item
	self.name:SetText( item.N )
	self.tier:SetText(item.T.." ("..Tier[item.T]..")")
	local desc = item.P and Proc[item.P] or "Guild rep item"
	self.type:SetText( desc )
end

BirdingLogWindowInstance = BirdingLogWindow()

-- Set Escape action
BirdingLogWindowInstance:SetWantsKeyEvents( true )
BirdingLogWindowInstance.KeyDown = function(sender, args)
	if( args.Action == Turbine.UI.Lotro.Action.Escape ) then
        BirdingLogWindowInstance:ShowHide( false );
	-- elseif Track and args.Control then 
	-- 	BirdingLogWindowInstance.fish:MouseDown(sender, args)
	end
end

function BirdingLogWindow:ShowHide(isVisible)
    self:SetVisible(isVisible);
    CharacterSettings["BL_Window"]["VISIBLE"] = isVisible;
end

function BirdingLogWindow:BirdFound()
    self.TimerControl:BirdFound();
end

function BirdingLogWindow:SetActionKey(action)
    self.TimerControl:SetActionKey(action);
end
