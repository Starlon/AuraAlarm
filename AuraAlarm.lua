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

local soundFiles = LSM:List("sound") 

local alarmModes = {L["Flash Background"], L["Persist"], L["Blink"]}

local FLASH_MODE, PERSIST_MODE, BLINK_MODE = 1, 2, 3

local auraTypes = {L["Harmful"], L["Helpful"]}

local typeNames = {"DEBUFF", "BUFF"}

local supportModes = {L["Normal"], L["Determined"]}

local NORML_MODE, DETERMINED_MODE, MORE_DETERMINED_MODE = 1, 2, 3

local FADE_IN, FADE_OUT = 1, 2

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
	self.opts.args.auras.args = {}
	for k,v in ipairs(self.db.profile.auras) do
		self.opts.args.auras.args["Aura" .. tostring(k)] = {
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
					order=2
				},
				color = {
					name = L["Color"],
					type = 'color',
					desc = L["Change the flash color"],
					get = function()
						return self.db.profile.auras[k].color.r / 255, self.db.profile.auras[k].color.g / 255, self.db.profile.auras[k].color.b / 255, self.db.profile.auras[k].color.a / 255
					end,
					set = function(info, r, g, b, a)
						self.db.profile.auras[k].color.r, self.db.profile.auras[k].color.g, self.db.profile.auras[k].color.b, self.db.profile.auras[k].color.a = r * 255, g * 255, b * 255, a * 255
					end,
					hasAlpha = true,
					order = 3
				},
				soundFile = {
					name = L["Warning Sound"],
					type = "select",
					desc = L["Sound to play"],
					get = function()
						return table_find(LSM:List("sound"), self.db.profile.auras[k].soundFile or "None")
					end,
					set = function(info, v)
						PlaySoundFile(LSM:Fetch("sound", soundFiles[v]))
						self.db.profile.auras[k].soundFile = soundFiles[v]
					end,
					values = soundFiles,
					order = 4
				},
				soundPersist = {
					name = L["Persisting Sound"],
					type = "toggle",
					desc = L["Toggle repeating sound throughout aura. This only pertains to Persist Mode."],
					get = function()
						return self.db.profile.auras[k].soundPersist
					end,
					set = function(info, v)
						if v then
							self.opts.args.auras.args["Aura" .. tostring(k)].args.soundRate.disabled = false
						else
							self.opts.args.auras.args["Aura" .. tostring(k)].args.soundRate.disabled = true
						end
						self.db.profile.auras[k].soundPersist = v
					end,
					disabled = self.db.profile.auras[k].mode ~= PERSIST_MODE,
					order = 5
				},
				soundRate = {
					name = L["Sound Rate"],
					type = "input",
					desc = L["Rate at which Persisting Sound will fire. This is in milliseconds."],
					get = function()
						return tostring(self.db.profile.auras[k].soundRate or 3)
					end,
					set = function(info, v)
						self.db.profile.auras[k].soundRate = tonumber(v)
					end,
					pattern = "%d",
					disabled = not (self.db.profile.auras[k].mode == PERSIST_MODE and self.db.profile.auras[k].soundPersist),
					order = 6
				},
				mode = {
					name = L["Mode"],
					type = "select",
					desc = L["Alarm mode"],
					get = function()
						return self.db.profile.auras[k].mode or 1
					end,
					set = function(info, v)
						if alarmModes[v] == L["Persist"] then
							self.opts.args.auras.args["Aura" .. tostring(k)].args.soundPersist.disabled = false
							if self.db.profile.auras[k].soundPersist then
								self.opts.args.auras.args["Aura" .. tostring(k)].args.soundRate.disabled = false
							end
						else
							self.opts.args.auras.args["Aura" .. tostring(k)].args.soundPersist.disabled = true
							self.opts.args.auras.args["Aura" .. tostring(k)].args.soundRate.disabled = true
						end
						self.db.profile.auras[k].mode = v
						self.AAWatchFrame.active = false
					end,
					values = alarmModes,
					order = 7
				},
				blinkRate = {
					name = L["Blink Rate"],
					type = "input",
					get = function() 
						return tostring((self.db.profile.auras[k].blinkRate or 1) * 100)
					end,
					set = function(info, v)
						self.db.profile.auras[k].blinkRate = tonumber(v) / 100
					end,
					pattern = "%d",
					order = 8
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
					order = 9
				},
				count = {
					name = L["Stacks"],
					desc = L["0 means do not consider stack count."],
					type = "input",
					get = function()
						return tostring(self.db.profile.auras[k].count or 0)
					end,
					set = function(info, v)
						self.db.profile.auras[k].count = tonumber(v)
					end,
					pattern = "%d",
					order = 10
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
					order=12
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
	self.opts.args.auras.args.add = {
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
					self.db.profile.auras[#self.db.profile.auras+1] = {name=v, color={r=255,g=0,b=0,a=42}, soundFile="None", mode=1} 
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
		self.opts.args.auras.args.add.args.captured_header = {
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
		self.opts.args.auras.args.add.args[k] = {
			name = text,
			type = 'execute',
			func = function()
				self.db.profile.auras[#self.db.profile.auras+1] = {name=k, color={r=255,g=0,b=0,a=42}, soundFile="None", mode=1, type=v == "DEBUFF" and 1 or 2} 
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

	self.opts = opts

	LibStub("AceConfig-3.0"):RegisterOptionsTable("AuraAlarm", opts)

	self:RegisterChatCommand("/da", "/auraalarm", opts)
    
	AceConfigDialog:AddToBlizOptions("AuraAlarm")
	
	self.db:RegisterDefaults({
		profile = {
		    auras = {},
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
	if self.db.profile.mode ~= NORML_MODE  then -- Determined
		self.AAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
	end

	self.AAWatchFrame.active = false
	
end

function AuraAlarm:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.AAFrame:SetBackdropColor(0, 0, 0, 0)
	self.AAFrame:Show()
	if self.db.profile.mode ~= NORML_MODE then	
		self.AAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
	end
	self.AAIconFrame:SetAlpha(0)
	self.AAIconFrame:Show()
	self:ChangeMode(self.db.profile.mode or 1)
end

function AuraAlarm:OnDisable()
	if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then 
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
	end
	self.AAFrame:Hide()
	self.AAWatchFrame:SetScript("OnUpdate", nil)
	self.AAIconFrame:Hide()
	self:ChangeMode(1)
end

local function findByIndex(tbl, i)
	if not tbl then return nil end

	for k, v in pairs(tbl) do
		if v.i == i then
			return v.table
		end
	end
	return nil
end

function AuraAlarm:WatchForAura(elapsed)

	local show_icon
	local name, icon, count, expirationTime, id, _

	if not self.current_alarms then 
		self.current_alarms = {}
		for i, v in ipairs(self.obj.db.profile.auras) do

			self.current_alarms[v] = {name=v.name, type=v.type, unit=v.unit or "player", mode=v.mode, blinkRate=v.blinkRate, show_icon=v.show_icon, active=false, table=v, i=i}
		end
	end

	if self.current then
		self.current = findByIndex(self.current_alarms, self.current_alarms[self.current].i + 1)
	end

	if not self.current then
		self.current = findByIndex(self.current_alarms, 1) 
	end

	local alarm = self.current_alarms[self.current]

	alarm.timer = (alarm.timer or 0) + elapsed / #self.current_alarms
	alarm.fallTimer = (alarm.fallTimer or 0) + elapsed / #self.current_alarms
	alarm.blinkTimer = (alarm.blinkTimer or 0) + elapsed / #self.current_alarms
	alarm.soundTimer = (alarm.soundTimer or 0) + elapsed / #self.current_alarms

	local units = {}

	for i, v in pairs(self.obj.db.profile.auras) do
		units[#units + 1] = v.unit or "player"
	end

	if not units[1] then
		units[1] = "player"
	end

	local auras = {}
	
	for _, unit in ipairs(units) do
		
		auras[unit] = {DEBUFF={}, BUFF={}}
		for i = 1, 40 do
			name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitDebuff(unit, i)
			if name then 
				auras[unit]['DEBUFF'][name] = {name=name, icon=icon, count=count, expirationTime=expirationTime, id=id, unit=v, i=i} 
				auras[unit]['DEBUFF'][i] = auras[unit]['DEBUFF'][name]
			end
			name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitBuff(unit, i)
			if name then 
				auras[unit]['BUFF'][name] = {name=name, icon=icon, count=count, expirationTime=expirationTime, id=id, unit=v, i=i} 
				auras[unit]['BUFF'][i] = auras[unit]['BUFF'][name]
			end
		end

	end

	for i, type in pairs(typeNames) do
		for i = 1, 40 do
			name = auras["player"][type][i] and auras["player"][type][i].name
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
	end

	if self.current_alarms[self.current].timer > (self.obj.db.profile.determined_rate or 1) then
		local i = alarm.i
		local v = self.current

			local aura
			local at = auras[v.unit or "player"]

			if at and at[typeNames[v.type or 1] ] then
				aura = at[typeNames[v.type or 1] ][v.name]
			end

			if aura then
				name, icon, count, expirationTime, id = aura.name, aura.icon, aura.count, aura.expirationTime, aura.id
			end

			local isStacked = true
			local stackText = ""

			if count == 0 or count == nil then
				isStacked = false
			else
				stackText = tostring(count)
			end

			local stackTest = (isStacked and aura and aura.count == count) or not isStacked


			if isStacked and name then
				self.obj.AAIconFrame:SetWidth(80)
			elseif name then
				self.obj.AAIconFrame:SetWidth(44)
			end

			local first_time = false
			if name and name == v.name and not alarm.active and (isStacked and v.count == count or not isStacked) then
				local r, g, b, a = 0, 0, 0, 0
				
				self.obj.AAFrame:SetBackdropColor(v.color.r / 255, v.color.g / 255, v.color.b / 255, v.color.a / 255)
				if alarmModes[v.mode or 1] == L["Persist"] or alarmModes[v.mode or 1] == L["Blink"] then 
					UIFrameFadeIn(self.obj.AAFrame, .3, 0, 1)
					if v.show_icon == nil or v.show_icon then
						UIFrameFadeIn(self.obj.AAIconFrame, .3, 0, 1)
					end
					alarm.wasPersist = true
				else
					UIFrameFlash(self.obj.AAFrame, .3, .3, 1.6, false, 0, 1)
					if alarm.show_icon == nil or alarm.show_icon then
						UIFrameFlash(self.obj.AAIconFrame, .3, .3, 3.6, false, 0, 3)
					end
				end
				alarm.show_icon = v.show_icon
				alarm.active = true
				first_time = true
				alarm.blinkTimer = 0
			end
			if name and name == v.name  then
				if (isStacked and count ~= alarm.lastCount) or (v.soundPersist and alarm.soundTimer > (v.soundRate or 2) and v.mode == PERSIST_MODE) or first_time then
					PlaySoundFile(LSM:Fetch("sound", soundFiles[getLSMIndexByName("sound", v.soundFile) or getLSMIndexByName("sound", "None")]))
					if isStacked and count ~= alarm.lastCount then
						alarm.lastCount = count
					end
					alarm.soundTimer = 0
				end
				self.obj.AAIconFrame.Icon:SetTexture(icon)
				self.obj.AAIconFrame.Text:SetText(stackText)
				alarm.fallOff = expirationTime - GetTime()
				if alarm.fallOff < 0 then
					alarm.fallOff = 0xdeadbeef
				end
				alarm.fallTimer = 0
			end
			if name == (v.name or "") and alarm.blinkTimer > (v.blinkRate or 1 + .6) and v.mode == table_find(alarmModes, L["Blink"]) and not first_time then
				UIFrameFadeOut(self.obj.AAFrame, .3, 1, 0)
				if v.show_icon == nil or v.show_icon then
					UIFrameFadeOut(self.obj.AAIconFrame, .3, 1, 0)
				end
				if alarm.fallTimer > alarm.fallOff then
					alarm.fallTimer = 0
				end	
				alarm.firstSound = false
				alarm.active = false
				alarm.blinkTimer = 0
				alarm.blinkRate = v.blinkRate
			end
		alarm.timer = 0
	end

	local activeAura = false
	if alarm and alarm.active then for i = 1, 40 do
		if alarm.name then
			local aura = auras[alarm.unit or "player"]

			if aura then
				aura = aura[typeNames[alarm.type or 1]][name]
			end

			if aura and alarm.name == aura.name then
				activeAura = true
			end
		end
	end end

	if alarm.active and (alarm.fallTimer or 0xbeef) > (alarm.fallOff or 0xdead) then
		if alarm.wasPersist then
			UIFrameFadeOut(self.obj.AAFrame, .3, 1, 0)
			if alarm.show_icon == nil or alarm.show_icon then 
				UIFrameFadeOut(self.obj.AAIconFrame, .3, 1, 0)
			end
		end
		for k, v in pairs(self.current_alarms) do
			v.active = false
		end
		alarm.fallTimer = 0
	end
end

function AuraAlarm:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local _, eventtype, _, _, _, _, dst_name, _, _, aura_name, _, aura_type = ...

	if self.db.profile.mode ~= NORML_MODE then return end -- just in case

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
				self.AAFrame:SetBackdropColor(v.color.r, v.color.g, v.color.b, v.color.a)
				UIFrameFlash(self.AAFrame, .3, .3, 1.6, false, 0, 1) 
				UIFrameFlash(self.AAIconFrame, .3, .3, 3.6, false, 0, 3)
			elseif alarmModes[v.mode] == L["Persist"] then
				if eventtype == "SPELL_AURA_APPLIED" and stackTest then
					self.AAFrame:SetBackdropColor(v.color.r, v.color.g, v.color.b, v.color.a)
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
				if v.playSound then
					PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile and getLSMIndexByName("sound", v.soundFile or "None") or 1]))
				end
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
			self.db.profile.auras[#self.db.profile.auras+1] = {name=buffName, color={r=1,g=0,b=0,a=0}, duration=1, soundFile="None", flashBackground=true} 
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

