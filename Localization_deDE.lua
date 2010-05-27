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
local L = AceLocale:NewLocale("AuraAlarm", "deDE", true)
if not L then return end

L["Add and remove auras"] = "Auras hinzufügen und entfernen"
L["Duration"] = "Dauer"
L["Set the flash duration"] = "Markierungsdauer einstellen"
L["<Duration here>"] = "<Dauer>"
L["Color"] = "Farbe"
L["Change the flash color"] = "Farbe des Aufblinkens ändern"
L["Aura Name"] = "Aura Name"
L["<Aura name here>"] = "<Aura name>"
L["Name for Aura"] = "Name des Aura"
L["Remove"] = "Entfernen"
L["Remove aura"] = "Entferne aura"
L["Add Aura"] = "Aura hinzufügen"
L["Add a aura"] = "Aura hinzufügen"
L["You are afflicted by %s."] = "Ihr seid von %s betroffen."
L["Warning Sound"] = "Warnsignal"
L["Sound to play"] = "Abzuspielender Sound"
L["Play Sound"] = "Sound Abspielen"
L["Toggle playing sounds"] = "Zeige abgespielte Sounds"
L["Flash Background"] = "Markiere Hintergrund"
L["Persist"] = "Persist"
L["None"] = "None"
L["Aura removed."] = "Aura removed."
L["%s added."] = "%s added."
L["%s added to AuraAlarm."] = "%s added to AuraAlarm."
L["<New aura here>"] = "<New aura here>"
L["Captured Auras - Click to add"] = "Captured Auras - Click to add"
