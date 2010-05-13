local _G = _G
local pairs = _G.pairs
local UIFrameFlash = _G.UIFrameFlash
local UIFrameFadeIn = _G.UIFrameFadeIn
local UIFrameFadeOut = _G.UIFrameFadeOut

BINDING_HEADER_AURAALARM = "AuraAlarm";
BINDING_NAME_ADDAURA = "Add Aura";

_G.AuraAlarm = LibStub("AceAddon-3.0"):NewAddon("AuraAlarm", "AceConsole-3.0", "AceEvent-3.0")

local AuraAlarm = _G.AuraAlarm

AuraAlarm.hasIcon = true

AuraAlarm.AAFrame = CreateFrame("Frame", "AAFrame", UIParent)
AuraAlarm.AAIconFrame = CreateFrame("Frame", "AAIconFrame", UIParent)
AuraAlarm.AAWatchFrame = CreateFrame("Frame")
AuraAlarm.AARebuildFrame = CreateFrame("Frame")

AuraAlarm.AAFrame.obj = AuraAlarm
AuraAlarm.AAIconFrame.obj = AuraAlarm
AuraAlarm.AAWatchFrame.obj = AuraAlarm
AuraAlarm.AARebuildFrame.obj = AuraAlarm

local L = LibStub("AceLocale-3.0"):GetLocale("AuraAlarm")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("sound", "Crash", [[Sound\Doodad\ArcaneCrystalOpen.wav]])
LSM:Register("sound", "Tribal", [[Sound\Doodad\BellTollTribal.wav]])
LSM:Register("sound", "Boat Bell", [[Sound\Doodad\BoatDockedWarning.wav]])
LSM:Register("sound", "Cannon", [[Sound\Doodad\Cannon01_BlastA.wav]])
LSM:Register("sound", "Machine", [[Sound\Doodad\DR_MachineParts01_Open.wav]])
LSM:Register("sound", "Foghorn", [[Sound\Doodad\DwarfHorn.wav]])
LSM:Register("sound", "Firecrackers", [[Sound\Doodad\FirecrackerStringExplode.wav]])
LSM:Register("sound", "Gong", [[Sound\Doodad\G_GongTroll01.wav]])
LSM:Register("sound", "Mortar", [[Sound\Doodad\G_Mortar.wav]])
LSM:Register("sound", "Netherstorm", [[Sound\Doodad\NetherstormCrackLighting01.wav]])

local soundFiles = LSM:List("sound") -- BUG: This list isn't always the same depending on what addons installed what sound references.

local alarmModes = {L["Flash Background"], L["Persist"], L["Blink"]}

local auraTypes = {L["Harmful"], L["Helpful"]}

local auraNames = {"DEBUFF", "BUFF"}

local supportModes = {L["Normal"], L["Determined"], L["More Determined"]}

local hideIcon = function(self, elapsed)
	self.timer = (self.timer or 0) + 1

	if self.timer > 30 then
		AuraAlarm.AAIconFrame:SetAlpha(0)
		AuraAlarm.AAIconFrame:SetScript("OnUpdate", nil)
		self.timer = 0
	end
end

