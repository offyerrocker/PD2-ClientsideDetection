blasudifh = "flasdjfal;sfkja;"

Hooks:PostHook(CharacterAttentionObject,"init","clientsidedetection_charattentionobj",function(self,unit,is_not_extension)
	self._LUA_SOURCE = debug.traceback()
end)