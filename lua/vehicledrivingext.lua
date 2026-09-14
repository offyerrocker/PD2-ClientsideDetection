
-- custom func;
-- determine which player in the lobby should be responsible for detection of this vehicle:
-- if player driver present, use driver
-- else, find the player who got in any non-driver seat first, and use that player
function VehicleDrivingExt:chk_attention_responsibility()
	local is_local_player_responsible
	
--	if not managers.groupai:state():whisper_mode() then
		-- if in loud, allow enemy ai to "target" other players
--		is_local_player_responsible = true
--	else
		local responsible_peerid = self:get_attention_responsibility()
		if responsible_peerid and responsible_peerid == managers.network:session():local_peer():id() then
			is_local_player_responsible = true
		end
--	end
	
	if is_local_player_responsible then
		local attention_setting_name = "vehicle_enemy_cbt"
		local attention_desc = tweak_data.attention.settings[attention_setting_name]
		local attention_setting = PlayerMovement._create_attention_setting_from_descriptor(self, attention_desc, attention_setting_name)

		self._unit:attention():set_attention(attention_setting, nil)
		local player = managers.player:local_player()
		local team = alive(player) and player:movement():team()
		if team then
			self._unit:attention():set_team(team)
		end
	else
		self._unit:attention():set_attention(nil, nil)
	end
end


function VehicleDrivingExt:get_attention_responsibility()
	local best_peerid = 1
	local best_t = math.huge
	for _,seat in pairs(self._seats) do
		if seat._cd_start_t and seat._cd_start_t < best_t then
			local peer_id = alive(seat.occupant) and managers.criminals:character_peer_id_by_unit(seat.occupant)
			if peer_id then
				best_peerid = peer_id or best_peerid
			end
		end
	end
	return best_peerid
end

Hooks:PostHook(VehicleDrivingExt,"_evacuate_seat","clientsidedetection_onplayerleftvehicle",function(self, seat)
	seat._cd_start_t = nil
	self:chk_attention_responsibility()
end)

Hooks:PostHook(VehicleDrivingExt,"reserve_seat","clientsidedetection_onplayerenteredvehicle",function(self, player, position, seat_name)
	local seat = Hooks:GetReturn()
	if seat then
		if not (alive(seat.occupant) and seat.occupant:brain()) then
			seat._cd_start_t = TimerManager:main():time()
		end
	end
	
	self:chk_attention_responsibility()
end)


Hooks:OverrideFunction(VehicleDrivingExt,"place_player_on_seat",function(self, player, seat_name)
	local number_of_seats = 0

	for _, seat in pairs(self._seats) do
		number_of_seats = number_of_seats + 1

		if seat.name == seat_name then
			seat.occupant = player

			self._door_soundsource:set_position(seat.object:position())
			self._door_soundsource:post_event(self._tweak_data.sound.door_close)

			local count = self:_number_in_the_vehicle()

			if count == 1 then
				self:_chk_register_drive_SO()
			end

			if alive(self._seats.driver.occupant) and (self._current_state_name == VehicleDrivingExt.STATE_INACTIVE or self._current_state_name == VehicleDrivingExt.STATE_PARKED) then
				self:set_state(VehicleDrivingExt.STATE_DRIVING)
			end

			if count == 1 and self._current_state_name ~= VehicleDrivingExt.STATE_BROKEN and self._current_state_name ~= VehicleDrivingExt.STATE_BLOCKED then
				self:start(player)
			end
		end
	end

	if number_of_seats == self:_number_in_the_vehicle() then
		self._interaction_enter_vehicle = false
	end
	
	
	self:chk_attention_responsibility()
	--[[
	if self:num_players_inside() == 1 then
		local attention_setting_name = "vehicle_enemy_cbt"
		local attention_desc = tweak_data.attention.settings[attention_setting_name]
		local attention_setting = PlayerMovement._create_attention_setting_from_descriptor(self, attention_desc, attention_setting_name)

		self._unit:attention():set_attention(attention_setting, nil)
		self._unit:attention():set_team(player:movement():team())
	end
	--]]
end)