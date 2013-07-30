AdminPanel = IconPanel("Toxic Admin Panel", Vector2(600, 450))
AdminPanel.pathName = "Admin Panel"
AdminPath = PanelPath(AdminPanel)

local right = AccessRight('resource.'..g_ResName..'.admin')

addCommandHandler('txadmin', function()
	if(right:check()) then
		AdminPath:toggle()
	else
		outputMsg(Styles.red, "Access denied!")
	end
end, false, false)
