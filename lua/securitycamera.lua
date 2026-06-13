-- currently:
-- on the host side, cameras detect host but not clients
-- on the client side, cameras do not detect anything

SecurityCamera._NET_EVENTS = {
	camera_enabled_state_off = 15,
	camera_enabled_state_on = 14,
	
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

Hooks:PostHook(SecurityCamera,"set_detection_enabled","clientsidedetection_setcameraupdateenabled",function(self,state,settings,mission_element)
	if Network:is_server() then
		if settings then 
			-- serialize and send detection values
			
			local function sformat(value,precision)
				if not value then 
					return ""
				end
				
				if precision and precision > 0 then
					return string.format("%0." .. math.floor(precision) .. "f",value)
				end
				
				return string.format("%i",value)
			end
			
			local id = unit:id()
			if id ~= -1 then
				local div_char = "|"
				local data_str = (
					sformat(id,0) .. div_char .. 
					sformat(self._NET_EVENTS.camera_enabled_state_on,0) .. div_char .. 
					sformat(settings.yaw,1) .. div_char .. 
					sformat(settings.pitch,1) ..  div_char .. 
					sformat(settings.fov,1) .. div_char .. 
					sformat(settings.detection_range,1) .. div_char .. 
					sformat(settings.suspicion_range,1) .. div_char .. 
					sformat(settings.detection_delay and settings.detection_delay.detection_delay_min,1) .. div_char .. 
					sformat(settings.detection_delay and settings.detection_delay.detection_delay_max,1) .. div_char
				)
				
				LuaNetworking:SendToPeers("cds_sync_camera_event",data_str)
			end
		end
		
		
		
		--[[
		if state then
			self:_send_net_event(self._NET_EVENTS.camera_enabled_state_off)
		else
			self:_send_net_event(self._NET_EVENTS.camera_enabled_state_on)
		end
		--]]
	end
end)

Hooks:OverrideFunction(SecurityCamera,"sync_net_event",function(self,event_id)
	local net_events = self._NET_EVENTS

	-- modded changes begin
	if event_id == net_events.camera_enabled_state_on then
		self:set_detection_enabled(true)
	elseif event_id == net_events.camera_enabled_state_off then
		self:set_detection_enabled(false)
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
end)

	--somethig in this crashes, probably attention
	--[[
function SecurityCamera:_upd_sound(unit, t)
	if self._alarm_sound then
		return
	end

	local suspicion_level = self._suspicion

	for u_key, attention_info in pairs(self._detected_attention_objects) do
		if AIAttentionObject.REACT_SCARED <= attention_info.reaction then
			if attention_info.identified then
				self:_sound_the_alarm(attention_info.unit)

				return
			elseif not suspicion_level or suspicion_level < attention_info.notice_progress then
				suspicion_level = attention_info.notice_progress
			end
		end
	end

	if not suspicion_level then
		self:_set_suspicion_sound(0)
		self:_stop_all_sounds()

		return
	end

	self:_set_suspicion_sound(suspicion_level)
end

--]]
	
Hooks:OverrideFunction(SecurityCamera,"update",function(self,unit,t,dt)
	self:_update_tape_loop_restarting(unit, t, dt)
	
	-- enable clientside detection for security cameras
--	if not Network:is_server() then
--		return
--	end

	if managers.groupai:state():is_ecm_jammer_active("camera") or self._tape_loop_expired_clbk_id or self._tape_loop_restarting_t then
		self:_destroy_all_detected_attention_object_data()
		self:_stop_all_sounds()
	else
		self:_upd_detection(t)
	end

	self:_upd_sound(unit, t)
end)

do return end -- needs testing



-- figure out what verified and identified are- log to tracker
-- check attention object with the same conditions to prevent serverside detection from being active on players
	-- disable clientside detection on the client and host, to isolate whether hostside detection is active

Hooks:OverrideFunction(SecurityCamera,"_upd_detect_attention_objects",function(self,t)
	
	local detected_obj = self._detected_attention_objects
	local my_key = self._u_key
	local my_pos = self._pos
	local my_fwd = self._look_fwd
	local det_delay = self._detection_delay

	for u_key, attention_info in pairs(detected_obj) do
		if t >= attention_info.next_verify_t then
			-- only check detection on an interval;
			-- either needs smooth frame interpolation,
			-- or run every frame (and add suspicion by dt)
			
			
			attention_info.next_verify_t = t + (attention_info.identified and attention_info.verified and attention_info.settings.verification_interval * 1.3 or attention_info.settings.verification_interval * 0.3)

			if not attention_info.identified then
				local noticable = nil
				local angle, dis_multiplier = self:_detection_angle_and_dis_chk(my_pos, my_fwd, attention_info.handler, attention_info.settings, attention_info.handler:get_detection_m_pos())

				if angle then
					local attention_pos = attention_info.handler:get_detection_m_pos()
					local vis_ray = self._unit:raycast("ray", my_pos, attention_pos, "slot_mask", self._visibility_slotmask, "ray_type", "ai_vision")

					if not vis_ray or vis_ray.unit:key() == u_key then
						noticable = true
					end
				end

				local delta_prog = nil
				local dt = t - attention_info.prev_notice_chk_t

				if noticable then
					if angle == -1 then
						delta_prog = 1
					else
						local min_delay = det_delay[1]
						local max_delay = det_delay[2]
						local angle_mul_mod = 0.15 * math.min(angle / self._cone_angle, 1)
						local dis_mul_mod = 0.85 * dis_multiplier
						local notice_delay_mul = attention_info.settings.notice_delay_mul or 1

						if attention_info.settings.detection and attention_info.settings.detection.delay_mul then
							notice_delay_mul = notice_delay_mul * attention_info.settings.detection.delay_mul
						end

						local notice_delay_modified = math.lerp(min_delay * notice_delay_mul, max_delay, dis_mul_mod + angle_mul_mod)
						delta_prog = notice_delay_modified > 0 and dt / notice_delay_modified or 1
					end
				else
					delta_prog = det_delay[2] > 0 and -dt / det_delay[2] or -1
				end

				attention_info.notice_progress = attention_info.notice_progress + delta_prog

				if attention_info.notice_progress > 1 then
					attention_info.notice_progress = nil
					attention_info.prev_notice_chk_t = nil
					attention_info.identified = true
					attention_info.release_t = t + attention_info.settings.release_delay
					attention_info.identified_t = t
					noticable = true

					if AIAttentionObject.REACT_SCARED <= attention_info.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(attention_info.unit, self._unit, true)
					end
				elseif attention_info.notice_progress < 0 then
					self:_destroy_detected_attention_object_data(attention_info)

					noticable = false
				else
					noticable = attention_info.notice_progress
					attention_info.prev_notice_chk_t = t

					if AIAttentionObject.REACT_SCARED <= attention_info.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(attention_info.unit, self._unit, noticable)
					end
				end

				if noticable ~= false and attention_info.settings.notice_clbk then
					attention_info.settings.notice_clbk(self._unit, noticable)
				end
			end

			if attention_info.identified then
				attention_info.nearly_visible = nil
				local verified, vis_ray = nil
				local attention_pos = attention_info.handler:get_detection_m_pos()
				local dis = mvector3.distance(my_pos, attention_info.m_pos)

				if dis < self._range * 1.2 then
					local detect_pos = nil

					if attention_info.is_husk_player and attention_info.unit:anim_data().crouch then
						detect_pos = self._tmp_vec1

						mvector3.set(detect_pos, attention_info.m_pos)
						mvector3.add(detect_pos, tweak_data.player.stances.default.crouched.head.translation)
					else
						detect_pos = attention_pos
					end

					local in_FOV = self:_detection_angle_chk(my_pos, my_fwd, detect_pos, 0.8)

					if in_FOV then
						vis_ray = self._unit:raycast("ray", my_pos, detect_pos, "slot_mask", self._visibility_slotmask, "ray_type", "ai_vision")

						if not vis_ray or vis_ray.unit:key() == u_key then
							verified = true
						end
					end

					attention_info.verified = verified
				end

				attention_info.dis = dis

				if verified then
					attention_info.release_t = nil
					attention_info.verified_t = t

					mvector3.set(attention_info.verified_pos, attention_pos)

					attention_info.last_verified_pos = mvector3.copy(attention_pos)
					attention_info.verified_dis = dis
				elseif attention_info.release_t and attention_info.release_t < t then
					self:_destroy_detected_attention_object_data(attention_info)
				else
					attention_info.release_t = attention_info.release_t or t + attention_info.settings.release_delay
				end
			end
		end
	end
end)











do return end
SecurityCamera._upd_detect_attention_objects = function() end 

function SecurityCamera:_upd_detect_attention_objects(t)
	local detected_obj = self._detected_attention_objects
	local my_key = self._u_key
	local my_pos = self._pos
	local my_fwd = self._look_fwd
	local det_delay = self._detection_delay

	for u_key, attention_info in pairs(detected_obj) do
		if t >= attention_info.next_verify_t then
			attention_info.next_verify_t = t + (attention_info.identified and attention_info.verified and attention_info.settings.verification_interval * 1.3 or attention_info.settings.verification_interval * 0.3)

			if not attention_info.identified then
				local noticable = nil
				local angle, dis_multiplier = self:_detection_angle_and_dis_chk(my_pos, my_fwd, attention_info.handler, attention_info.settings, attention_info.handler:get_detection_m_pos())

				if angle then
					local attention_pos = attention_info.handler:get_detection_m_pos()
					local vis_ray = self._unit:raycast("ray", my_pos, attention_pos, "slot_mask", self._visibility_slotmask, "ray_type", "ai_vision")

					if not vis_ray or vis_ray.unit:key() == u_key then
						noticable = true
					end
				end

				local delta_prog = nil
				local dt = t - attention_info.prev_notice_chk_t

				if noticable then
					if angle == -1 then
						delta_prog = 1
					else
						local min_delay = det_delay[1]
						local max_delay = det_delay[2]
						local angle_mul_mod = 0.15 * math.min(angle / self._cone_angle, 1)
						local dis_mul_mod = 0.85 * dis_multiplier
						local notice_delay_mul = attention_info.settings.notice_delay_mul or 1

						if attention_info.settings.detection and attention_info.settings.detection.delay_mul then
							notice_delay_mul = notice_delay_mul * attention_info.settings.detection.delay_mul
						end

						local notice_delay_modified = math.lerp(min_delay * notice_delay_mul, max_delay, dis_mul_mod + angle_mul_mod)
						delta_prog = notice_delay_modified > 0 and dt / notice_delay_modified or 1
					end
				else
					delta_prog = det_delay[2] > 0 and -dt / det_delay[2] or -1
				end

				attention_info.notice_progress = attention_info.notice_progress + delta_prog

				if attention_info.notice_progress > 1 then
					attention_info.notice_progress = nil
					attention_info.prev_notice_chk_t = nil
					attention_info.identified = true
					attention_info.release_t = t + attention_info.settings.release_delay
					attention_info.identified_t = t
					noticable = true

					if AIAttentionObject.REACT_SCARED <= attention_info.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(attention_info.unit, self._unit, true)
					end
				elseif attention_info.notice_progress < 0 then
					self:_destroy_detected_attention_object_data(attention_info)

					noticable = false
				else
					noticable = attention_info.notice_progress
					attention_info.prev_notice_chk_t = t

					if AIAttentionObject.REACT_SCARED <= attention_info.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(attention_info.unit, self._unit, noticable)
					end
				end

				if noticable ~= false and attention_info.settings.notice_clbk then
					attention_info.settings.notice_clbk(self._unit, noticable)
				end
			end

			if attention_info.identified then
				attention_info.nearly_visible = nil
				local verified, vis_ray = nil
				local attention_pos = attention_info.handler:get_detection_m_pos()
				local dis = mvector3.distance(my_pos, attention_info.m_pos)

				if dis < self._range * 1.2 then
					local detect_pos = nil

					if attention_info.is_husk_player and attention_info.unit:anim_data().crouch then
						detect_pos = self._tmp_vec1

						mvector3.set(detect_pos, attention_info.m_pos)
						mvector3.add(detect_pos, tweak_data.player.stances.default.crouched.head.translation)
					else
						detect_pos = attention_pos
					end

					local in_FOV = self:_detection_angle_chk(my_pos, my_fwd, detect_pos, 0.8)

					if in_FOV then
						vis_ray = self._unit:raycast("ray", my_pos, detect_pos, "slot_mask", self._visibility_slotmask, "ray_type", "ai_vision")

						if not vis_ray or vis_ray.unit:key() == u_key then
							verified = true
						end
					end

					attention_info.verified = verified
				end

				attention_info.dis = dis

				if verified then
					attention_info.release_t = nil
					attention_info.verified_t = t

					mvector3.set(attention_info.verified_pos, attention_pos)

					attention_info.last_verified_pos = mvector3.copy(attention_pos)
					attention_info.verified_dis = dis
				elseif attention_info.release_t and attention_info.release_t < t then
					self:_destroy_detected_attention_object_data(attention_info)
				else
					attention_info.release_t = attention_info.release_t or t + attention_info.settings.release_delay
				end
			end
		end
	end
end
