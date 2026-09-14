ClientsideDetection = {
	_modpath = ModPath,
	_libs = {}
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



do return end
require("lib/units/props/securitycamera")
Hooks:Add("NetworkReceivedData", "cds_NetworkReceivedData", function(sender, message, body)
	if message == "cds_sync_camera_event" then
		Print("Received camera sync!",body)
		local data = string.split(body,"|")
		
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
		
		if SecurityCamera._NET_EVENTS then
			if message_id == SecurityCamera._NET_EVENTS.camera_enabled_state_on then
				state = true
			elseif message_id == SecurityCamera._NET_EVENTS.camera_enabled_state_off then
				state = false
			end
		else
			Print("NO NET EVENTS???",SecurityCamera)
			state = true
		end
		
		
		for _,unit in pairs(SecurityCamera.cameras) do 
			if unit:id() == id then
				unit:base():set_detection_enabled(state,settings,nil)
				Print("Found camera unit")
				break
			end
		end
		
	end
end)
