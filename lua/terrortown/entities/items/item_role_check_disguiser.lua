if not TTT2 then
	print("\nERROR: Missing core Role Check Hooks.\nThe Role Check Disguiser is only available for TTT2!\nRemoving Role Check Disguiser from shop!\n")
	return
end

if SERVER then
	AddCSLuaFile()
end

ITEM.EquipMenuData = {
	type = "item_active",
	name = "Role-Check Disguiser",
	desc = "Hides yourself from Testers and let's you become innocent, but also doesnt let you enter Traitor-only rooms, if activated."
}
ITEM.material = "vgui/ttt/icon_role_check_disguiser.png"
ITEM.CanBuy = {ROLE_TRAITOR}

local materialList = {}
local teamIntIdentifier = {}

local timeStamp = 0
local timeWait = 2

local function SetPlayerTeamStatus(ply, plyTeam)
		STATUS:AddStatus(ply, "item_role_check_disguiser_status", teamIntIdentifier[plyTeam])

		net.Start("ttt2_role_check_disguise_toggle")
		net.WriteString(plyTeam)
		net.Send(ply)
end

local function Toggle_Role_Check_Disguiser(ply)
	if CLIENT then
		net.Start("ttt2_role_check_disguise_toggle")
		net.SendToServer()
	else
		local newState = not ply:GetNWBool("role_check_disguise", false)
		local plyTeam = newState and TEAM_INNOCENT or ply:GetTeam()

		ply:SetNWBool("role_check_disguise", newState)
		SetPlayerTeamStatus(ply, plyTeam)

		LANG.Msg(ply, newState and "disg_turned_on" or "disg_turned_off", nil, MSG_MSTACK_ROLE)
	end
end

hook.Add("Initialize", "TTT2RoleCheckDisguiserInitStatus", function()
	materialList.hud = {}
	materialList.type = nil
	materialList.hud_color = TEAMS[TEAM_INNOCENT].color
	materialList.DrawInfo = nil

	local counter = 0

	for team,gui in SortedPairs(TEAMS) do
		counter = counter + 1
		teamIntIdentifier[team] = counter
		materialList.hud[counter] = gui.iconMaterial
	end

	if SERVER then return end

	STATUS:RegisterStatus("item_role_check_disguiser_status", materialList)

	bind.Register("ttt2_role_check_disguiser_toggle", function()
		Toggle_Role_Check_Disguiser(LocalPlayer())
		end, nil, nil, "Toggle Role-Check Disguiser", KEY_N)
end)

if CLIENT then
	net.Receive("ttt2_role_check_disguise_toggle", function(len)
		if len < 1 then return end

		local plyTeam = net.ReadString()
		local disguisedText = plyTeam == TEAM_INNOCENT and "Inno" or nil

		STATUS.active["item_role_check_disguiser_status"].hud_color = TEAMS[plyTeam].color
		STATUS.active["item_role_check_disguiser_status"].DrawInfo = function() return disguisedText end
	end)

	function ITEM:Bought()
		chat.AddText("Role-Check Disguiser: ", COLOR_WHITE, "Toggle Disguise with the key: ", COLOR_RED, tostring(input.GetKeyName(bind.Find("ttt2_role_check_toggle"))))
	end

else
	util.AddNetworkString("ttt2_role_check_disguise_toggle")

	function ITEM:Equip(ply)
		local state = ply:GetNWBool("role_check_disguise", false)
		local plyTeam = state and TEAM_INNOCENT or ply:GetTeam()

		SetPlayerTeamStatus(ply, plyTeam)
	end

	hook.Add("TTT2ModifyLogicRoleCheck", "ttt2_item_role_check_modifier", function(ply, ent, activator, caller, data)
		if not IsValid(ply) or not ply:IsActive() or not ply:HasEquipmentItem("item_role_check_disguiser") then return end

		local disguised = ply:GetNWBool("role_check_disguise", false)

		if CurTime() > timeStamp then
			LANG.Msg(ply, disguised and "You were disguised as Innocent" or "You weren't disguised, but checked with your actual Role.", nil, MSG_MSTACK_ROLE)
		end

		timeStamp = CurTime() + timeWait

		if not disguised then return end

		return ROLE_INNOCENT, TEAM_INNOCENT
	end)

	hook.Add("TTT2UpdateTeam", "ttt2_item_role_check_disguiser_update_team", function(ply, oldTeam, newTeam)
		if not IsValid(ply) or not ply:IsActive() or not ply:HasEquipmentItem("item_role_check_disguiser") then return end

		local state = ply:GetNWBool("role_check_disguise", false)
		local plyTeam = state and TEAM_INNOCENT or ply:GetTeam()

		SetPlayerTeamStatus(ply, plyTeam)
	end)

	net.Receive("ttt2_role_check_disguise_toggle",function(len,ply)
		if not IsValid(ply) or not ply:IsActive() or not ply:HasEquipmentItem("item_role_check_disguiser") then return end

		Toggle_Role_Check_Disguiser(ply)
	end)
end
