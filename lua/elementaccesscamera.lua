do return end

function ElementAccessCamera:on_script_activated()
	if self._values.camera_u_id then
		local id = self._values.camera_u_id
		local unit

		if Global.running_simulation then
			unit = managers.editor:unit_with_id(id)
		else
			unit = managers.worlddefinition:get_unit_on_load(id, callback(self, self, "_load_unit"))
		end

		if unit then
			
			log("script activated",debug.traceback())
			
			--unit:base():set_access_camera_mission_element(self)

			self._camera_unit = unit
		end
	end

	self._has_fetched_units = true

	self._mission_script:add_save_state_cb(self._id)

	local channel_id = self._values.channel_id or "default"

	managers.game_play_central:add_access_camera(channel_id, self)
end

function ElementAccessCamera:_load_unit(unit)
	log("load unit",debug.traceback())
	
	--unit:base():set_access_camera_mission_element(self)

	self._camera_unit = unit
end