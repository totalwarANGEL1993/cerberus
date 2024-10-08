Lib.Require("comfort/CreateNameForEntity");
Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("comfort/CopyTable");
Lib.Require("comfort/Localize");
Lib.Require("module/mp/Syncer");
Lib.Register("module/io/Interaction");

--- 
--- Internal interaction controller
--- 
--- Version 1.0.1
--- 

Interaction = Interaction or {}

-- -------------------------------------------------------------------------- --
-- API

--- Returns the script name of the last hero of the player that was 
--- involved in an NPC interaction.
--- @param _PlayerID integer ID of player
--- @return string Npc ID of last Hero
function Interaction.Hero(_PlayerID)
    return Interaction.Internal.LastInteractionHero[_PlayerID];
end

--- Returns the script name of the last NPC one of the players hero 
--- has interacted with.
--- @param _PlayerID integer ID of player
--- @return string Npc ID of last NPC
function Interaction.Npc(_PlayerID)
    return Interaction.Internal.LastInteractionNpc[_PlayerID];
end

-- Checks, if the npc is active.
--- @param _ScriptName string Scriptname of npc
--- @return boolean Active NPC is active
function Interaction.IsActive(_ScriptName)
    return Interaction.Internal:IsActive(_ScriptName);
end

-- Checks, if the entity is an NPC.
--- @param _ScriptName string Scriptname of npc
--- @return boolean IsNPC Entity is NPC
function Interaction.IsNpc(_ScriptName)
    return Interaction.Internal:IsNpc(_ScriptName);
end

-- Creates a new NPC.
-- DO NOT USE MANUALLY!
function Interaction.CreateNpc(_Data)
    Interaction.Internal:CreateNpc(_Data);
end

-- Activates an existing inactive NPC.
-- DO NOT USE MANUALLY!
function Interaction.Activate(_ScriptName)
    Interaction.Internal:Activate(_ScriptName);
end

-- Deactivates an existing active NPC.
-- DO NOT USE MANUALLY!
function Interaction.Deactivate(_ScriptName)
    Interaction.Internal:Deactivate(_ScriptName);
end

-- Installs the core NPC stuff.
-- DO NOT USE MANUALLY!
function Interaction.Install()
    Interaction.Internal:Install();
end

-- -------------------------------------------------------------------------- --
-- Callback

--- Called when a hero is talking to a normal npc.
--- @param _PlayerID integer ID of player
--- @param _HeroID integer   ID of hero
--- @param _NpcID integer    ID of npc
--- @param _Data table  Data object of npc
function GameCallback_Logic_InteractWithCharacter(_PlayerID, _HeroID, _NpcID, _Data)
end

--- Called when a hero is talking to a merchant.
--- @param _PlayerID integer ID of player
--- @param _HeroID integer   ID of hero
--- @param _NpcID integer    ID of npc
--- @param _Data table  Data object of npc
function GameCallback_Logic_InteractWithMerchant(_PlayerID, _HeroID, _NpcID, _Data)
end

--- Called on each second for each npc.
--- @param _Name string Script name of npc
--- @param _Data table  Data object of npc
function GameCallback_Logic_OnTickNpcController(_Name, _Data)
end

--- Called when a npc is activated.
--- @param _Name string Script name of npc
--- @param _Data table  Data object of npc
function GameCallback_Logic_OnNpcActivated(_Name, _Data)
end

--- Called when a npc is deactivated.
--- @param _Name string Script name of npc
--- @param _Data table  Data object of npc
function GameCallback_Logic_OnNpcDeactivated(_Name, _Data)
end

--- Called when a npc is updated.
--- @param _Name string Script name of npc
--- @param _Data table  Data object of npc
function GameCallback_Logic_OnNpcUpdated(_Name, _Data)
end

-- -------------------------------------------------------------------------- --
-- Internal

Interaction.Internal = Interaction.Internal or {
    LastInteractionHero = {},
    LastInteractionNpc = {},

    Data = {
        IO = {}
    },
};

function Interaction.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        for i= 1, GetMaxAmountOfPlayer() do
            self.LastInteractionHero[i] = nil;
            self.LastInteractionNpc[i] = nil;
        end
        self:OverrideNpcInteraction();
    end
