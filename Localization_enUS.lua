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
local L = AceLocale:NewLocale("AuraAlarm", "enUS", true)
if not L then return end

L["Add and remove auras"] = true
L["Duration"] = true
L["Set the flash duration"] = true
L["<Duration here>"] = true
L["Color"] = true
L["Change the flash color"] = true
L["Aura Name"] = true
L["<Aura name here>"] = true
L["Name for Aura"] = true
L["Remove"] = true
L["Remove aura"] = true
L["Add Aura"] = true
L["Add an aura"] = true
L["You are afflicted by %s."] = true
L["Warning Sound"] = true
L["Sound to play"] = true
L["Play Sound"] = true
L["Toggle playing sounds"] = true
L["Mode"] = true
L["Alarm mode"] = true
L["Flash Once"] = true
L["Persist"] = true
L["None"] = true
L["Aura removed."] = true
L["%s added."] = true
L["%s added to AuraAlarm."] = true
L["<New aura here>"] = true
L["Captured Auras - Click to add"] = true
L["Enable Mouse"] = true
L["Unit"] = true
L["Stacks"] = true
L["Frame x position"] = true
L["Frame y position"] = true
L["Stacks: "] = true
L["Harmful"] = true
L["Helpful"] = true
L["Type"] = true
L["Normal"] = true
L["Light"] = true
L["Light mode has less features"] = true
L["Operation Mode"] = true
L["Show Icon"] = true
L["Show icon frame"] = true
L["Normal Mode Rate (in ms)"] = true
L[" (D)"] = true -- Some short tag meaning "Debuff"
L["Blink"] = true
L["Blink Rate"] = true
L["0 means do not consider stack count."] = true
L["Persisting Sound"] = true
L["Toggle repeating sound throughout aura. This only pertains to Persist Mode."] = true
L["Sound Rate"] = true
L["Rate at which Persisting Sound will fire. This is in milliseconds."] = true
L["Layers"] = true
L["Layer"] = true
L["This alarm's layer"] = true
L["How many screen layers"] = true
L["Color key"] = true
L["Usually a black color with half opacity."] = true
L["Fade Time"] = true
L["Duration of fade 'in' and 'out' effects."] = true
L["Reset AuraAlarm"] = true
L["Sets"] = true
L["Click this in case the icon or background doesn't fade. May fix other issues as well."] = true
L["Enabled"] = true
L["Whether this alarm is enabled"] = true
L["Default"] = true
L["Current Set"] = true
L[" is not a valid set."] = true
L["Set %s applied."] = true
L["Which alarm set to use"] = true
L["Save Set"] = true
L["Delete Set"] = true
L["Create a Set"] = true
L["Settings"] = true
L["Configure AuraAlarm"] = true
L["Coordinates"] = true
L["Frames"] = true
L["Troubleshooting"] = true
L["Enter a name for this set."] = true
L["Set saved."] = true
L["Target"] = true
L["Change to this set when I target <name>"] = true
L["Usage: /auraalarm getset Default"] = true
L["Aura ID"] = true
L["<Aura ID here>"] = true
L["ID for Aura"] = true
L["Profiles"] = true
L["Share"] = true
L["Share this alarm with a player"] = true
L["<Enter player name>"] = true
L["Alarm shared with %s."] = true
L["Received Alarms"] = true
L["Someone shared these alarms with you"] = true
L["Sender"] = true
L["This player sent this alarm to you"] = true
L["Add"] = true
L["Add this alarm"] = true
L["Received alarm added."] = true
L["Copy"] = true
L["Copy an alarm's settings"] = true
L["Alarm copied."] = true
L["Duration Precision"] = true
L["In Seconds"] = true
L["Single Decimal"] = true
L["Delayed Alarm"] = true
L["Toggle whether to delay flash. This only pertains to Flash Once mode."] = true
L["When to Fire"] = true
L["Fire alarm this many seconds from end of aura's duration"] = true