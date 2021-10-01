--meta tables
local ENTITY = FindMetaTable("Entity")
local PLAYER = FindMetaTable("Player")

--locals
local entity_remove = PYRITION.Backup.entity_remove or ENTITY.Remove

--globals
PLAYER.RemoveX_Pyrition = entity_remove

--global functions
function PLAYER:Remove() self:Kick("Your player entity was removed.") end