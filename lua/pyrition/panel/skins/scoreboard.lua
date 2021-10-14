local default_skin = derma.GetNamedSkin("Default")

--if we need more than 2 skins I think it might be best to make a loader with SKIN as our method table
local SKIN = {
	--meta
	Author = "Cryotheum",
	DermaVersion = 1,
	PrintName = "Pyrition Scoreboard Skin",
}

--post
derma.DefineSkin("PyritionScoreboard", "Skin for Pyrition's scoreboard.", SKIN)