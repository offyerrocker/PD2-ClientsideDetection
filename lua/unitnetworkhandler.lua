function UnitNetworkHandler:sync_set_camera_detection_enabled(unit,state,str_settings,rpc)
	if not self._verify_sender(rpc) or not alive(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	
	local base = unit:base()
	if not base then
		error("UnitNetworkHandler:sync_set_camera_detection_enabled() No unit base extension")
		return
	end
	
	local settings = nil
	if str_settings ~= "null" then
		settings = json.decode(str_settings)
	end
	
	base:set_detection_enabled(state,settings)
end