local opts = { 
	type = 'group',
	args = {
		auras = {
			name = "Auras", 
			type = 'group',
			desc = L["Add and remove auras"],
			args = {},
			order = 1
		},
		x = {
			name = "X",
			desc = L["Frame x position"],
			type = "range",
			get = function()
				return AuraAlarm.db.profile.x
			end,
			set = function(info, v)
				AuraAlarm.db.profile.x = v
				AuraAlarm.AAIconFrame:ClearAllPoints()
				AuraAlarm.AAIconFrame:SetPoint("CENTER", AuraAlarm.db.profile.x, AuraAlarm.db.profile.y)
				AuraAlarm.AAIconFrame:SetAlpha(1)
				AuraAlarm.AAIconFrame:SetScript("OnUpdate", hideIcon)
				AuraAlarm.AAIconFrame.timer = 0
			end,
			min = -math.floor(GetScreenWidth()/2 + 0.5),
			max = math.floor(GetScreenWidth()/2 + 0.5),
			step = 1,
			order = 2
		},
		y = {
			name = "Y",
			desc = L["Frame y position"],
			type = "range",
			get = function()
				return AuraAlarm.db.profile.y
			end,
			set = function(info, v)
				AuraAlarm.db.profile.y = v
				AuraAlarm.AAIconFrame:ClearAllPoints()
				AuraAlarm.AAIconFrame:SetPoint("CENTER", AuraAlarm.db.profile.x, AuraAlarm.db.profile.y)
				AuraAlarm.AAIconFrame:SetAlpha(1)
				AuraAlarm.AAIconFrame:SetScript("OnUpdate", hideIcon)
				AuraAlarm.AAIconFrame.timer = 0

			end,
			min = -math.floor(GetScreenHeight()/2 + 0.5),
			max = math.floor(GetScreenHeight()/2 + 0.5),
			step = 1,
			order = 3
		},
		mode = {
			name = L["Support Mode"],
			desc = L["Use 'Determined' for events that don't show up in the combat log."],
			type = "select",
			values = supportModes,
			get = function()
				return AuraAlarm.db.profile.mode or 1
			end,
			set  = function(info, v)
				AuraAlarm.db.profile.mode = v
				AuraAlarm:ChangeMode(v)
			end,
			order = 4
		},
		determined_rate = {
			name = L["Determined Mode Rate (in ms)"],
			type = "input",
			get = function()
				return tostring((AuraAlarm.db.profile.determined_rate or 1) * 100)
			end,
			set = function(info, v) 
				AuraAlarm.db.profile.determined_rate = tonumber(v) / 100
			end,
			pattern = "%d"
		}
	}
}

local function count(tbl)
	local count = 0
	for k in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function table_find(tbl, el)
	for k, v in pairs(tbl) do
		if v == el then
			return k
		end
	end
	return nil
end

local function getLSMIndexByName(category, name)
	for k, v in pairs(LSM:List(category)) do
		if v == name then
			return k
		end
	end
	return nil
end

local function cleanup(frame, elapsed)
	frame.timer = (frame.timer or 0) + elapsed

	if frame.timer > 300 then
		frame:SetAlpha(0)
		frame:SetScript("OnUpdate", nil)
		frame.timer = 0
	end
end

