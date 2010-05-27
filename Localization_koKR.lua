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

 You should have received a copy of the GNU Lesser General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
]]

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("AuraAlarm", "koKR", true)
if not L then return end

L["Add and remove auras"] = "디버프를 추가하거나 제거합니다."
L["Duration"] = "지속시간"
L["Set the flash duration"] = "반짝임 지속시간을 설정합니다."
L["<Duration here>"] = "<여기 지속시간>"
L["Color"] = "색상"
L["Change the flash color"] = "플래시 색상을 변경합니다."
L["Aura Name"] = "디버프 이름"
L["<Aura name here>"] = "<여기 디버프 이름>"
L["Name for Aura"] = "디버프를 위한 이름"
L["Remove"] = "제거"
L["Remove aura"] = "디버프 제거"
L["Add Aura"] = "디버프 추가"
L["Add a aura"] = "디버프를 추가합니다."
L["You are afflicted by %s."] = "당신은 %s에 걸렸습니다."
L["Warning Sound"] = "소리 경고"
L["Sound to play"] = "경고할 소리"
L["Play Sound"] = "소리 재생"
L["Toggle playing sounds"] = "소리 재생 토글"
L["Mode"] = "방식"
L["Alarm mode"] = "경보 방식"
L["Flash Background"] = "배경 깜박임"
L["Persist"] = "지속"
L["None"] = "없음"
L["Aura removed."] = "디버프를 제거합니다."
L["%s added."] = "%s를 추가합니다."
L["%s added to AuraAlarm."] = "AuraAlarm에 %s를 추가합니다."
L["<New aura here>"] = "<여기 새로운 디버프>"
L["Captured Auras - Click to add"] = "Captured Auras - Click to add"
