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

AuraAlarm.DAFrame = CreateFrame("Frame", "DAFrame", UIParent)
AuraAlarm.DAIconFrame = CreateFrame("Frame", "DAIconFrame", UIParent)
AuraAlarm.DAWatchFrame = CreateFrame("Frame", "DAWatchFrame", UIParent)

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

local alarmModes = {L["Flash Background"], L["Persist"], L["None"]}

local auraTypes = {L["Harmful"], L["Helpful"]}

local supportModes = {L["Normal"], L["Determined"]}

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
				AuraAlarm.DAIconFrame:ClearAllPoints()
				AuraAlarm.DAIconFrame:SetPoint("CENTER", AuraAlarm.db.profile.x, AuraAlarm.db.profile.y)
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
				AuraAlarm.DAIconFrame:ClearAllPoints()
				AuraAlarm.DAIconFrame:SetPoint("CENTER", AuraAlarm.db.profile.x, AuraAlarm.db.profile.y)
			end,
			min = -math.floor(GetScreenHeight()/2 + 0.5),
			max = math.floor(GetScreenHeight()/2 + 0.5),
			step = 1,
			order = 3
		},
		mode = {
			name = L["Support Mode"],
			desc = L["Select between determined and normal mode."],
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
		}
	}
}

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
						return self.db.profile.auras[k].soundFile
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
						return self.db.profile.auras[k].mode
					end,
					set = function(info, v)
						self.db.profile.auras[k].mode = v
					end,
					values = alarmModes,
					order=5
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
					order=6 
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
					order=7
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
					order=8
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
    opts.args.auras.args.add.args.captured_header = {
	type = "header",
	name = L["Captured Auras - Click to add"],
	order=2
    }
	for k,v in pairs(self.captured_auras) do
		opts.args.auras.args.add.args[k] = {
			name = k,
			type = 'execute',
			desc = "Add " .. k,
			func = function()
				self.db.profile.auras[#self.db.profile.auras+1] = {name=k, color={1,0,0,.4}, soundFile=getLSMIndexByName("sound", "None"), mode=1} 
				self.captured_auras[k] = nil
				self:BuildAurasOpts()
				self:Print(L["%s added."]:format(k))
			end
		}
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
	
	self.DAFrame:SetFrameStrata("BACKGROUND")
	self.DAFrame:SetFrameLevel(0)
	self.DAFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
		tile = true, 
		tileSize = 16,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	})
	self.DAFrame:ClearAllPoints()
	self.DAFrame:SetAllPoints(UIParent)
	self.DAFrame.obj = self
	
	if not self.db.profile.mouse then self.db.profile.mouse = false end
	if not self.db.profile.x then self.db.profile.x = 0 end
	if not self.db.profile.y then self.db.profile.y = 0 end

	self.DAIconFrame:SetFrameStrata("BACKGROUND")
	self.DAIconFrame:SetHeight(44)
	self.DAIconFrame:SetWidth(80)
	self.DAIconFrame:EnableMouse(self.db.profile.locked or false)
	self.DAIconFrame:SetMovable(true)
	self.DAIconFrame:SetPoint("CENTER", UIParent, self.db.profile.x, self.db.profile.y);
	self.DAIconFrame:SetFrameStrata("DIALOG")
	self.DAIconFrame:SetFrameLevel(0)
	self.DAIconFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 16,
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=16, 
		insets = { left = 4, right = 4, top = 4, bottom = 4}})
	self.DAIconFrame:SetBackdropColor(0, 1, 0, 1)
	self.DAIconFrame:SetBackdropBorderColor(0, 0, 0, 1)

	self.DAIconFrame.Text = self.DAIconFrame:CreateFontString("DAtext", "LEFT")
	self.DAIconFrame.Text:SetPoint("LEFT", 34, 0)
	self.DAIconFrame.Text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, MONOCHROME")
	self.DAIconFrame.Text:SetFontObject(GameFontNormal)

	self.DAIconFrame.Icon = self.DAIconFrame:CreateTexture(nil,"DIALOG")
	self.DAIconFrame.Icon:SetPoint("LEFT", 10, 0)
	self.DAIconFrame.Icon:SetTexture(select(3, GetSpellInfo("Slam")))
	self.DAIconFrame.Icon:SetHeight(24)
	self.DAIconFrame.Icon:SetWidth(24)

	self.DAWatchFrame.obj = self
	if supportModes[self.db.profile.mode or 1] == L["Determined"] then 
		self.DAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
	end

	self.DAWatchFrame.active = false
	
	self:ChangeMode(self.db.profile.mode or 1)
end

function AuraAlarm:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self.DAFrame:SetBackdropColor(0, 0, 0, 0)
	self.DAFrame:Show()
	self.DAIconFrame:SetAlpha(0)
	self.DAIconFrame:Show()
end

function AuraAlarm:OnDisable()
	if self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") then 
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") 
	end
	self.DAFrame:Hide()
	self.DAIconFrame:Hide()
end

function AuraAlarm:OnTooltipUpdate()
	GameTooltip:AddLine("AuraAlarm")
	GameTooltip:AddLine("|cffffff00Right-click|r to open menu.")
end

