-- Plugin manager Options tab.

function Options_Box(OP,Ypos,text)
	local Box = Turbine.UI.Lotro.CheckBox()
	Box:SetText( text )
	Box:SetSize( 220, 22 )
	Box:SetPosition( 10, Ypos )
	Box:SetParent( OP )
	return Box
end

function Options_Init(print,Settings,Window,Fname,Window2)
	local OP = Turbine.UI.Control()
	OP:SetBackColor( Turbine.UI.Color(0.0, 0.0, 0.1) )
	OP:SetSize( 240, 260 )
	plugin.GetOptionsPanel = function( self ) return OP end
	if not Window then return OP end
	if not Settings then Settings = {} end

	local autoBox = Options_Box(OP,10," Auto-open window")
	if Settings.pos1 or Settings.auto then
		if Settings.auto then 
			Window:SetVisible( true )
			autoBox:SetChecked( true )
		end
		if type(Settings.auto)=="table" and not Settings.pos1 then
			Settings.pos1 = Settings.auto -- patch for old version
		end
	end
	autoBox.CheckedChanged = function( sender, args )
		if not Settings then Settings = {} end
		Settings.auto = sender:IsChecked()
		if Settings.auto then
			local x,y = Window:GetPosition()
			Settings.auto = { x=x, y=y }
			Settings.pos1 = { x=x, y=y }
			if Window2 then
				x,y = Window2:GetPosition()
				Settings.pos2 = { x=x, y=y }
			end
			print("Saved window position.")
		end
		print((Settings.auto and "En" or "Dis").."abled Auto-open.")
		if Fname then
			Turbine.PluginData.Save(Turbine.DataScope.Server,Fname,Settings)
			print("Settings saved.")
		end
	end
	return OP
end
