local _G = _G
local pairs = _G.pairs

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

local NORML_MODE, DETERMINED_MODE = 1, 2

local alarmSets = {L["Default"]}

local FADE_IN, FADE_OUT = 1, 2

local new, del, newDict
do
	local pool = setmetatable({},{__mode='k'})
	function new(...)
		local t = next(pool)
		if t then
			for k, v in pairs(t) do
				t[k] = nil
			end
			pool[t] = nil
			for i=1, select("#", ...) do
				t[i] = select(i, ...)
			end
			return t
		else
			return {...}
		end
	end
	function newDict(...)
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = {}			
		end
		for k, v in pairs(t) do
			t[k] = nil
		end
		for i=1, select("#", ...), 2 do
			t[select(i, ...)] = select(i+1, ...)
		end
		return t
	end
	function del(t)
		if not t or type(t) ~= "table" then error("Argument passed is invalid, expected a table.") end
		for k in pairs(t) do
			t[k] = nil
		end
		pool[t] = true
	end
end

local hideIcon = function(self, elapsed)
	self.timer = (self.timer or 0) + 1

	if self.timer > 30 then
		AuraAlarm.AAIconFrame:SetAlpha(0)
		AuraAlarm.AAIconFrame:SetScript("OnUpdate", nil)
		self.timer = 0
	end
end

local function count(tbl)
	local count = 0
	for k in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function round(num)
	return math.floor(num + 0.5)
end

local function tableFind(tbl, el)
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

local function clearCurrentAlarms()
	AuraAlarm.AAWatchFrame.background:Stop()
	AuraAlarm.AAWatchFrame.icon:Stop()
	del(AuraAlarm.AAWatchFrame.currentAlarms)
	AuraAlarm.AAWatchFrame.currentAlarms = nil
	AuraAlarm.AAWatchFrame.current = nil
end

local newFont, delFont
do
	local pool = {} --setmetatable({},{__mode='k'})
	newFont = function(frame)
		if not frame or type(frame) ~= "table" then error("Argument passed is invalid, expected a table.") end
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = frame:CreateFontString(nil, "LEFT")
			t:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, MONOCHROME")
	                t:SetFontObject(GameFontNormal)
		end
		return t
	end

	delFont = function(t)
		if not t or type(t) ~= "table" then error("Argument passed is invalid, expected a table.") end
		t:SetText("")
		pool[t] = true
	end
end

local newIcon, delIcon
do
	local pool = {} --setmetatable({}, {__mode='k'})
	newIcon = function(frame)
		if not frame or type(frame) ~= "table" then error("Argument passed is invalid, expected a table.") end
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = frame:CreateTexture(nil, "DIALOG")
			t:SetHeight(24)
			t:SetWidth(24)
		end
		return t
	end

	delIcon = function(t)
		if not t or type(t) ~= "table" then error("Argument passed is invalid, expected a table.") end
		t:SetTexture(nil)
		pool[t] = true
	end
end

local function refreshIcons()
	if AuraAlarm.AAIconFrame.icons then
		for k, v in pairs(AuraAlarm.AAIconFrame.icons) do
			delIcon(v)
		end
		del(AuraAlarm.AAIconFrame.icons)
	end
	if AuraAlarm.AAIconFrame.texts then
		for k, v in pairs(AuraAlarm.AAIconFrame.texts) do
			delFont(v)
		end
		del(AuraAlarm.AAIconFrame.texts)
	end
        AuraAlarm.AAIconFrame.icons = new()
        AuraAlarm.AAIconFrame.texts = new()
        for i, v in pairs(AuraAlarm.db.profile.auras) do
                if not AuraAlarm.AAIconFrame.icons[v] then
                        AuraAlarm.AAIconFrame.icons[v] = newIcon(AuraAlarm.AAIconFrame)
                end
                if not AuraAlarm.AAIconFrame.texts[v] then
                        AuraAlarm.AAIconFrame.texts[v] = newFont(AuraAlarm.AAIconFrame)
                end
        end
