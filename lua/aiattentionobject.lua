
function AIAttentionObject:init(unit, is_not_extension)
	self._LUA_SOURCE = debug.traceback()
	
	self._unit = unit
	self._attention_data = nil
	self._listener_holder = ListenerHolder:new()

	self:setup_attention_positions(nil, nil)

	self._is_extension = not is_not_extension

	if self._is_extension then
		if Network:is_client() and unit:unit_data().only_visible_in_editor then
			unit:set_visible(false)
		end

		if self._initial_settings then
			local preset_list = string.split(self._initial_settings, " ")

			for _, preset_name in ipairs(preset_list) do
				local attention_desc = tweak_data.attention.settings[preset_name]
				local att_setting = PlayerMovement._create_attention_setting_from_descriptor(self, attention_desc, preset_name)

				self:add_attention(att_setting)
			end
		end

		self:set_update_enabled(true)
	end
end
