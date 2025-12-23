local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local t_rem = table.remove
local t_ins = table.insert
local tmp_vec1 = Vector3()
local world_g = World

Hooks:OverrideFunction(EnemyManager,"_update_queued_tasks",function(self, t, dt)
	local i_asap_task, asap_task_t = nil

	if managers.groupai:state():whisper_mode() then
		for i_task, task_data in ipairs(self._queued_tasks) do
			if not task_data.t or task_data.t < t then
				self:_execute_queued_task(i_task)
			elseif task_data.asap then
				if not asap_task_t or task_data.t < asap_task_t then
					i_asap_task = i_task
					asap_task_t = task_data.t
				end
			end
		end
	else
		self._queue_buffer = self._queue_buffer + dt
		local tick_rate = self._tick_rate

		if tick_rate <= self._queue_buffer then
			for i_task, task_data in ipairs(self._queued_tasks) do
				if not task_data.t or task_data.t < t then
					self:_execute_queued_task(i_task)

					self._queue_buffer = self._queue_buffer - tick_rate

					if self._queue_buffer <= 0 then
						break
					end
				elseif task_data.asap then
					if not asap_task_t or task_data.t < asap_task_t then
						i_asap_task = i_task
						asap_task_t = task_data.t
					end
				end
			end
		end

		if #self._queued_tasks == 0 then
			self._queue_buffer = 0
		else
			self._queue_buffer = math.min(self._queue_buffer, tick_rate * #self._queued_tasks)
		end
	end

	if i_asap_task and not self._queued_task_executed then
		self:_execute_queued_task(i_asap_task)
	end

	local all_clbks = self._delayed_clbks

	if all_clbks[1] and all_clbks[1][2] < t then
		local clbk = t_rem(all_clbks, 1)[3]

		clbk()
	end
end)

