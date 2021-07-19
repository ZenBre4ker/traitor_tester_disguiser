if SERVER then
	AddCSLuaFile()
end

ITEM.EquipMenuData = {
	type = "item_active",
	name = "Traitor Check Disabler",
	desc = "Hides your Team from Testers and lets you become innocent, but also doesnt let you enter Traitor-only rooms, if activated."
}
ITEM.material = "vgui/ttt/icon_disguise"
ITEM.CanBuy = {ROLE_TRAITOR}

local materialList = {}
local teamIntIdentifier = {}

local function SetPlayerTeamStatus(ply, plyTeam)
		STATUS:AddStatus(ply, "item_traitor_check_status", teamIntIdentifier[plyTeam])
		net.Start("item_ttt2_traitor_test_toggle")
		net.WriteString(plyTeam)
		net.Send(ply)
end

local function Toggle_Traitor_Check_Disguiser(ply)
	if CLIENT then
		net.Start("item_ttt2_traitor_test_toggle")
		net.SendToServer()

	else
		local newState = not ply:GetNWBool("traitor_check_disguise", false)
		local plyTeam = newState and TEAM_INNOCENT or ply:GetTeam()

		ply:SetNWBool("traitor_check_disguise", newState)
		SetPlayerTeamStatus(ply, plyTeam)

		LANG.Msg(ply, newState and "disg_turned_on" or "disg_turned_off", nil, MSG_MSTACK_ROLE)
	end
end

hook.Add("Initialize", "TTTItemTraitorTestDisguiserInitStatus", function()
	materialList.hud = {}
	materialList.type = nil
	materialList.hud_color = TEAMS[TEAM_INNOCENT].color
	materialList.DrawInfo = nil

	local counter = 1
	for team,gui in SortedPairs(TEAMS) do
		teamIntIdentifier[team] = counter
		materialList.hud[counter] = gui.iconMaterial
		counter = counter + 1
	end

	if SERVER then return end

	STATUS:RegisterStatus("item_traitor_check_status", materialList)

	bind.Register("ttt2_traitor_check_toggle", function()
		Toggle_Traitor_Check_Disguiser(LocalPlayer())
	end, nil, nil, "Toggle Traitor Check Disabler", KEY_N)
end)



if CLIENT then

	net.Receive("item_ttt2_traitor_test_toggle",function(len,ply)
		if IsValid(ply) or len < 1 then return end
		local plyTeam = net.ReadString()
		local disguisedText = plyTeam == TEAM_INNOCENT and "Inno" or nil
		STATUS.active["item_traitor_check_status"].hud_color = TEAMS[plyTeam].color
		STATUS.active["item_traitor_check_status"].DrawInfo = function() return disguisedText end
	end)

else
	util.AddNetworkString("item_ttt2_traitor_test_toggle")

	function ITEM:Equip(ply)
		local state = ply:GetNWBool("traitor_check_disguise", false)
		local plyTeam = state and TEAM_INNOCENT or ply:GetTeam()

		SetPlayerTeamStatus(ply, plyTeam)
	end

	hook.Add("TTT2ModifyLogicRoleCheck", "item_ttt2_traitor_test_modifier", function(ply, ent, activator, caller, data) 
		if not IsValid(ply) or not ply:IsActive() or not ply:HasEquipmentItem("item_ttt2_traitor_test_disguiser") then return end
		local disguised = ply:GetNWBool("traitor_check_disguise", false)
		LANG.Msg(ply, disguised and "You were successfully disguised as Innocent" or "You weren't disguised, but checked with your actual Role.", nil, MSG_MSTACK_ROLE)
		if not disguised then return end
		return ROLE_INNOCENT,TEAM_INNOCENT
	end)

	hook.Add("TTT2UpdateTeam", "item_ttt2_traitor_test_update_team", function(ply, oldTeam, newTeam)
		if not IsValid(ply) or not ply:IsActive() or not ply:HasEquipmentItem("item_ttt2_traitor_test_disguiser") then return end

		local state = ply:GetNWBool("traitor_check_disguise", false)
		local plyTeam = state and TEAM_INNOCENT or ply:GetTeam()

		SetPlayerTeamStatus(ply, plyTeam)
	end)

	net.Receive("item_ttt2_traitor_test_toggle",function(len,ply)
		if not IsValid(ply) or not ply:IsActive() or not ply:HasEquipmentItem("item_ttt2_traitor_test_disguiser") then return end
		Toggle_Traitor_Check_Disguiser(ply)
	end)
end