function AuraAlarm:BuildAurasOpts()
	opts.args.auras.args = {}
	for k,v in ipairs(self.db.profile.auras) do
		opts.args.auras.args["Aura" .. tostring(k)] = {
			name = v.name,
			desc = v.name,
			type = 'group',
			args = {
				aura_name = {
					name = L["Aura Name"],
					type = 'input',
					usage = L["<Aura name here>"],
					desc = L["Name for Aura"] .. tostring(k),
					get = function() return self.db.profile.auras[k].name end,
					set = function(info, value) 
						self.db.profile.auras[k].name = value
						self:BuildAurasOpts() 
					end,
					validate = function(info, value)
						local isNotAlarm = true
						for k,v in pairs(self.db.profile.auras) do
							if value == v.name then
								isNotAlarm = false
							end
						end
						return isNotAlarm
					end,
				order=1
				},
				color = {
					name = L["Color"],
					type = 'color',
					desc = L["Change the flash color"],
					get = function()
						return self.db.profile.auras[k].color[1], self.db.profile.auras[k].color[2], self.db.profile.auras[k].color[3], self.db.profile.auras[k].color[4]
					end,
					set = function(info, r, g, b, a)
						self.db.profile.auras[k].color[1], self.db.profile.auras[k].color[2], self.db.profile.auras[k].color[3], self.db.profile.auras[k].color[4] =r, g, b, a
					end,
					hasAlpha = true,
					order = 2
				},
				soundFile = {
					name = L["Warning Sound"],
					type = "select",
					desc = L["Sound to play"],
					get = function()
						return self.db.profile.auras[k].soundFile or getLSMIndexByName("None") or 1
					end,
					set = function(info, v)
						PlaySoundFile(LSM:Fetch("sound", soundFiles[v]))
						self.db.profile.auras[k].soundFile = v
					end,
					values = soundFiles,
					order=4
				},
				mode = {
					name = L["Mode"],
					type = "select",
					desc = L["Alarm mode"],
					get = function()
						return self.db.profile.auras[k].mode or 1
					end,
					set = function(info, v)
						self.db.profile.auras[k].mode = v
					end,
					values = alarmModes,
					order=5
				},
				blink_rate = {
					name = L["Blink Rate"],
					type = "input",
					get = function() 
						return tostring((self.db.profile.auras[k].blink_rate or 1) / 100)
					end,
					set = function(info, v)
						self.db.profile.auras[k].blink_rate = tonumber(v) * 100
					end,
					pattern = "%d",
					order = 6
				},
				unit = {
					name = L["Unit"], 
					type = "input",
					get = function()
						return self.db.profile.auras[k].unit or "player"
					end,
					set = function(info, v)
						self.db.profile.auras[k].unit = v
					end,
					order = 7
				},
				count = {
					name = L["Stacks"],
					type = "input",
					get = function()
						return tostring(self.db.profile.auras[k].count or 1)
					end,
					set = function(info, v)
						self.db.profile.auras[k].count = tonumber(v)
					end,
					pattern = "%d",
					order = 8
				},
				type = {
					name = L["Type"],
					desc = "AuraType",
					type = "select",
					values = auraTypes,
					get = function()
						return self.db.profile.auras[k].type or 1
					end,
					set = function(info, v)
						self.db.profile.auras[k].type = v
					end,
					order=9
				},
				show_icon = {
					name = L["Show Icon"],
					desc = L["Show icon frame"],
					type = "toggle",
					get = function()
						local show_icon = self.db.profile.auras[k].show_icon
						return show_icon == nil or show_icon == true
					end,
					set = function(info, v)
						self.db.profile.auras[k].show_icon = v
					end,
					order=10
				},
				remove = {
					name = L["Remove"],
					type = 'execute',
					desc = L["Remove aura"],
					func = function() 
						table.remove(self.db.profile.auras, k) 
						self:BuildAurasOpts() 
						self:Print(L["Aura removed."]) 
					end,
					order=100
				},				
			},
			order = k+2			
		}
	end
	opts.args.auras.args.add = {
		name = L["Add Aura"],
		type = 'group',
		desc = L["Add a aura"],
		args = {
			as_text = {
				name = "As Text",
				type = 'input',
				desc = L["Add a aura"],
				usage = L["<New aura here>"],
				set = function(info, v) 
					self.db.profile.auras[#self.db.profile.auras+1] = {name=v, color={1,0,0,.4}, soundFile=getLSMIndexByName("sound", "None"), mode=1} 
					self:BuildAurasOpts() 
					self:Print(L["%s added."]:format(v)) 
				end,
				get = function() end,
				order=1
			},
		},
		order=1
	}

	if self.captured_auras and count(self.captured_auras) > 0 then
		opts.args.auras.args.add.args.captured_header = {
			type = "header",
			name = L["Captured Auras - Click to add"],
			order=2
		}
	end

	local low, hi = 3, 3
	
	for i, v in pairs(self.captured_auras or {})  do
		if self.captured == "DEBUFF" then
			low = low + 1
		else
			hi = hi + 1
		end
	end

	hi = low + hi

	for k,v in pairs(self.captured_auras) do
		local text = k
		if v == "DEBUFF" then text = text .. L[" (D)"] end
		opts.args.auras.args.add.args[k] = {
			name = text,
			type = 'execute',
			func = function()
				self.db.profile.auras[#self.db.profile.auras+1] = {name=k, color={1,0,0,.4}, soundFile=getLSMIndexByName("sound", "None"), mode=1, type=v == "DEBUFF" and 1 or 2} 
				self.captured_auras[k] = nil
				self:BuildAurasOpts()
				self:Print(L["%s added."]:format(k))
			end,
			order = v == "DEBUFF" and low or hi
		}
		if v == "DEBUFF" then
			low = low + 1
		else
			hi = hi + 1
		end
	end
end

function AuraAlarm:OnInitialize()	

    self.db = LibStub("AceDB-3.0"):New("AuraAlarmDB")
	
    LibStub("AceConfig-3.0"):RegisterOptionsTable("AuraAlarm", opts)

	self:RegisterChatCommand("/da", "/auraalarm", opts)
    
    AceConfigDialog:AddToBlizOptions("AuraAlarm")
	
	self.db:RegisterDefaults({
		profile = {
	    auras = {},
	    duration = 1,
	    color = {1, 0, 0},
	    soundFile = "None",
	    flashBackground = true,
	    x = 0,
	    y = 0,
	    mouse = true
		}
	})
	
	self.captured_auras = {}
	self:BuildAurasOpts()	
	
	self.AAFrame:SetFrameStrata("BACKGROUND")
	self.AAFrame:SetFrameLevel(0)
	self.AAFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
		tile = true, 
		tileSize = 16,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	self.AAFrame:ClearAllPoints()
	self.AAFrame:SetAllPoints(UIParent)
	
	if not self.db.profile.mouse then self.db.profile.mouse = false end
	if not self.db.profile.x then self.db.profile.x = 0 end
	if not self.db.profile.y then self.db.profile.y = 0 end

	self.AAIconFrame:SetFrameStrata("BACKGROUND")
	self.AAIconFrame:SetHeight(44)
	self.AAIconFrame:SetWidth(80)
	self.AAIconFrame:EnableMouse(self.db.profile.locked or false)
	self.AAIconFrame:SetMovable(true)
	self.AAIconFrame:SetPoint("CENTER", UIParent, self.db.profile.x, self.db.profile.y);
	self.AAIconFrame:SetFrameStrata("DIALOG")
	self.AAIconFrame:SetFrameLevel(0)
	self.AAIconFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=16, 
		insets = { left = 4, right = 4, top = 4, bottom = 4}})
	self.AAIconFrame:SetBackdropColor(0, 1, 0, 1)
	self.AAIconFrame:SetBackdropBorderColor(0, 0, 0, 1)

	self.AAIconFrame.Text = self.AAIconFrame:CreateFontString("AAtext", "LEFT")
	self.AAIconFrame.Text:SetPoint("LEFT", 34, 0)
	self.AAIconFrame.Text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, MONOCHROME")
	self.AAIconFrame.Text:SetFontObject(GameFontNormal)

	self.AAIconFrame.Icon = self.AAIconFrame:CreateTexture(nil,"DIALOG")
	self.AAIconFrame.Icon:SetPoint("LEFT", 10, 0)
	self.AAIconFrame.Icon:SetTexture(select(3, GetSpellInfo("Slam")))
	self.AAIconFrame.Icon:SetHeight(24)
	self.AAIconFrame.Icon:SetWidth(24)

	self.AAWatchFrame.obj = self
	local mode = supportModes[self.db.profile.mode or 1]
	if self.db.profile.mode > 1  then -- Determined and More Determined
		self.AAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
	end

	self.AAWatchFrame.active = false
	