function AuraAlarm:WatchForAura(elapsed)
	self.timer = (self.timer or 0) + elapsed
	self.dropTimer = (self.dropTimer or 0) + elapsed

	if this.timer > .5 and not self.active then
		for i = 1, 40 do
			for k, v in pairs(self.obj.db.profile.auras) do
				local aura = v
				local name, icon, count, expirationTime, id, _
				if auraTypes[v.type or 1] == L["Harmful"] then
					name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitDebuff(v.unit or "player", i)
				else
					name, _, icon, count, _, _, expirationTime, _, _, _, id = UnitBuff(v.unit or "player", i)
				end

				self.obj:Print(name)

				local isStacked = true
				local stackText = ""

				if count == 0 or count == nil then
					isStacked = false
				else
					stackText = tostring(count)
				end

				local stackTest = (isStacked and aura.count == count) or isStacked == false

				self.obj.DAIconFrame.Text:SetText(stackText)

				if isStacked and name then
					self.obj.DAIconFrame:SetWidth(80)
				elseif name then
					self.obj.DAIconFrame:SetWidth(44)
				end

				if name == v.name then
					self.obj:Print(name)
				end

				if name and not self.active then
					if name == v.name then
						self.obj.DAFrame:SetBackdropColor(v.color[1], v.color[2], v.color[3], v.color[4])
						if alarmModes[v.mode] == L["Persist"] then 
							UIFrameFadeIn(self.obj.DAFrame, .3, 0, 1)
							UIFrameFadeIn(self.obj.DAIconFrame, .3, 0, 1)
							self.wasPersist = true
						else
							UIFrameFlash(self.obj.DAFrame, .3, .3, 1.6, false, 0, 1)
							UIFrameFlash(self.obj.DAIconFrame, .3, .3, 3.6, false, 0, 3)
						end
						self.active = true
					end
				end
				if name == v.name then
					PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile]))
					if auraTypes[aura.type] == L["Harmful"] then
						
						self.obj.DAIconFrame.Icon:SetTexture(icon)
					else
						self.obj.DAIconFrame.Icon:SetTexture(icon)
					end
					self.fallOff = expirationTime - GetTime()
					self.fallTimer = 0
					self.count = count
				end
                        end
		end
		this.timer = 0
	end
	if self.active and (self.Falltimer or 16) > (self.fallOff or 15) then
		self.active = false
		self.timer = 0
		if self.wasPersist then
			UIFrameFadeOut(self.DAFrame, .3, 1, 0)
			UIFrameFadeOut(self.DAIconFrame, .3, 1, 0)
			self.wasPersist = false
		end
		self.obj.DAFrame:SetAlpha(0)
		self.obj.DAIconFrame:SetAlpha(0)
	end

end

function AuraAlarm:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	local _, eventtype, _, _, _, _, dst_name, _, _, aura_name, _, aura_type = ...

	if supportModes[self.db.profile.mode or 1] == L["Determined"] then return end

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

			self.DAIconFrame.Text:SetText(stackText)

			if isStacked then
				self.DAIconFrame:SetWidth(80)
			else
				self.DAIconFrame:SetWidth(44)
			end

			if alarmModes[v.mode] == L["Flash Background"] and eventtype == "SPELL_AURA_APPLIED" and stackTest then
				self.DAFrame:SetBackdropColor(v.color[1], v.color[2], v.color[3], v.color[4])
				UIFrameFlash(self.DAFrame, .3, .3, 1.6, false, 0, 1) 
				UIFrameFlash(self.DAIconFrame, .3, .3, 3.6, false, 0, 3)
			elseif alarmModes[v.mode] == L["Persist"] then
				if eventtype == "SPELL_AURA_APPLIED" and stackTest then
					self.DAFrame:SetBackdropColor(v.color[1], v.color[2], v.color[3], v.color[4])
					UIFrameFadeIn(self.DAFrame, .3, 0, 1)
					UIFrameFadeIn(self.DAIconFrame, .3, 0, 1)
					self.DAFrame:SetScript("OnUpdate", cleanup) -- all alarms have a hard timeout of 5 minutes before hiding the background frame
					self.DAIconFrame:SetScript("OnUpdate", cleanup) -- this is because sometimes the combat log stops working
				elseif stackTest then
					UIFrameFadeOut(self.DAFrame, .3, 1, 0)
					UIFrameFadeOut(self.DAIconFrame, .3, 1, 0)
				end
			end
			if eventtype == "SPELL_AURA_APPLIED" then 
				PlaySoundFile(LSM:Fetch("sound", soundFiles[v.soundFile]))
				self.DAIconFrame.Icon:SetTexture(select(3, UnitAura(aura.unit or "player", aura_name, "", "HARMFUL")))
			end
			return
		end
	end
	
	if not self.captured_auras[aura_name] then 
		self.captured_auras[aura_name] = true 
		self:BuildAurasOpts()
	end
    
end

function AuraAlarm:ChangeMode(v)
	if supportModes[v] == L["Normal"] then
		self.DAWatchFrame:SetScript("OnUpdate", nil)
	else
		self.DAWatchFrame:SetScript("OnUpdate", self.WatchForAura)
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
