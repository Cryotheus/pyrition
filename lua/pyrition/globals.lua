PYRITION = {
	Backup = PYRITION and PYRITION.Backup or {},
	Commands = {},
	Groups = {},
	GroupsPrecedence = {},
	
	Player = {
		Storage = {}, --the keys should reflect the file's name without the extension
		StorageTailored = {},
		
		Time = {
			Sessions = {},
			SessionStarts = {},
			Total = {}
		}
	},
	
	Variables = {}
}

if SERVER then
	PYRITION.SyncHooks = {}
else
	--maybe make a sync for this?
	PYRITION.GFX = {
		BlipOutline = {},
		Blur = {},
		Outline = {},
		Halo = {}
	}
	
	PYRITION.Pages = {}
end

--realm constants
PYRITION_CLIENT = 1 --include on client, AddCSLua
PYRITION_SERVER = 2 --include on server
PYRITION_MEDIA = 4 --clients network when they run this command instead of executing it

--special realm constants
PYRITION_MEDIATED = bit.bor(PYRITION_SERVER, PYRITION_MEDIA)
PYRITION_SHARED = bit.bor(PYRITION_CLIENT, PYRITION_SERVER)

--useful constants
PYRITION_MAP_DIAGONAL = 113512 --113511.681725

--console variables types
PYRITION_VARIABLE_ANY = 0
PYRITION_VARIABLE_NUMBER = 1
PYRITION_VARIABLE_INTEGER = 2
PYRITION_VARIABLE_STRING = 3
PYRITION_VARIABLE_BOOL = 4

--console variable flags
PYRITION_VARIABLE_REPLICATED = 8 --doesn't actually do anything yet