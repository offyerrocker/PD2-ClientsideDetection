ClientsideDetection = {
	_modpath = ModPath,
	_libs = {},
	SECURITYCAMERA_NETEVENTS = {
--		camera_enabled_state_off = 15,
--		camera_enabled_state_on = 14,
		
		set_detection_enabled_state = 14,
		request_alarm_start = 15,
		
		-- below is vanilla
		deactivate_tape_loop = 13,
		request_start_tape_loop_2 = 12,
		request_start_tape_loop_1 = 11,
		start_tape_loop_2 = 10,
		start_tape_loop_1 = 9,
		suspicion_6 = 8,
		suspicion_5 = 7,
		suspicion_4 = 6,
		suspicion_3 = 5,
		suspicion_2 = 4,
		suspicion_1 = 3,
		alarm_start = 2,
		sound_off = 1
	}
}


function ClientsideDetection:require(_path)
	local path = self._modpath .. "lua/" .. _path .. ".lua"
	if self._libs[path] then
		return self._libs[path]
	elseif io.file_is_readable(path) then
		local result = blt.vm.dofile(path)
		self._libs[_path] = result
		return result
	else
		error("File could not be read: " .. tostring(path))
	end
end


function ClientsideDetection.camera_sync_net_event(self,event_id)
	local net_events = self._NET_EVENTS

	-- modded changes begin
	if event_id == net_events.set_detection_enabled_state then
		self:set_detection_enabled(true)
	elseif event_id == net_events.request_alarm_start then
		self:_send_net_event(net_events.alarm_start)
	-- modded changes end
	elseif net_events.suspicion_1 <= event_id and event_id <= net_events.suspicion_6 then
		local suspicion_lvl = (event_id - net_events.suspicion_1 + 1) / 6

		self:_set_suspicion_sound(suspicion_lvl)
	elseif event_id == net_events.sound_off then
		self:_stop_all_sounds()
	elseif event_id == net_events.alarm_start then
		self:_sound_the_alarm()
	elseif event_id == net_events.start_tape_loop_1 then
		self:_start_tape_loop_by_upgrade_level(1)
	elseif event_id == net_events.start_tape_loop_2 then
		self:_start_tape_loop_by_upgrade_level(2)
	elseif event_id == net_events.request_start_tape_loop_1 then
		self:_request_start_tape_loop_by_upgrade_level(1)
	elseif event_id == net_events.request_start_tape_loop_2 then
		self:_request_start_tape_loop_by_upgrade_level(2)
	elseif event_id == net_events.deactivate_tape_loop then
		self:_deactivate_tape_loop()
	end
end
