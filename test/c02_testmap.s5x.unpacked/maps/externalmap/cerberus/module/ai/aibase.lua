Lib.Require("comfort/GiveEntityName");
Lib.Require("module/ai/AiArmyManager");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiBase");

---
---
---

AiBase = AiBase or {}

-- -------------------------------------------------------------------------- --
-- API



-- -------------------------------------------------------------------------- --
-- Internal

AiBase.Internal = AiBase.Internal or {
    Data = {
        Player = {},
        Base = {},
    }
}

function AiBase.Internal:Install()
    if not self.isInstalled then
        self.Controller = Job.Second(function()
            for Base,_ in pairs(AiBase.Internal.Data.Base) do
                AiBase.Internal:ControlAllBase(Base);
            end
        end);
        self.isInstalled = true;
    end
end

function AiBase.Internal:CreateBase(_PlayerID, _HQ, _RestoreBuildingsInFog)
    self:EnableAi(_PlayerID);

    if not self.Data.Base[_HQ] then
        local Data = {
            PlayerID            = _PlayerID,
            HomeBase            = _HQ,
            IsRebuilding        = _RestoreBuildingsInFog == true,
            AttackTargets       = {},
            DefencePositions    = {},
            Armies              = {},
            Buildings           = {},
        }
        self.Data.Base[_HQ] = Data;
    end
end

function AiBase.Internal:DestroyBase(_HQ)
    self.Data.Base[_HQ] = nil;
end

function AiBase.Internal:IsExisting(_HQ)
    return self.Data.Base[_HQ] ~= nil;
end

function AiBase.Internal:ControlAllBase(_Base)
    local BaseData = self.Data.Base[_Base];
    if IsExisting(_Base) then
        -- Restore buildings
        if BaseData.IsRebuilding then
            for ScriptName,Data in pairs(BaseData.Buildings) do
                -- TODO: Better check for enemies...
                if Tools.IsMapPositionExplored(1, Data[1], Data[2]) == 0 then
                    if not IsExisting(ScriptName) then
                        local ID = Logic.CreateEntity(Data[4], Data[1], Data[2], Data[1], BaseData.PlayerID);
                        Logic.SetEntityName(ID, ScriptName);
                    end
                end
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

function AiBase.Internal:GetArmies(_HQ)
    if self.Data.Base[_HQ] then
        return self.Data.Base[_HQ].Armies;
    end
    return {};
end

function AiBase.Internal:GetBuildings(_HQ)
    if self.Data.Base[_HQ] then
        return self.Data.Base[_HQ].Buildings;
    end
    return {};
end

function AiBase.Internal:ChangePlayer(_HQ, _PlayerID)
    if self.Data.Base[_HQ] then
        -- Change buildings
        for k,v in pairs(self.Data.Base[_HQ].Buildings) do
            if IsExisting(v) and Logic.isConstructionComplete(GetID(v)) == 1 then
                ChangePlayer(v, _PlayerID);
            end
        end
        -- Change armies
        for k,v in pairs(self.Data.Base[_HQ].Armies) do
            AiArmyManager.ChangePlayer(v, _PlayerID);
            for _,FillerID in pairs(AiTroopSpawner.GetSpawnersOfArmy(v)) do
                AiTroopSpawner.ChangePlayer(FillerID, _PlayerID);
            end
        end
        -- Save player
        self.Data.Base[_HQ].PlayerID = _PlayerID;
    end
end

function AiBase.Internal:AddBuilding(_HQ, _ScriptName)
    if self.Data.Base[_HQ] then
        assert(IsExisting(_ScriptName), "Building does not exist!");
        local EntityID = GetID(_ScriptName);
        local PosX, PosY = Logic.EntityGetPos(EntityID);
        local Orientation = Logic.GetEntityOrientation(EntityID);
        local Type = Logic.GetEntityType(EntityID);
        self.Data.Base[_HQ].Buildings[_ScriptName] = {PosX, PosY, Orientation, Type};
    end
end

function AiBase.Internal:RemoveBuilding(_HQ, _ScriptName)
    if self.Data.Base[_HQ] then
        self.Data.Base[_HQ].Buildings[_ScriptName] = nil;
    end
end

function AiBase.Internal:AddArmy(_HQ, _ManagerID)
    if self.Data.Base[_HQ] then
        assert(AiArmyManagerData_ManagerIdToManagerInstance[_ManagerID]);
        local ArmyID = AiArmyManager.GetArmy(_ManagerID);
        assert(ArmyID ~= 0);

        AiArmyManager.EndCampaign(_ManagerID);
        for k,v in pairs(self.Data.Base[_HQ].Armies) do
            AiArmyManager.PurgeSynchronization(v);
            AiArmyManager.Synchronize(_ManagerID, v);
        end

        self.Data.Base[_HQ].Armies[_ManagerID] = {_ManagerID, ArmyID}
    end
end

function AiBase.Internal:RemoveArmy(_HQ, _ManagerID)
    if self.Data.Base[_HQ] then
        AiArmyManager.PurgeSynchronization(_ManagerID);
        AiArmyManager.EndCampaign(_ManagerID);

        for k,v in pairs(self.Data.Base[_HQ].AttackTargets) do
            AiArmyManager.RemoveAttackTarget(_ManagerID, v);
        end
        for k,v in pairs(self.Data.Base[_HQ].GuardPositions) do
            AiArmyManager.RemoveGuardPosition(_ManagerID, v);
        end

        self.Data.Base[_HQ].Armies[_ManagerID] = nil;
    end
end

function AiBase.Internal:EnableAi(_PlayerID)
    if not self.Data.Player[_PlayerID] then
        -- TODO: Check if has buildings
        AI.EnablePlayerAi(_PlayerID);
    end
end

function AiBase.Internal:GetHostilePlayers(_HQ)
    local Enemies = {};
    if self.Data.Base[_HQ] then
        for i= 1, table.getn(Score.Player) do
            if i ~= self.Data.Base[_HQ].PlayerID then
                if Logic.GetDiplomacyState(self.Data.Base[_HQ].PlayerID, i) == Diplomacy.Hostile then
                    table.insert(Enemies, i);
                end
            end
        end
    end
    return Enemies;
end

