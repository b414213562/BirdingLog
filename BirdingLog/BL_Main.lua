-- Birding Log by David Down
-- coding: utf-8 '�

import "Turbine.Gameplay"
import "Turbine.UI.Lotro"
import "Vinny.Common.EII_ID"
import "Vinny.Common.Sort"
import "Vinny.BirdingLog.BL_Data"

-- Save player name for later use
player = Turbine.Gameplay.LocalPlayer.GetInstance()
pname = player:GetName()

function print(text) Turbine.Shell.WriteLine("<rgb=#00FFFF>BL:</rgb> "..tostring(text)) end
function printh(text) print("<rgb=#00FF00>"..text.."</rgb>") end
function printe(text) print("<rgb=#FF6040>Error: "..text.."</rgb>") end

import "Vinny.Common.Help"

local locPat = "You are on %a* server %d* at r(%d) lx(%d+) ly(%d+) ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
local liPat = "You are on %a* server %d* at r(%d) lx(%d+) ly(%d+) i%d* ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
local iPat = "You are on %a* server %d* at r(%d) lx(%d+) ly(%d+) cInside ox(.-%d+%.?%d*) oy(.-%d+%.?%d*) oz(.-%d+%.?%d*)"
local xlink = "<Examine:IIDDID:0x0000000000000000:0x700%s>[%s]<\\Examine>"
local xpat = "<Examine:IIDDID:0x0%x+:0x700(%x+)>%[(.-)%]<\\Examine>"
local fpPat = "Your proficiency in Birding has increased to (%d+)."
local nPat = "(%d+) (.+)"
local Zloc = "^(.+): (.+): (%d+%.%d[NS]), (%d+%.%d[EW])$"
local x0,y0 = 1468,1244
locStr = false
Track = false
-- You have acquired: [Minnow].
-- Your proficiency in Birding has increased to 9.

BL_Options = Turbine.PluginData.Load(Turbine.DataScope.Server,"BL_Options")
if not BL_Options then BL_Options = {} end

local FLv = "Birding Log "..Plugins["BirdingLog"]:GetVersion()

Locs = Turbine.PluginData.Load(Turbine.DataScope.Server,"BL_Locs")
if type(Locs) == "table" then
	if next(Locs) and #next(Locs) > 2 then
		print("Converting Locs to Zones..")
		local zt = {}
		for z in pairs(Zone) do zt[z] = {} end
		for l,t in pairs(Locs) do
			z = zt[t.z]
			for id,n in pairs(t) do
				if #id==5 then z[id] = (z[id] or 0)+n end
			end
		end
		Locs = zt
	end
else Locs = {} end

Totals = Turbine.PluginData.Load(Turbine.DataScope.Character,"BL_Totals")
if type(Totals) ~= "table" then 
	Totals = {} 
	print("Created new birding record")
end

--- Initialize a setting with a default value, if it's not already there.
---@param settings table
---@param key string
---@param defaultValue any
function InitSetting(settings, key, defaultValue)
    if (settings[key] == nil) then
        settings[key] = defaultValue;
    end
end

CharacterSettings = Turbine.PluginData.Load(Turbine.DataScope.Character,"BL_CharacterSettings");
if (type(CharacterSettings)) ~= "table" then
    CharacterSettings = {}

    -- Initialize default settings 
    InitSetting(CharacterSettings, "BL_Window", {});
    InitSetting(CharacterSettings["BL_Window"], "VISIBLE", false);
    InitSetting(CharacterSettings["BL_Window"], "X", (Turbine.UI.Display.GetWidth() - 340)/3);
    InitSetting(CharacterSettings["BL_Window"], "Y", (Turbine.UI.Display:GetHeight() - 300)*.7);

end

import "Vinny.BirdingLog.BL_Window"

printh(FLv..", data loaded.")

function pos(n0,ls,os)
	return (tostring(ls) +math.fmod(tostring(os),20)/20 -n0)/10
end

Turbine.Chat.Received = function (sender,args)
	local msg = args.Message
	if not msg then return end
	local fp = msg:match(fpPat)
	if fp then Totals.fp = fp return end
--	print("Chat type="..args.ChatType)
	if args.ChatType==Turbine.ChatType.SelfLoot then 
		if msg:find("You have acquired: ") then
			local id,name = msg:match(xpat)
			if not id then id,name = Vinny.Common.EII_ID(msg) end
			if not id then return end
			if name:sub(-5)=="Frame" then return end
			if ID[id] then
				if not Totals[id] then
					Totals[id] = 0
					print("New type of bird found.")
				end
				Totals[id] = Totals[id]+1
				print("Saw a "..ID[id].n..", count="..Totals[id])
				if locStr then
					local locTbl = Locs[locStr]
					if not locTbl then return end
					if not locTbl[id] then locTbl[id] = 0 end
					locTbl[id] = locTbl[id]+1
				end
			elseif Track then 
				printe("Unknown: "..name..", id="..tostring(id)) 
			end
		end
		return
	end
	if args.ChatType~=Turbine.ChatType.Standard then return end
	local tt = msg:match("^Taking the contents of the (.+)....$")
	if tt then last = last==tt return end
	local r,lx,ly,ox,oy,oz = msg:match(locPat)
	if not r then r,lx,ly,ox,oy,oz = msg:match(liPat) end
	if not r then r,lx,ly,ox,oy,oz = msg:match(iPat) end
	if not r then return end
	local ew,ns = pos(x0,lx,ox), pos(y0,ly,oy)
	locStr = string.format("%.1f,%.1f",ns,ew)
	print("r="..r..", ns="..ns..", ew="..ew.."  ("..locStr..")")
