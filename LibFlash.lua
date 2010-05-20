
Flash = {
	pool = setmetatable({},{__mode='k'}),
	New = function(self, frame)
		if not frame then
			error("No frame specified")
		end

		local obj = next(self.pool or {}) or {}

		self.pool[obj] = nil

		setmetatable(obj, self)

		self.__index = self

		obj.frame = frame

		obj.UpdateFrame = CreateFrame("Frame")
		obj.UpdateFrame.obj = obj


		return obj
	end,
	Del = function(self) 
		self.pool[self] = true
	end
}

function Flash:FadeIn(dur, startA, finishA)
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
			self:SetScript("OnUpdate", nil)
		end
	end

	
	self.UpdateFrame:SetScript("OnUpdate", update)
end

Flash.FadeOut = Flash.FadeIn

function Flash:Flash(fadeinTime, fadeoutTime, flashduration, showWhendone, flashinHoldTime, flashoutHoldTime)

end
