--[[
Hooks:OverrideFunction(PlayerManager,"server_drop_carry",function(self, carry_id, carry_multiplier, dye_initiated, has_dye_pack, dye_value_multiplier, position, rotation, dir, throw_distance_multiplier_upgrade_level, zipline_unit, peer)
	if not self:verify_carry(peer, carry_id) then
		return
	end

	local unit_name = tweak_data.carry[carry_id].unit or "units/payday2/pickups/gen_pku_lootbag/gen_pku_lootbag"
	local unit = World:spawn_unit(Idstring(unit_name), position, rotation)
	
--	local attention = unit:attention() 
--	if attention then
--	end
	
	managers.network:session():send_to_peers_synched("sync_carry_data", unit, carry_id, carry_multiplier, dye_initiated, has_dye_pack, dye_value_multiplier, position, dir, throw_distance_multiplier_upgrade_level, zipline_unit, peer and peer:id() or 0)
	self:sync_carry_data(unit, carry_id, carry_multiplier, dye_initiated, has_dye_pack, dye_value_multiplier, position, dir, throw_distance_multiplier_upgrade_level, zipline_unit, peer and peer:id() or 0)

	if unit:carry_data()._global_event then
		managers.mission:call_global_event(unit:carry_data()._global_event)
	end

	return unit
end)


Hooks:OverrideFunction(PLayerManager,"sync_carry_data",function(self, unit, carry_id, carry_multiplier, dye_initiated, has_dye_pack, dye_value_multiplier, position, dir, throw_distance_multiplier_upgrade_level, zipline_unit, peer_id)
	
end)
--]]