end

local function distance(dy,dx) return math.sqrt(dy*dy+dx*dx) end

local function locV(str,neg)
    local nbr = tonumber(str:sub(1,-2))
    if str:sub(-1)==neg then nbr = -nbr end
    return nbr
end

local function print_list(list)
	local nr,t = 0,{}
	for id,n in pairs(list) do
		if #id==5 then
			table.insert(t,id)
		end
	end
	table.sort(t, function(a,b) return ID[a].n<ID[b].n end )
	for i,id in ipairs(t) do
		local t,n = ID[id],list[id]
		local s = string.format(xlink,id,t.n)
		print(s..': '..n)
		nr = nr + n
	end
	print("Total sighting count: "..nr)
	return
end

BL_Command = Turbine.ShellCommand()
function BL_Command:GetShortHelp() return Vinny.Common.Help(help,"??") end
function BL_Command:GetHelp() return Vinny.Common.Help(help,"help") end

function BL_Command:Execute( cmd,args )
	if Vinny.Common.HelpCmd(cmd,args,help) then return end
    if cmd=="bll" then
		if args=="list" then
			if locStr then
				printh("Birds sighted in "..Zone[locStr].z)
				print_list(Locs[locStr])
			else printe("No zone selected yet") end
			return
		end
		if args=="zone" then
			if locStr then
				local z = Zone[locStr]
				printh("Birds to see in "..z.z)
				for id in Sort(z.id,function(a,b) return ID[a].n<ID[b].n end) do
					local t,n = ID[id], Totals[id] or 0
					local s = string.format(xlink,id,t.n)
					print(s..': '..n)
				end
			else printe("No zone selected yet") end
			return
		end
		local reg,a,y,x = args:match(Zloc)
		if y then
			local r = Region[reg]
			if not r then printe("Unknown region: "..reg) return end
			if r~=1 then printe("Birding requires Eriador.") return end
			local y1,x1,ln = locV(y,'S'), locV(x,'W')
			local loc = r..';'..y1..','..x1
			locStr = nil
			local zc,zn
			for c,t in pairs(Zone) do
				if y1<t.n and y1>t.s and x1<t.e and x1>t.w then
					zc = c; zn = t.z break end
			end
			if zn then 
				print("Zone: "..zn)
				locStr = zc
				if not Locs[zc] then Locs[zc] = {} end
				BirdingLogWindowInstance.zoneMenu:SetText( Zone[zc].z )
			else printe("Zone not found.") end
		else printe("Invalid location for Birding.") end
		return
	end
	if args=="show" or cmd=="blw" then
		BirdingLogWindowInstance:ShowHide( true )
		return
	end
    if args=="sight" then
		printh("Birding sighting record:")
		print_list(Totals)
		return
	end
	if args=="zones" then
		printh("Birds found by zone:")
		for zc,zt in Sort(Zone) do
			local zn,pn = 0,0
			for id in pairs(zt.id) do
				zn = zn+1
				if Totals[id] then pn = pn+1 end
			end
			print(zt.z..': '..pn..'/'..zn)
		end
		return
	end
    if args=="" then
		local fp = Totals.fp
		if fp then 
			local s,fp,pv = '', tonumber(fp), 0
			if fp>9 then
				for p,n in pairs(Title) do
					if fp>=p and p>pv then pv = p end
				end
				if pv>0 then s = ', '..Title[pv] end
			end
			print("Birding proficiency is "..fp..s)
		else print("Unknown Birding proficiency.") end
		return
	end
	local n,bird = args:match(nPat)
	if n and bird then
		n = tonumber(n)
		for id,t  in pairs(ID) do
			if t.n==bird then
				local s = Zone[t.f[1]].z
				if t.f[2] then s = s.." and "..Zone[t.f[2]].z end
				print("The "..bird.." is found in "..s)
				Totals[id] = n
				print("Total sightings set to "..n)
				return
			end
		end
		print("Bird '"..bird.."' not found")
		return
	end
    printe("Unknown command, "..args)
end

Turbine.Shell.AddCommand( "bl;bll;blw;bl?", BL_Command )

Plugins.BirdingLog.Unload = function(sender,args)
    Turbine.PluginData.Save(Turbine.DataScope.Server,"BL_Locs",Locs)
    Turbine.PluginData.Save(Turbine.DataScope.Character,"BL_Totals",Totals)
    Turbine.PluginData.Save(Turbine.DataScope.Character,"BL_CharacterSettings",CharacterSettings);
    print("Birding record saved.")
end

--~ if Event[-1] then FR_Command:Execute("fr","") end

-- Options panel
import "Vinny.Common.Options"
OP = Vinny.Common.Options_Init(print,BL_Options,BirdingLogWindowInstance,"BL_Options")

-- Help text
help = {
	pre = "bl",
	arg = {
		[""] = "Display personal birding details.",
		[" "] = "Display birding proficiency.",
		["# <name>"] = "Set count for <name> to #.",
		sight = "List birding sighting records.",
		zones = "List birding zones and counts.",
	},
	cmd = {
		bll = {
			[" "] = "Birding location commands.",
			[";loc"] = "Set the current birding zone.",
			list = "List sightings in the current zone.",
			zone = "List all birds and sightings in the zone.",
		},
		blw = "Open Birding Log window.",
	},
}