end

function AuraAlarm:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.AAFrame:SetBackdropColor(0, 0, 0, 0)
	self.AAFrame:Show()
	self.AAIconFrame:SetAlpha(0)
	self.AAIconFrame:Show()
	self:ChangeMode(self.db.profile.mode or 1)
end

function AuraAlarm:OnDisable()
	if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then 
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
	end
	self.AAFrame:Hide()
	self.AAIconFrame:Hide()
	self:ChangeMode(1)
end

function AuraAlarm:WatchForAura(elapsed)
	self.timer = (self.timer or 0) + elapsed
	self.fallTimer = (self.fallTimer or 0) + elapsed

	local show_icon
	local name, icon, count, expirationTime, id, _

	if self.timer > (self.obj.db.profile.determined_rate or 1) then
		for k, v in pairs(self.obj.db.profile.auras) do
			for i = 1, 40 do
				local aura = v

				if supportModes[self.obj.db.profile.mode] == L["More Determined"]  then for i, type in pairs(auraNames) do
					for i = 1, 40 do
						if type == "DEBUFF" then
							name = UnitDebuff("player", i)
						else
							name = UnitBuff("player", i)
						end 
						if name and not self.obj.captured_auras[name] then
							local test = false
							for i = 1, #self.obj.db.profile.auras do
								if self.obj.db.profile.auras[i].name == name then
									test = true
								end
							end
							if not test then
								self.obj.captured_auras[name] = type
								self.obj.AARebuildFrame:SetScript("OnUpdate", self.obj.ProcessCaptures)
							end
						end
					end
				end end

				if auraNames[v.type or 1] == "DEBUFF" then
					name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitDebuff(v.unit or "player", i)
				else
					name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitBuff(v.unit or "player", i)
				end


				local isStacked = true
				local stackText = ""

				if count == 0 or count == nil then
					isStacked = false
				else
					stackText = tostring(count)
				end

				local stackTest = (isStacked and aura.count == count) or isStacked == false


				if isStacked and name then
					self.obj.AAIconFrame:SetWidth(80)
				elseif name then
					self.obj.AAIconFrame:SetWidth(44)
				end

				local first_time = false
				if name and name == v.name and not self.active and ((isStacked and count == v.count) or not isStacked) then
					self.obj.AAFrame:SetBackdropColor(v.color[1], v.color[2], v.color[3], v.color[4])
					if alarmModes[v.mode or 1] == L["Persist"] or alarmModes[v.mode or 1] == L["Blink"]then 
						UIFrameFadeIn(self.obj.AAFrame, .3, 0, 1)
						if v.show_icon == nil or v.show_icon then
							UIFrameFadeIn(self.obj.AAIconFrame, .3, 0, 1)
						end
						self.wasPersist = true
					else
						UIFrameFlash(self.obj.AAFrame, .3, .3, 1.6, false, 0, 1)
						if v.show_icon or true then
							UIFrameFlash(self.obj.AAIconFrame, .3, .3, 3.6, false, 0, 3)
						end
					end
					self.show_icon = v.show_icon
					self.active = true
					first_time = true
				end
				if name and name == v.name and (count == nil or count == 0 or v.count ~= count) then
					self.obj.AAIconFrame.Icon:SetTexture(icon)
					self.obj.AAIconFrame.Text:SetText(stackText)
					self.fallOff = expirationTime - GetTime()
					if self.fallOff < 0 then
						self.fallOff = 100
					end
					if (v.mode or 1) == table_find(alarmModes, "Blink") then
						self.obj:Print("blink")
						self.fallOff = (v.blink_rate or 1) / 100
						self.obj:Print(self.fallTimer .. " " .. self.fallOff)
					end
					self.fallTimer = 0
				end
				if self.active and (self.fallTimer or 0xdead) > (self.fallOff or 0xbeef) then
					PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile]))
					UIFrameFadeOut(self.obj.AAFrame, .3, 1, 0)
					if v.show_icon then
						UIFrameFadeOut(self.obj.AAIconFrame, .3, 1, 0)
					end
					self.active = false
					
				end
				if not v.count or first_time then
					PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile]))
				end
                        end
		end
		this.timer = 0
	end
	if self.active and (self.fallTimer or 0xdead) > (self.fallOff or 0xbeef)  then
		self.active = false
		self.timer = 0
		if self.wasPersist then
			self.obj:Print("was persist")
			UIFrameFadeOut(self.obj.AAFrame, .3, 1, 0)
			if self.show_icon or true then 
				UIFrameFadeOut(self.obj.AAIconFrame, .3, 1, 0)
			end
			self.wasPersist = false
		end
		self.Falltimer = 0
	end