end

function Interaction.Internal:CreateNpc(_Data)
    self:DeleteNpc(_Data.ScriptName);

    local Data = {
        ScriptName = _Data.ScriptName,
        Callback   = _Data.Callback,
        Active     = false,
        Hero       = _Data.Hero,
        HeroInfo   = _Data.WrongHeroMsg,
        Player     = _Data.Player,
        PlayerInfo = _Data.WrongPlayerMsg,
    }
    Data.Controller = Trigger.RequestTrigger(
        Events.LOGIC_EVENT_EVERY_SECOND,
        "",
        "Interaction_Internal_NpcController",
        1,
        {},
        {_Data.ScriptName}
    );

    self.Data.IO[_Data.ScriptName] = Data;
end

function Interaction.Internal:DeleteNpc(_ScriptName)
    -- Delete old instance
    if self.Data.IO[_ScriptName] then
        if JobIsRunning(self.Data.IO[_ScriptName].JobID) then
            EndJob(self.Data.IO[_ScriptName].JobID);
        end
        if self.Data.IO[_ScriptName].Active then
            Interaction.Internal:Deactivate(_ScriptName);
        end
        self.Data.IO[_ScriptName] = nil;
    end
end

function Interaction.Internal:Activate(_ScriptName)
    local ID = GetID(_ScriptName);
    if self.Data.IO[_ScriptName] and Logic.IsSettler(ID) == 1 then
        Logic.SetOnScreenInformation(ID, 1);
        self.Data.IO[_ScriptName].Active = true;
        GameCallback_Logic_OnNpcActivated(_ScriptName, self.Data.IO[_ScriptName]);
    end
end

function Interaction.Internal:Deactivate(_ScriptName)
    local ID = GetID(_ScriptName);
    if self.Data.IO[_ScriptName] and Logic.IsSettler(ID) == 1 then
        -- Only disable NPC if not used in any active quest
        if not QuestSystem or not QuestSystem.IsQuestNpcUsedByQuest(_ScriptName) then
            Logic.SetOnScreenInformation(ID, 0);
        end
        self.Data.IO[_ScriptName].Active = false;
        GameCallback_Logic_OnNpcDeactivated(_ScriptName, self.Data.IO[_ScriptName]);
    end
end

function Interaction.Internal:UpdateNpc(_Data)
    local Data = self.Data.IO[_Data.ScriptName];
    if not Data then
        return self:CreateNpc(_Data);
    end
    Data.Callback   = _Data.Callback or Data.Callback;
    Data.Hero       = _Data.Hero or Data.Hero;
    Data.HeroInfo   = _Data.WrongHeroMsg or Data.HeroInfo;
    Data.Player     = _Data.Player or Data.Player;
    Data.PlayerInfo = _Data.WrongPlayerMsg or Data.PlayerInfo;
    GameCallback_Logic_OnNpcUpdated(_Data.ScriptName, Data);
end

function Interaction.Internal:IsNpc(_ScriptName)
    return self.Data.IO[_ScriptName] ~= nil;
end

function Interaction.Internal:IsActive(_ScriptName)
    return self:IsNpc(_ScriptName) and self.Data.IO[_ScriptName].Active == true;
end

function Interaction.Internal:HeroesLookAtNpc(_HeroID, _NpcID)
    local PlayerID = Logic.EntityGetPlayer(_HeroID);
    local HeroesTable = {};
    Logic.GetHeroes(PlayerID, HeroesTable);
    if XNetwork.Manager_DoesExist() == 0 then
        LookAt(_HeroID, _NpcID);
        for k, v in pairs(HeroesTable) do
            if v and IsExisting(v) and IsNear(v, _NpcID, 3000) then
                LookAt(v, _NpcID);
            end
        end
    end
end

