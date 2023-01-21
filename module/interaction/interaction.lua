Lib.Register("module/interaction/Interaction");

--- 
--- Internal interaction controller
--- 
--- @require Syncer
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Interaction = Interaction or {}

-- -------------------------------------------------------------------------- --
-- API

--- Installs the interaction controller.
--- (This is usually called by code from other scripts.)
function Interaction.Install()
    Interaction.Internal:Install();
end

-- -------------------------------------------------------------------------- --
-- Callback

--- Called when a hero is talking to a normal npc.
--- @param _HeroID number ID of hero
--- @param _NpcID number  ID of npc
function GameCallback_Logic_InteractWithCharacter(_HeroID, _NpcID)
end

--- Called when a hero is talking to a merchant.
--- @param _HeroID number ID of hero
--- @param _NpcID number  ID of npc
function GameCallback_Logic_InteractWithMerchant(_HeroID, _NpcID)
end

--- Called on each second for each npc.
--- @param _Name string Script name of npc
function GameCallback_Logic_OnTickNpcController(_Name)
end

--- Called when a npc is activated.
--- @param _Name string Script name of npc
function GameCallback_Logic_OnNpcActivated(_Name)
end

--- Called when a npc is deactivated.
--- @param _Name string Script name of npc
function GameCallback_Logic_OnNpcDeactivated(_Name)
end

-- -------------------------------------------------------------------------- --
-- Internal

Interaction.Internal = Interaction.Internal or {
    Data = {
        IO = {}
    },
};

function Interaction.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self:OverrideNpcInteraction();
    end
end

function Interaction.Internal:CreateNpc(_Data)
    Interaction.Internal:DeleteNpc(_Data.Scriptname);

    local Data = {
        ScriptName = _Data.Scriptname,
        Callback   = _Data.Callback or function() end,
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
        {_Data.Scriptname}
    );

    self.Data.IO[_Data.Scriptname] = Data;
end

function Interaction.Internal:DeleteNpc(_Scriptname)
    -- Delete old instance
    if self.Data.IO[_Scriptname] then
        if JobIsRunning(self.Data.IO[_Scriptname].JobID) then
            EndJob(self.Data.IO[_Scriptname].JobID);
        end
        if self.Data.IO[_Scriptname].Active then
            Interaction.Internal:Deactivate(_Scriptname);
        end
        self.Data.IO[_Scriptname] = nil;
    end
end

function Interaction.Internal:Activate(_ScriptName)
    local ID = GetID(_ScriptName);
    if Logic.IsSettler(ID) == 1 then
        Logic.SetOnScreenInformation(ID, 1);
        self.Data.IO[_ScriptName].Active = true;
        GameCallback_Logic_OnNpcActivated(_ScriptName);
    end
end

function Interaction.Internal:Deactivate(_ScriptName)
    local ID = GetID(_ScriptName);
    if Logic.IsSettler(ID) == 1 then
        Logic.SetOnScreenInformation(ID, 0);
        self.Data.IO[_ScriptName].Active = false;
        GameCallback_Logic_OnNpcDeactivated(_ScriptName);
    end
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

function Interaction.Internal:GetNearestHero(_PlayerID, _NpcID, _Distance)
    local PlayerID = Logic.EntityGetPlayer(_PlayerID);
    local HeroesTable = {};
    Logic.GetHeroes(PlayerID, HeroesTable);

    local x1, y1, z1   = Logic.EntityGetPos(_NpcID);
    local BestDistance = _Distance or Logic.WorldGetSize();
    local BestHero     = nil;

    for k, v in pairs(HeroesTable) do
        if v and IsExisting(v) then
            local x2, y2, z2 = Logic.EntityGetPos(v);
            local Distance   = ((x2-x1)^2)+((y2-y1)^2);
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
        if Data.Hero then
            if _HeroID ~= GetID(Data.Hero) then
                if Data.WrongHeroInfo and PlayerID == GUI.GetPlayerID() then
                    local Msg = Data.WrongHeroInfo;
                    -- TODO: Localization
                    -- TODO: Placeholder
                    Message(Data.WrongHeroInfo);
                end
                return false;
            end
        end
        if Data.Hero then
            if PlayerID ~= GetID(Data.Player) then
                if Data.WongPlayerInfo and PlayerID == GUI.GetPlayerID() then
                    local Msg = Data.WongPlayerInfo;
                    -- TODO: Localization
                    -- TODO: Placeholder
                    Message(Msg);
                end
                return false;
            end
        end
        return true;
    end
    return false;
end

function Interaction.Internal:OverrideNpcInteraction()
    self.Orig_GameCallback_NPCInteraction = GameCallback_NPCInteraction;
    GameCallback_NPCInteraction = function(_HeroID, _NpcID)
        Interaction.Internal.Orig_GameCallback_NPCInteraction(_HeroID, _NpcID);

        if Interaction.Internal:IsInteractionPossible(_HeroID, _NpcID) then
            local ID = Logic.GetMerchantBuildingId(_NpcID);
            if ID ~= 0 then
                GameCallback_Logic_InteractWithMerchant(_HeroID, _NpcID);
            else
                GameCallback_Logic_InteractWithCharacter(_HeroID, _NpcID);
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
    GameCallback_Logic_OnTickNpcController(_Name);
end