end

function AuraAlarm:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local _, eventtype, _, _, _, _, dst_name, _, _, aura_name, _, aura_type = ...

	if self.db.profile.mode > 1 then return end -- just in case

	if (eventtype ~= "SPELL_AURA_APPLIED" and eventtype ~= "SPELL_AURA_REMOVED") then return end
	
	for k, v in pairs(self.db.profile.auras) do
		local aura = v
		if aura_name == v.name and dst_name == UnitName(aura.unit or "player") then
			
			local count
			if aura_type == "DEBUFF" then 
				count = select(4, UnitAura(aura.unit or "player", aura_name, "", "HARMFUL"))
			else
				count = select(4, UnitAura(aura.unit or "player", aura_name, "", "HELPFUL"))
			end
			local isStacked = true
			local stackText = ""

			if count == 0 or count == nil then
				isStacked = false
			else
				stackText = tostring(count)
			end

			local stackTest = (isStacked and aura.count == count) or isStacked == false

			self.AAIconFrame.Text:SetText(stackText)

			if isStacked then
				self.AAIconFrame:SetWidth(80)
			else
				self.AAIconFrame:SetWidth(44)
			end

			if alarmModes[v.mode] == L["Flash Background"] and eventtype == "SPELL_AURA_APPLIED" and stackTest then
				self.AAFrame:SetBackdropColor(v.color[1], v.color[2], v.color[3], v.color[4])
				UIFrameFlash(self.AAFrame, .3, .3, 1.6, false, 0, 1) 
				UIFrameFlash(self.AAIconFrame, .3, .3, 3.6, false, 0, 3)
			elseif alarmModes[v.mode] == L["Persist"] then
				if eventtype == "SPELL_AURA_APPLIED" and stackTest then
					self.AAFrame:SetBackdropColor(v.color[1], v.color[2], v.color[3], v.color[4])
					UIFrameFadeIn(self.AAFrame, .3, 0, 1)
					if v.show_icon then
						UIFrameFadeIn(self.AAIconFrame, .3, 0, 1)
					end
					self.AAFrame:SetScript("OnUpdate", cleanup) -- all alarms have a hard timeout of 5 minutes before hiding the background frame
					self.AAIconFrame:SetScript("OnUpdate", cleanup) -- this is because sometimes the combat log stops working
				elseif stackTest then
					UIFrameFadeOut(self.AAFrame, .3, 1, 0)
					if v.show_icon then
						UIFrameFadeOut(self.AAIconFrame, .3, 1, 0)
					end
				end
			end
			if eventtype == "SPELL_AURA_APPLIED" then 
				PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile]))
				self.AAIconFrame.Icon:SetTexture(select(3, UnitAura(aura.unit or "player", aura_name, "", "HARMFUL")))
			end
			return
		end
	end
	
	if not self.captured_auras[aura_name] and dst_name == UnitName("player") then 
		self.captured_auras[aura_name] = aura_type 
		self.AARebuildFrame:SetScript("OnUpdate", self.ProcessCaptures)
	end
    
