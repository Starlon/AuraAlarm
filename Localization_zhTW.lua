--[[
 AuraAlarm -- Buff and debuff alerter.
 
 Copyright (C) 2010 Scott Sibley <starlon@users.sourceforge.net>
 Layering design and associated algorithm borrowed from LCD4Linux.
 Copyright (C) 2004 The LCD4Linux Team <lcd4linux-devel@users.sourceforge.net>

 Authors: Scott Sibley

 $Id$

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as
 published by the Free Software Foundation; either version 3
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("AuraAlarm", "zhTW", false)
if not L then return end

L["Add and remove auras"] = "增加或移除Aura"
L["Duration"] = "持續時間"
L["Set the flash duration"] = "設置閃動的持續時間"
L["<Duration here>"] = "<持續時間>"
L["Color"] = "顏色"
L["Change the flash color"] = "修改閃動的顏色"
L["Aura Name"] = "Aura名字"
L["<Aura name here>"] = "<Aura 名字>"
L["Name for Aura"] = "Aura的名字"
L["Remove"] = "移除"
L["Remove aura"] = "移除Aura"
L["Add Aura"] = "增加Aura"
L["Add a aura"] = "增加壹個Aura"
L["You are afflicted by %s."] = "妳獲得了 %s 效果"
L["Warning Sound"] = "警報音效"
L["Sound to play"] = "要播放的音效"
L["Play Sound"] = "播放音效"
L["Toggle playing sounds"] = "開啟或關閉播放音效"
L["Mode"] = "模式"
L["Alarm mode"] = "警報模式"
L["Flash Background"] = "閃動背景"
L["Persist"] = "保持"
L["None"] = "無"
L["Aura removed."] = "Aura 已移除"
L["%s added."] = "%s 已增加"
L["%s added to AuraAlarm."] = "%s 已增加到 AuraAlarm"
L["<New aura here>"] = "<新的Aura>"
L["Captured Auras - Click to add"] = "已探測的Aura-點擊增加"
