
Hooks:Add("NetworkReceivedData", "cds_NetworkReceivedData", function(sender, message, body)
	if message == "cds_sync_camera_event" then
		local data = string.split(body)
		
		local detection_delay_min = data[8] and tonumber(data[8])
		local detection_delay_max = data[9] and tonumber(data[9])
		local id = tonumber(data[1]) -- network id
		
		local message_id = tonumber(data[2])
		local state
		local settings = {
			yaw = tonumber(data[2]),
			pitch = tonumber(data[3]),
			fov = tonumber(data[4]),
			detection_range = tonumber(data[5]),
			suspicion_range = tonumber(data[6]),
			detection_delay = (detection_delay_min or detection_delay_max) and {
				detection_delay_min,
				detection_delay_max
			} or nil
		}
		
		if message_id == SecurityCamera._NET_EVENTS.camera_enabled_state_on then
			state = true
		elseif message_id == SecurityCamera._NET_EVENTS.camera_enabled_state_off then
			state = false
		end
		
		
		for _,unit in pairs(SecurityCamera.cameras) do 
			if unit:id() == id then
				unit:base():set_detection_enabled(state,settings,nil)
				break
			end
		end
		
	end
end)
