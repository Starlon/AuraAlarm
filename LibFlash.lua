
LibFlash = {
	pool = {},
	New = function(self, frame)
		if not frame then
			error("No frame specified")
		end

		if not self.pool[frame] then
			self.pool[frame] = setmetatable({}, {__mode='k'})
		end

		local obj = next(self.pool[frame] or {}) or {}

		self.pool[frame][obj] = nil

		setmetatable(obj, self)

		self.__index = self

		obj.frame = frame

		obj.UpdateFrame = CreateFrame("Frame")
		obj.UpdateFrame.obj = obj


		return obj
	end,
	Del = function(self) 
		if self.frame or self.pool[self.frame] then
			self.pool[self.frame][self] = true
		end
	end
}

function LibFlash:Stop()
	self.UpdateFrame:SetScript("OnUpdate", nil)
	self.active = false
end

function LibFlash:FadeIn(dur, startA, finishA, callback, data)
	self.UpdateFrame.timer = 0
	self.UpdateFrame.elapsed = 0
	if startA < finishA then
		self.UpdateFrame.progress = 100
	else
		self.UpdateFrame.progress = 0
	end
	local function update(self, elapsed)
		self.timer = self.timer + elapsed

		if self.timer < dur / 100 then
			self.elapsed = self.elapsed + elapsed
			return
		end

		local alpha
		if startA > finishA then 
			alpha = (finishA - startA) * self.progress / 100 + startA
			self.progress = self.progress + 1 / dur
		else
			alpha = (startA - finishA) * self.progress / 100 + finishA
			self.progress = self.progress - 1 / dur
		end

		self.obj.frame:SetAlpha(alpha)
		self.timer = 0
		self.elapsed = 0

		if self.progress > 100 or self.progress <= 0 then
			self.obj:Stop()
			self:SetScript("OnUpdate", nil)
			if callback then callback(data) end
		end
	end

	
	self.UpdateFrame:SetScript("OnUpdate", update)
	self.active = true
end

LibFlash.FadeOut = LibFlash.FadeIn

function LibFlash:Flash(fadeinTime, fadeoutTime, flashDuration, showWhenDone, flashinHoldTime, flashoutHoldTime)
	if not self.childFlash then self.childFlash = LibFlash:New(self.frame) end

	local state = 0

	self.UpdateFrame.timer = 0
	self.UpdateFrame.elapsed = 0
	self.UpdateFrame.smallElapse = 0
	self.UpdateFrame.flashinTimer = 0
	self.UpdateFrame.flashoutTimer = 0
	self.UpdateFrame.flashinHoldTimer = 0
	self.UpdateFrame.flashoutHoldTimer = 0

	local incrementState = function()
		state = state + 1
	end

	local update = function(self, elapsed)
		self.timer = self.timer + elapsed

		self.elapsed = self.elapsed + elapsed

		if self.timer < 0.1 then
			self.smallElapse = self.smallElapse + elapsed
			return
		end

		if state == 0 then
			self.flashinHoldTimer = self.flashinHoldTimer + self.timer

			if self.flashinHoldTimer > flashinHoldTime then
				incrementState()
				self.flashinHoldTimer = 0
			end
		elseif state == 1 then
			if not self.flashin then
				self.flashin = true
				self.obj.childFlash:FadeIn(fadeinTime, 0, 1, incrementState)
			end
		elseif state == 2 then
			self.flashin = false
			self.flashoutHoldTimer = self.flashoutHoldTimer + self.timer

			if self.flashoutHoldTimer > flashoutHoldTime then
				self.obj.childFlash:FadeOut(fadeoutTime, 1, 0, incrementState)
				self.flashoutHoldTimer = 0
			end
		elseif state == 3 then
			if self.elapsed > flashDuration then
				self.obj.UpdateFrame:SetScript("OnUpdate", nil)
				if showWhenDone then
					self.obj.childFlash:FadeIn(.01, 0, 1)
				end
				self.elapsed = 0
			end		
		end

		self.timer = 0
		self.smallElapse = 0
	end

	self.UpdateFrame:SetScript("OnUpdate", update)
end
