Hooks:OverrideFunction(PlayerMovement,"clbk_attention_notice_sneak",function(self, observer_unit, status, local_client_detection)
	if alive(observer_unit) then
		self:on_suspicion(observer_unit, status, local_client_detection)
	end
end)

-- completely vanilla detection code, with the exception of the third argument and corresponding check
Hooks:OverrideFunction(PlayerMovement,"on_suspicion",function(self, observer_unit, status, local_client_detection)
	if Network:is_server() or local_client_detection then
		self._suspicion_debug = self._suspicion_debug or {}
		self._suspicion_debug[observer_unit:key()] = {
			unit = observer_unit,
			name = observer_unit:name(),
			status = status
		}
		local visible_status = nil

		if managers.groupai:state():whisper_mode() and not managers.groupai:state():stealth_hud_disabled() then
			visible_status = status
		else
			visible_status = false
		end

		self._suspicion = self._suspicion or {}

		if visible_status == false or visible_status == true then
			self._suspicion[observer_unit:key()] = nil

			if not next(self._suspicion) then
				self._suspicion = nil
			end

			if visible_status and observer_unit:movement() and not observer_unit:movement():cool() and TimerManager:game():time() - observer_unit:movement():not_cool_t() > 1 then
				self._suspicion_ratio = false

				self:_feed_suspicion_to_hud()

				return
			end
		elseif type(visible_status) == "number" and (not observer_unit:movement() or observer_unit:movement():cool()) then
			self._suspicion[observer_unit:key()] = visible_status
		else
			return
		end

		self:_calc_suspicion_ratio_and_sync(observer_unit, visible_status, local_client_detection) -- also passes the local detection flag
	else
		self._suspicion_ratio = status
	end

	self:_feed_suspicion_to_hud()
end)

-- again vanilla except for local detection check
Hooks:OverrideFunction(PlayerMovement,"_calc_suspicion_ratio_and_sync",function(self, observer_unit, status, local_client_detection)
	local suspicion_sync = nil

	if self._suspicion and status ~= true then
		local max_suspicion = nil

		for u_key, val in pairs(self._suspicion) do
			if not max_suspicion or max_suspicion < val then
				max_suspicion = val
			end
		end

		if max_suspicion then
			self._suspicion_ratio = max_suspicion
			suspicion_sync = math.ceil(self._suspicion_ratio * 254)
		else
			self._suspicion_ratio = false
			suspicion_sync = false
		end
	elseif type(status) == "boolean" then
		self._suspicion_ratio = status
		suspicion_sync = status and 255 or 0
	else
		self._suspicion_ratio = false
		suspicion_sync = 0
	end

	if not local_client_detection and suspicion_sync ~= self._synced_suspicion then
		self._synced_suspicion = suspicion_sync
		local peer = managers.network:session():peer_by_unit(self._unit)

		if peer then
			managers.network:session():send_to_peers_synched("suspicion", peer:id(), suspicion_sync)
		end
	end
end)

-- set detection changes locally
-- but don't send them to host as client
Hooks:OverrideFunction(PlayerMovement,"set_attention_settings",function(self,settings_list)
	local changes = self._attention_handler:chk_settings_diff(settings_list)

	if not changes then
		return
	end

	local all_attentions = nil

	local function _add_attentions_to_all(names)
		for _, setting_name in ipairs(names) do
			local setting_desc = tweak_data.attention.settings[setting_name]

			if setting_desc then
				all_attentions = all_attentions or {}
				local setting = self:_create_attention_setting_from_descriptor(setting_desc, setting_name)
				all_attentions[setting_name] = setting
			else
				debug_pause_unit(self._unit, "[PlayerMovement:set_attention_settings] invalid setting", setting_name, self._unit)
			end
		end
	end

	if changes.added then
		_add_attentions_to_all(changes.added)
	end

	if changes.maintained then
		_add_attentions_to_all(changes.maintained)
	end

	self._attention_handler:set_settings_set(all_attentions)

	-- change: don't sync attention settings to host!
	-- that reboots the attention settings for the player husk detection object on the host side,
	-- which is exactly what we are trying to avoid
	if false and Network:is_client() then
		if changes.added then
			for _, id in ipairs(changes.added) do
				local index = tweak_data.attention:get_attention_index(id)

				self._unit:network():send_to_host("set_attention_enabled", index, true)
			end
		end

		if changes.removed then
			for _, id in ipairs(changes.removed) do
				local index = tweak_data.attention:get_attention_index(id)

				self._unit:network():send_to_host("set_attention_enabled", index, false)
			end
		end
	end
end)
