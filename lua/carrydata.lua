Hooks:PostHook(CarryData,"set_latest_peer_id","clientsidedetection_setbagresponsibility",function(self,peer_id)
	if peer_id ~= managers.network:session():local_peer():id() then 
		local attention = self._unit:attention()
		if attention then
			-- don't check clientside detection for this bag if local player was not the most recent
			attention:set_attention(nil)
			self._saved_attention_data = nil
		end
	end
end)

--[[
Hooks:PostHook(CarryData,"init","clientsidedetection_baginit",function(self,unit)
	foo2 = self
	if Network:is_client() then
		-- on bag spawn, bag detection should be only the host's responsibility
		local attention = unit:attention()
		if attention then
			attention:set_attention(nil)
		end
	end
end)
--]]