end

function AuraAlarm:ChangeMode(v)
	if supportModes[v] == L["Normal"] then
		self.AAWatchFrame:SetScript("OnUpdate", nil)
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self.AAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

function AuraAlarm:AddAuraUnderMouse()
	local scannedText = GameTooltipTextLeft1:GetText()
	local i = 1
	while true do
		local buffIndex = GetPlayerBuff(i, "HARMFUL")
		if buffIndex < 1 then break end
		local buffName = GetPlayerBuffName(buffIndex)
		local isNotAlarm = true
		for k,v in pairs(self.db.profile.auras) do
			if buffName == v.name then
				isNotAlarm = false
				break
			end
		end
		if isNotAlarm and buffName == scannedText then
			self.db.profile.auras[#self.db.profile.auras+1] = {name=buffName, color={1,0,0}, duration=1, soundFile="None", flashBackground=true} 
			self:BuildAurasOpts() 
			self:Print(L["%s added to AuraAlarm."], buffName)
			break
		end
		i = i + 1
	end
end

function AuraAlarm:ProcessCaptures(elapsed)
	self.timer = (self.timer or 0) + elapsed

	if self.timer > 1 then
		if InCombatLockdown() then
			self.timer = 0
			return
		end
		self.obj:BuildAurasOpts()
		self.timer = 0
		self:SetScript("OnUpdate", nil)
	end
end