end

function applySet()
	for i, v in ipairs(AuraAlarm.db.profile.sets[AuraAlarm.db.profile.currentSet] or new()) do
		if not AuraAlarm.db.profile.auras[i] then
			break
		end
		AuraAlarm.db.profile.auras[i].enabled = v
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
						for k, v in pairs(self.AAWatchFrame.currentAlarms or {}) do
							v.active = false
						end
					end,
					hasAlpha = true,
					order = 3
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
						for k, v in pairs(self.AAWatchFrame.currentAlarms) do
							v.active = false
						end
					end,
					values = alarmModes,
					order = 4
				},
				soundFile = {
					name = L["Warning Sound"],
					type = "select",
					desc = L["Sound to play"],
					get = function()
						return tableFind(LSM:List("sound"), self.db.profile.auras[k].soundFile or "None")
					end,
					set = function(info, v)
						PlaySoundFile(LSM:Fetch("sound", soundFiles[v]))
						self.db.profile.auras[k].soundFile = soundFiles[v]
					end,
					values = soundFiles,
					order = 5
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
					order = 6
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
					order = 7
				},
--[[
				blinkRate = {
					name = L["Blink Rate"],
					type = "input",
					get = function() 
						return tostring((self.db.profile.auras[k].blinkRate or .3) * 100)
					end,
					set = function(info, v)
						self.db.profile.auras[k].blinkRate = tonumber(v) / 100
					end,
					pattern = "%d",
					order = 8
				},
]]
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
				showIcon = {
					name = L["Show Icon"],
					desc = L["Show icon frame"],
					type = "toggle",
					get = function()
						local showIcon = self.db.profile.auras[k].showIcon
						return showIcon == nil or showIcon == true
					end,
					set = function(info, v)
						self.db.profile.auras[k].showIcon = v
					end,
					order=12
				},
				layer = {
					name = L["Layer"],
					desc = L["This alarm's layer"],
					type = 'input',
					get = function() 
						return tostring(self.db.profile.auras[k].layer or 1)
					end,
					set = function(info, v)
						self.db.profile.auras[k].layer = tonumber(v)
					end,
					pattern = "%d",
					order = 15

				},
				enabled = {
					name = L["Enabled"],
					desc = L["Whether this alarm is enabled"],
					type = "toggle",
					get = function()
						return self.db.profile.auras[k].enabled == nil or self.db.profile.auras[k].enabled
					end,
					set = function(info, v)
						self.db.profile.auras[k].enabled = v
						clearCurrentAlarms()
					end,
					order = 16
				},
				remove = {
					name = L["Remove"],
					type = 'execute',
					desc = L["Remove aura"],
					func = function() 
						table.remove(self.db.profile.auras, k) 
						table.remove(self.db.profile.sets, k)
						self:BuildAurasOpts() 
						self:Print(L["Aura removed."]) 
						clearCurrentAlarms()
						refreshIcons()
					end,
					order=100
				}				
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
					self.db.profile.auras[#self.db.profile.auras+1] = {name=v, color={r=255,g=0,b=0,a=0.4 * 255}, soundFile="None", mode=1, fadeTime=.1, active=true} 
					self.db.profile.sets[self.db.profile.currentSet] = {name = v, alarms = {} }
					self:BuildAurasOpts() 
					self:Print(L["%s added."]:format(v)) 
					clearCurrentAlarms()
					refreshIcons()
				end,
				get = function() end,
				order=1
			},
		},
		order=1
	}

	if self.capturedAuras and count(self.capturedAuras) > 0 then
		self.opts.args.auras.args.add.args.captured_header = {
			type = "header",
			name = L["Captured Auras - Click to add"],
			order=2
		}
	end

	local low, hi = 3, 3
	
	for i, v in pairs(self.capturedAuras or {})  do
		if self.captured == "DEBUFF" then
			low = low + 1
		else
			hi = hi + 1
		end
	end

	hi = low + hi

	for k,v in pairs(self.capturedAuras or {}) do
		local text = k
		if v == "DEBUFF" then text = text .. L[" (D)"] end
		self.opts.args.auras.args.add.args[k] = {
			name = text,
			type = 'execute',
			func = function()
				self.db.profile.auras[#self.db.profile.auras+1] = {name=k, color={r=255,g=0,b=0,a=0.4 * 255}, soundFile="None", mode=1, type=v == "DEBUFF" and 1 or 2, flashTime=.1, active=true} 
				self.capturedAuras[k] = nil
				self:BuildAurasOpts()
				self:Print(L["%s added."]:format(k))
				clearCurrentAlarms()
				refreshIcons()
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
			settings = {
				name = L["Settings"],
				type = "group",
				desc = L["Configure AuraAlarm"],
				order = 2,
				args = {
					x = {
						name = "X",
						desc = L["Frame x position"],
						type = "range",
						get = function()
							return self.db.profile.x
						end,
						set = function(info, v)
							self.db.profile.x = v
							self.AAIconFrame:ClearAllPoints()
							self.AAIconFrame:SetPoint("CENTER", self.db.profile.x, self.db.profile.y)
							self.AAIconFrame:SetAlpha(1)
							self.AAIconFrame:SetScript("OnUpdate", hideIcon)
							self.AAIconFrame.timer = 0
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
							return self.db.profile.y
						end,
						set = function(info, v)
							self.db.profile.y = v
							self.AAIconFrame:ClearAllPoints()
							self.AAIconFrame:SetPoint("CENTER", self.db.profile.x, self.db.profile.y)
							self.AAIconFrame:SetAlpha(1)
							self.AAIconFrame:SetScript("OnUpdate", hideIcon)
							self.AAIconFrame.timer = 0
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
							return self.db.profile.mode or 1
						end,
						set  = function(info, v)
							self.db.profile.mode = v
							self:ChangeMode(v)
						end,
						order = 4
					},
					determined_rate = {
						name = L["Determined Mode Rate (in ms)"],
						type = "input",
						get = function()
							return tostring((self.db.profile.determined_rate or .4) * 100)
						end,
						set = function(info, v) 
							self.db.profile.determined_rate = tonumber(v) / 100
						end,
						pattern = "%d",
						order = 5
					},
					alpha = {
						name = L["Color key"],
						desc = L["Usually a black color with half opacity."],
						type = 'color',
						get = function()
							local c = self.db.profile.alpha
							return c.r / 255, c.g / 255, c.b / 255, c.a / 255
						end,
						set = function(info, r, g, b, a)
							local c = self.db.profile.alpha
							c.r, c.g, c.b, c.a = r * 255, g * 255, b * 255, a * 255
							for k, v in pairs(self.AAWatchFrame.currentAlarms) do
								v.active = false
							end
						end,
						hasAlpha = true,
						order = 6
					},
					fadeTime = {
						name = L["Fade Time"],
						desc = L["Duration of fade 'in' and 'out' effects."],
						type = "input",
						get = function()
							return tostring((self.db.profile.fadeTime or .3) * 100)
						end,
						set = function(info, v)
							self.db.profile.fadeTime = tonumber(v) / 100
						end,
						pattern = "%d",
						order = 7
					},
					blinkRate = {
						name = L["Blink Rate"],
						type = "input",
						get = function() 
							return tostring((self.db.profile.blinkRate or .3) * 100)
						end,
						set = function(info, v)
							self.db.profile.blinkRate = tonumber(v) / 100
						end,
						pattern = "%d",
						order = 8
					},
					garbageCollect = {
						name = L["Garbage Collect"],
						desc = L["Whether to collect garbage."],
						type = 'toggle',
						get = function()
							return self.db.profile.garbageCollect
						end,
						set = function(info, v)
							self.db.profile.garbageCollect = v
						end,
						order = 8
					},
					gcRate = {
						name = L["Garbage Collection Rate"],
						desc = L["Rate at which garbage collection will be done (in ms)"],
						type = 'input',
						get = function()
							return tostring((self.db.profile.gcRate or 10) * 100)
						end,
						set = function(info, v)
							self.db.profile.gcRate = tonumber(v / 100)
						end,
						pattern = "%d",
						order = 9
					},
					layers = {
						name = L["Layers"],
						desc = L["How many screen layers"],
						type = "input",
						get = function()
							return tostring(self.db.profile.layers or 2)
						end,
						set = function(info, v)
							self.db.profile.layers = tonumber(v)
						end,
						pattern = "%d",
						order = 10
					},
					currentSet = {
						name = L["Alarm Set"],
						desc = L["Which alarm set to use"],
						type = 'select',
						get = function()
							return self.db.profile.currentSet or 1
						end,
						set = function(info, v)
							self.db.profile.currentSet = v
							if not self.db.profile.sets[v] then
								self.db.profile.sets[v] = new()
								
							end
							for i, v in pairs(self.db.profile.auras) do
								local val = self.db.profile.sets[self.db.profile.currentSet][i]
								v.enabled = val == nil or val
							end
							clearCurrentAlarms()
							refreshIcons()
						end,
						values = alarmSets,
						order = 11
					},
					createSet = {
						name = L["Create a Set"],
						type = 'input',
						get = function()
						end,
						set = function(info, v)
							self.db.profile.sets[#self.db.profile.sets + 1] = new()
							local set = self.db.profile.sets[#self.db.profile.sets]
							set.name = v
							set.alarms = new()
							for i, v in ipairs(self.db.profile.auras) do
								set.alarms[#set.alarms + 1] = v.enabled == nil or v.enabled
							end
							
							alarmSets[#alarmSets + 1] = set.name
		
							self.db.profile.currentSet = #alarmSets
							clearCurrentAlarms()
							refreshIcons()
						end,
						order = 12
					},
					saveSet = {
						name = L["Save Set"],
						type  = "execute",
						func = function()
							local size = #self.db.profile.sets[self.db.profile.currentSet]
							del(self.db.profile.sets[self.db.profile.currentSet])
							self.db.profile.sets[self.db.profile.currentSet] = new()
							for i, v in ipairs(self.db.profile.auras) do
								self.db.profile.sets[self.db.profile.currentSet][i] = v.enabled
							end
							clearCurrentAlarms()
							refreshIcons()
						end,
						order = 13
					},
					deleteSet = {
						name = L["Delete Set"],
						type = 'execute',
						func = function()
							if self.db.profile.currentSet == 1 then
								return
							end
		
							local set = self.db.profile.sets[self.db.profile.currentSet]
							del(set.alarms or {})
							set.alarms = nil
							del(set)
							self:Print(#self.db.profile.sets)
							table.remove(self.db.profile.sets, self.db.profile.currentSet)
							table.remove(alarmSets, self.db.profile.currentSet)
							self:Print(#self.db.profile.sets)
							self.db.profile.currentSet = 1
							clearCurrentAlarms()
							refreshIcons()
							applySet()
						end,
						order = 14
					},
					reset = {
						name = L["Reset AuraAlarm"],
						desc = L["Click this in case the icon or background doesn't fade. May fix other issues as well."],
						type = 'execute',
						func = function()
							clearCurrentAlarms()
							refreshIcons()
							applySet()
						end,
						order = 100
					}
				}
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
			sets = {{}},
			currentSet = 1,
			x = 0,
			y = 0,
			alpha = {r = 0, g = 0, b = 0, a = 0.4 * 255}
		}
	})

	for i, v in ipairs(self.db.profile.sets) do
		alarmSets[i + 1] = v.name
	end

	applySet()
	
	self.capturedAuras = {}
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

	refreshIcons()

	local mode = supportModes[self.db.profile.mode or 1]

	if self.db.profile.mode ~= NORML_MODE  then -- Determined
		self.AAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
	end
	
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
	
local newUnit, delUnit

do
	local pool = setmetatable({}, {__mode='k'})
	newUnit = function()
		local unit = next(pool)
		if unit then 
			pool[unit] = nil
		else
			unit = {DEBUFF={}, BUFF={}}
		end
		return unit
	end
	delUnit = function(unit)
		if type(unit) ~= 'table' then error("Expected a table") end
		for _, type in pairs(typeNames) do
			for k, aura in pairs(unit[type] or {}) do
				del(aura)
				unit[type][k] = nil
			end
		end
		pool[unit] = true
	end
end

-- Determined mode
function AuraAlarm:WatchForAura(elapsed)
	self.timer = (self.timer or 0) + elapsed
	self.gcTimer = (self.gcTimer or 0) + elapsed
	local showIcon
	local name, icon, count, expirationTime, id, _

	if #self.obj.db.profile.auras == 0 then
		return
	end


	if not self.currentAlarms then 
		self.count = 0
		self.currentAlarms = new()
		for i, v in ipairs(self.obj.db.profile.auras) do
			if v.enabled == nil or v.enabled then
				self.currentAlarms[v] = new()
				local alarm = self.currentAlarms[v]
				alarm.name = v.name
				alarm.type = v.type or 1
				alarm.unit = v.unit or "player"
				alarm.mode = v.mode or 1
				alarm.showIcon = v.showIcon
				alarm.active = false
				alarm.table = v
				alarm.i = self.count + 1
				self.count = self.count + 1
			end
		end
	end

	if self.count == 0 then
		return
	end

	if self.timer < ((self.obj.db.profile.determined_rate or .4) / self.count) then
		self.elapsed = (self.elapsed or 0) + elapsed
		return
	end

	elapsed = (self.elapsed or 0) + elapsed

	self.elapsed = 0

	self.timer = 0

	if self.obj.db.profile.garbageCollect and self.gcTimer > (self.obj.db.profile.gcRate or 100) then
		if self.obj.db.profile.garbageCollect and not InCombatLockdown() then
			collectgarbage()
		end
		self.gcTimer = 0
	end

	if self.current then
		self.current = findByIndex(self.currentAlarms, self.currentAlarms[self.current].i + 1)
	end

	if not self.current then
		self.current = findByIndex(self.currentAlarms, 1) 
		if not self.current then
			return
		end
	end

	local alarm = self.currentAlarms[self.current]

	alarm.timer = (alarm.timer or 0) + elapsed
	alarm.fallTimer = (alarm.fallTimer or 0) + elapsed
	alarm.blinkTimer = (alarm.blinkTimer or 0) + elapsed
	alarm.soundTimer = (alarm.soundTimer or 0) + elapsed

	local units = {}

	for i, v in pairs(self.obj.db.profile.auras) do
		units[#units + 1] = v.unit or "player"
	end

	if not units[1] then
		units[1] = "player"
	end

	local auras = {}
	if not auras then
		auras = {}
	else
		for k, aura in pairs(auras) do
			delUnit(aura)
			auras[k] = nil
		end
	end

	for _, unit in ipairs(units) do
		
		if not auras[unit] then
			auras[unit] = newUnit() --{DEBUFF={}, BUFF={}}
		end

		del(auras[unit]['DEBUFF'])
		del(auras[unit]['BUFF'])
		auras[unit]['DEBUFF'] = new()
		auras[unit]['BUFF'] = new()

		for i = 1, 40 do
			name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitDebuff(unit, i)
			if name then 
				if not auras[unit]['DEBUFF'][name] then 
					auras[unit]['DEBUFF'][name] = new() 
				end
				auras[unit]['DEBUFF'][i] = auras[unit]['DEBUFF'][name]
				auras[unit]['DEBUFF'][name].name = name
				auras[unit]['DEBUFF'][name].icon = icon
				auras[unit]['DEBUFF'][name].count = count
				auras[unit]['DEBUFF'][name].expirationTime = expirationTime
				auras[unit]['DEBUFF'][name].id = id
				auras[unit]['DEBUFF'][name].id=id
				auras[unit]['DEBUFF'][name].unit = unit
				auras[unit]['DEBUFF'][name].i = i

			end
			name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitBuff(unit, i)
			if name then 
				if not auras[unit]['BUFF'][name] then
					auras[unit]['BUFF'][name] = new() 
				end
				auras[unit]['BUFF'][i] = auras[unit]['BUFF'][name]
				auras[unit]['BUFF'][name].name = name
				auras[unit]['BUFF'][name].icon = icon
				auras[unit]['BUFF'][name].count = count
				auras[unit]['BUFF'][name].expirationTime = expirationTime
				auras[unit]['BUFF'][name].id = id
				auras[unit]['BUFF'][name].id=id
				auras[unit]['BUFF'][name].unit = unit
				auras[unit]['BUFF'][name].i = i
			end
		end

	end

	for i, type in pairs(typeNames) do
		for i = 1, 40 do
			name = auras["player"][type][i] and auras["player"][type][i].name
			if name and not self.obj.capturedAuras[name] then
				local test = false
				for i = 1, #self.obj.db.profile.auras do
					if self.obj.db.profile.auras[i].name == name then
						test = true
					end
				end
				if not test then
					self.obj.capturedAuras[name] = type
					self.obj.AARebuildFrame:SetScript("OnUpdate", self.obj.ProcessCaptures)
				end
			end
		end
	end

	if not self.background then self.background = LibFlash:New(self.obj.AAFrame) end
	if not self.icon then self.icon = LibFlash:New(self.obj.AAIconFrame) end

	self.fadeTime = self.fadeTime or .3

	if alarm.timer > (self.obj.db.profile.determined_rate or .4) then
		local i = alarm.i
		local v = self.current

		local aura
		local at = auras[v.unit or "player"]

		if at and at[typeNames[v.type or 1] ] then
			aura = at[typeNames[v.type or 1] ][v.name]
		end
		
		name, icon, count, expirationTime, id = nil, nil, nil, nil, nil

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

		alarm.isStacked = isStacked

		local stackTest = (isStacked and aura and aura.count == count) or not isStacked

		local firstTime = false
		if name and name == v.name and not alarm.active and not alarm.justResting and (isStacked and v.count == count or not isStacked) then
			alarm.fallOff = expirationTime - GetTime()
			if alarm.fallOff < 0 then
				alarm.fallOff = 0xdeadbeef
			end
			alarm.fallTimer = 0

			if v.mode == 1 then -- Normal
				local timer = 0
				local goToSleep = function()
					alarm.justResting = true
					for k, currentAlarm in pairs(self.currentAlarms) do
						if currentAlarm ~= alarm then
							currentAlarm.active = false
						end
					end
				end

				self.background:Flash(self.fadeTime, self.fadeTime, 1 + self.fadeTime * 2, false, 0, 1)
				if alarm.showIcon == nil or alarm.showIcon then
					self.icon:Flash(self.fadeTime, self.fadeTime, 3 + self.fadeTime * 2, false, 0, 3, false, 0, goToSleep)
				end

			elseif v.mode == 2 then -- Persist
				self.background:FadeIn(self.fadeTime, 0, 1)
				if v.showIcon == nil or v.showIcon then
					self.icon:FadeIn(self.fadeTime, 0, 1)
				end
				alarm.wasPersist = true
			elseif v.mode == 3 then -- Blink
				self.background:Flash(self.fadeTime, self.fadeTime, alarm.fallOff + self.fadeTime * 2, false, 0, alarm.fallOff, true, self.obj.db.profile.blinkRate)
				if v.showIcon == nil or v.showIcon then
					self.icon:Flash(self.fadeTime, self.fadeTime, alarm.fallOff + self.fadeTime * 2, false, alarm.fallOff, true, self.obj.db.profile.blinkRate)
				end
			end
			alarm.showIcon = v.showIcon == nil or v.showIcon
			alarm.active = true
			firstTime = true
			alarm.blinkTimer = 0
			alarm.count = count or 0
		end
		if name and name == v.name  then
			if (isStacked and count ~= alarm.lastCount) or (v.soundPersist and alarm.soundTimer > (v.soundRate or 2) and v.mode == PERSIST_MODE) or firstTime then
				PlaySoundFile(LSM:Fetch("sound", soundFiles[getLSMIndexByName("sound", v.soundFile) or getLSMIndexByName("sound", "None")]))
				if isStacked and count ~= alarm.lastCount then
					alarm.lastCount = count
				end
				alarm.soundTimer = 0
			end

			self.obj.AAIconFrame.icons[v]:SetTexture(icon)

			self.obj.AAIconFrame.texts[v]:SetText(stackText)

			alarm.fallOff = expirationTime - GetTime()
			if alarm.fallOff < 0 then
				alarm.fallOff = 0xdeadbeef
			end

			alarm.fallTimer = 0
		end

--[[		if name == (v.name or "") and alarm.blinkTimer > alarm.blinkRate and v.mode == tableFind(alarmModes, L["Blink"]) then
			self.background:FadeOut(v.fadeTime, 1, 0)
			if v.showIcon == nil or v.showIcon then
				self.icon:FadeOut(v.fadeTime, 1, 0)
			end
			if alarm.fallTimer > alarm.fallOff then
				alarm.fallTimer = 0
			end	
			alarm.firstSound = false
			alarm.active = false
			alarm.blinkTimer = 0
		end
]]			
		local pos, width = 0, 0
		for k, v in pairs(self.currentAlarms) do
			self.obj.AAIconFrame.icons[k]:ClearAllPoints()
			self.obj.AAIconFrame.texts[k]:ClearAllPoints()
			if v.showIcon and v.active and not v.justResting then

				local x = pos * 44
				
				self.obj.AAIconFrame.icons[k]:SetPoint("LEFT", x + 10, 0) 
				self.obj.AAIconFrame.texts[k]:SetPoint("LEFT", x + 34, 0)
				pos = pos + 1
				if v.count == 0 then
					width = width + 44
				else
					width = width + 54
				end

			elseif v.showIcon and not v.active or v.justResting then
				self.obj.AAIconFrame.icons[k]:SetTexture(nil)
				self.obj.AAIconFrame.texts[k]:SetText("")
			end
		end
		self.obj.AAIconFrame:SetWidth(width)

		local c = self.obj.db.profile.alpha
		local r, g, b, a = c.r, c.g, c.b, c.a
		local o = self.obj.db.profile.layers or 2

		for l = 1, self.obj.db.profile.layers or 2 do
			
		end

		local o = self.obj.db.profile.layers or 2
		for l = 1, self.obj.db.profile.layers or 2 do
			for k, v in pairs(self.currentAlarms) do
				local p = k.color	
				if p.a == 255 and v.active and not v.justResting then
					o = l
				end
			end
		end

		for l = o, 1, -1 do
			for k, v in pairs(self.currentAlarms) do
				if v.active and not v.justResting then
					if (k.layer or 2) == l then
						local p = k.color
						if p.a == 255 then
							r = p.r
							g = p.g
							b = p.b
						elseif p.a > 0 then
							r = (p.r * p.a + round(r) * (255 - p.a)) / 255
							g = (p.g * p.a + round(g) * (255 - p.a)) / 255
							b = (p.b * p.a + round(b) * (255 - p.a)) / 255
						end
					end
				end
			end
		end

		self.obj.AAFrame:SetBackdropColor(round(r) / 255, round(g) / 255, round(b) / 255, round(a) / 255)

		alarm.timer = 0
	end

	local activeAura = false
	local aura = auras[self.current.unit or "player"]

	if aura then
		aura = aura[typeNames[self.current.type or 1]][alarm.name]
	end

	if aura then
		activeAura = true
	end

	local restart = function()
		refreshIcons()
		clearCurrentAlarms()
	end

	if alarm.active and (alarm.fallTimer or 0xbeef) > (alarm.fallOff or 0xdead) or (not activeAura  and alarm.active) then
		if alarm.wasPersist then
			self.background:FadeOut(self.current.fadeTime, 1, 0, restart)
			if alarm.showIcon == nil or alarm.showIcon then 
				self.icon:FadeOut(self.current.fadeTime, 1, 0)
			end
		else
			refreshIcons()
			clearCurrentAlarms()
		end
	end

	local totalActive = 0
	if self.currentAlarms then for k, v in pairs(self.currentAlarms) do
		if v.active then
			totalActive = totalActive + 1
		end
	end end

	if totalActive == 0 then
		self.obj.AAIconFrame:SetAlpha(0)
		self.obj.AAFrame:SetAlpha(0)
	end 

	for unit in pairs(units) do
		if auras[unit] and auras[unit]['DEBUFF'] then
			del(auras[unit]['DEBUFF'])
			delUnit(auras[unit])
		end
		if auras[unit] and auras[unit]['BUFF'] then
			del(auras[unit]['BUFF'])
			delUnit(auras[unit])
		end
	end
end

-- Normal mode
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

			self.AAIconFrame.texts[v]:SetText(stackText)

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
					self.AAFrame:SetBackdropColor(v.color.r / 255, v.color.g / 255, v.color.b / 255, v.color.a / 255)
					UIFrameFadeIn(self.AAFrame, .3, 0, 1)
					if v.showIcon then
						UIFrameFadeIn(self.AAIconFrame, .3, 0, 1)
					end
					self.AAFrame:SetScript("OnUpdate", cleanup) -- all alarms have a hard timeout of 5 minutes before hiding the background frame
					self.AAIconFrame:SetScript("OnUpdate", cleanup) -- this is because sometimes the combat log stops working
				elseif stackTest then
					UIFrameFadeOut(self.AAFrame, .3, 1, 0)
					if v.showIcon then
						UIFrameFadeOut(self.AAIconFrame, .3, 1, 0)
					end
				end
			end
			if eventtype == "SPELL_AURA_APPLIED" then 
				if v.playSound then
					PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile and getLSMIndexByName("sound", v.soundFile or "None") or 1]))
				end
				self.AAIconFrame.icons[v]:SetTexture(select(3, UnitAura(aura.unit or "player", aura_name, "", "HARMFUL")))
			end
			return
		end
	end
	
	if not self.capturedAuras[aura_name] and dst_name == UnitName("player") then 
		self.capturedAuras[aura_name] = aura_type 
		self.AARebuildFrame:SetScript("OnUpdate", self.ProcessCaptures)
	end
    
end

function AuraAlarm:ChangeMode(v)
	if supportModes[v] == L["Normal"] then
		self.AAWatchFrame:SetScript("OnUpdate", nil)
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		if self.AAWatchFrame.currentAlarms then
			del(self.AAWatchFrame.currentAlarms)
			self.AAWAtchFrame.currentAlarms = nil
			self.AAWatchFrame.current = nil
		end
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
			self.db.profile.auras[#self.db.profile.auras+1] = {name=buffName, color={r=255,g=0,b=0,a=0.4 * 255}, duration=1, soundFile="None", flashBackground=true, active=true} 
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