function Interaction.Internal:GetNearestHero(_Npc, _Distance)
    local NpcID = GetID(_Npc);
    local HeroesTable = {};
    for PlayerID = 1, GetMaxAmountOfPlayer() do
        local PlayerHeroTable = {};
        Logic.GetHeroes(PlayerID, PlayerHeroTable);
        HeroesTable = CopyTable(PlayerHeroTable, HeroesTable);
    end
    local x1, y1, z1   = Logic.EntityGetPos(NpcID);
    local BestDistance = _Distance or Logic.WorldGetSize();
    local BestHero     = nil;
    for k, v in pairs(HeroesTable) do
        if v and IsExisting(v) then
            local x2, y2, z2 = Logic.EntityGetPos(v);
            local Distance   = math.sqrt(((x2-x1)^2)+((y2-y1)^2));
            if Distance < BestDistance then
                BestDistance = Distance;
                BestHero = v;
            end
        end
    end
    return BestHero;
end

function Interaction.Internal:IsInteractionPossible(_HeroID, _NpcID)
    local ScriptName = Logic.GetEntityName(_NpcID);
    local PlayerID = Logic.EntityGetPlayer(_HeroID);

    local Data = self.Data.IO[ScriptName];
    if Data then
        -- Check heroes
        if Data.Hero then
            local HeroTable = (type(Data.Hero) ~= "table" and {Data.Hero}) or Data.Hero;
            -- Check if talking to the hero
            local AnyHero = false;
            for i= 1, table.getn(HeroTable) do
                if _HeroID == GetID(HeroTable[i]) then
                    AnyHero = true;
                    break;
                end
            end
            -- Deny if hero is not listed
            if not AnyHero then
                if Data.HeroInfo and PlayerID == GUI.GetPlayerID() then
                    Message(Localize(Data.HeroInfo));
                end
                return false;
            end
        end
        -- Check players
        if Data.Player then
            local PlayerTable = (type(Data.Player) ~= "table" and {Data.Player}) or Data.Player;
            -- Check if talking to the player
            local AnyPlayer = false;
            for i= 1, table.getn(PlayerTable) do
                if PlayerTable[i] == PlayerID then
                    AnyPlayer = true;
                    break;
                end
            end
            -- Deny if player is not listed
            if not AnyPlayer then
                if Data.PlayerInfo and PlayerID == GUI.GetPlayerID() then
                    Message(Localize(Data.PlayerInfo));
                end
                return false;
            end
        end
        -- Pass test
        return true;
    end
    return false;
end

function Interaction.Internal:OverrideNpcInteraction()
    self.Orig_GameCallback_NPCInteraction = GameCallback_NPCInteraction;
    GameCallback_NPCInteraction = function(_HeroID, _NpcID)
        Interaction.Internal.Orig_GameCallback_NPCInteraction(_HeroID, _NpcID);
        self:OnNpcInteraction(_HeroID, _NpcID);
    end
end

function Interaction.Internal:OnNpcInteraction(_HeroID, _NpcID)
    local PlayerID = Logic.EntityGetPlayer(_HeroID);
    local HeroScriptName = CreateNameForEntity(_HeroID);
    local NpcScriptName = CreateNameForEntity(_NpcID);
    -- NPCs of quests always have priority over NPC system!
    if not QuestSystem or not QuestSystem.IsQuestNpcUsedByQuest(NpcScriptName) then
        self.LastInteractionHero[PlayerID] = HeroScriptName;
        self.LastInteractionNpc[PlayerID] = NpcScriptName;

        if self:IsInteractionPossible(_HeroID, _NpcID) then
            local NpcID = _NpcID;
            local MerchantID = Logic.GetMerchantBuildingId(_NpcID);
            if MerchantID ~= 0 then
                NpcID = MerchantID;
            end
            local ScriptName = Logic.GetEntityName(NpcID);
            local Data = self.Data.IO[ScriptName];
            if Data then
                if Data.IsMerchant then
                    GameCallback_Logic_InteractWithMerchant(PlayerID, _HeroID, NpcID, Data);
                else
                    GameCallback_Logic_InteractWithCharacter(PlayerID, _HeroID, NpcID, Data);
                end
            end
        end
    end
end

-- -------------------------------------------------------------------------- --
-- Jobs

function Interaction_Internal_NpcController(_Name)
    if not IsExisting(_Name) then
        return true;
    end
    if Interaction.Internal.Data.IO[_Name] then
        local Data = Interaction.Internal.Data.IO[_Name];
        GameCallback_Logic_OnTickNpcController(_Name, Data);
    end
end

