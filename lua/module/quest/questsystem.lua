Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetHeadquarters");
Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("comfort/GetLanguage");
Lib.Require("comfort/GetPlayerEntities");
Lib.Require("comfort/GetResourceName");
Lib.Require("comfort/KeyOf");

Lib.Require("module/cinematic/BriefingSystem");
Lib.Require("module/io/Interaction");
Lib.Require("module/mp/Syncer");
Lib.Require("module/trigger/Job");
Lib.Require("module/ui/Placeholder");

Lib.Require("module/quest/QuestConstants");
Lib.Register("module/quest/QuestSystem");

--- 
--- 
---
--- Version 1.0.0
--- 

QuestSystem = QuestSystem or {};

-- -------------------------------------------------------------------------- --
-- API

function CreateQuest(_Data)
    return QuestSystem.Internal:CreateQuest(_Data);
end

function GetQuestID(_QuestName)
    return QuestSystem.Internal:GetQuestIDByName(_QuestName);
end

function IsValidQuest(_QuestName)
    return QuestSystem.Internal:GetQuestIDByName(_QuestName) ~= 0;
end

function StartQuest(_QuestName)
    local QuestID = GetQuestID(_QuestName);
    if QuestID > 0 then
        local QuestData = QuestSystem.Internal[QuestID];
        if QuestData.State == QuestState.Inactive and QuestData.Result == QuestResult.None then
            QuestSystem.Internal:TriggerQuest(QuestID);
        end
    end
end

function RestartQuest(_QuestName)
    local QuestID = GetQuestID(_QuestName);
    if QuestID > 0 then
        local QuestData = QuestSystem.Internal[QuestID];
        if QuestData.State == QuestState.Done and QuestData.Result ~= QuestResult.None then
            QuestSystem.Internal:RestartQuest(QuestID);
        end
    end
end

function RestartQuestForceActive(_QuestName)
    RestartQuest(_QuestName);
    StartQuest(_QuestName);
end

function FailQuest(_QuestName)
    local QuestID = GetQuestID(_QuestName);
    if QuestID > 0 then
        local QuestData = QuestSystem.Internal[QuestID];
        if QuestData.State ~= QuestState.Done and QuestData.State ~= QuestState.Inactive then
            QuestSystem.Internal:FailQuest(QuestID);
        end
    end
end

function WinQuest(_QuestName)
    local QuestID = GetQuestID(_QuestName);
    if QuestID > 0 then
        local QuestData = QuestSystem.Internal[QuestID];
        if QuestData.State ~= QuestState.Done and QuestData.State ~= QuestState.Inactive then
            QuestSystem.Internal:SucceedQuest(QuestID);
        end
    end
end

function InterruptQuest(_QuestName)
    local QuestID = GetQuestID(_QuestName);
    if QuestID > 0 then
        local QuestData = QuestSystem.Internal[QuestID];
        if QuestData.State ~= QuestState.Done then
            QuestSystem.Internal:InterruptQuest(QuestID);
        end
    end
end

-- -------------------------------------------------------------------------- --
-- Callbacks

function GameCallback_Logic_OnQuestTriggered(_QuestID, _PlayerID)
end

function GameCallback_Logic_OnQuestInterrupted(_QuestID, _PlayerID)
end

function GameCallback_Logic_OnQuestSuccess(_QuestID, _PlayerID)
end

function GameCallback_Logic_OnQuestFailure(_QuestID, _PlayerID)
end

function GameCallback_Logic_OnQuestInterrupt(_QuestID, _PlayerID)
end

function GameCallback_Logic_OnQuestRestart(_QuestID, _PlayerID)
end

-- -------------------------------------------------------------------------- --
-- Internal

QuestSystem.Internal = QuestSystem.Internal or {
    Data = {
        ExploreEntities = {},
        HurtEntities = {},
        EffectNames = {},
        CarringThieves = {},
    },
    Quests = {},
};

function QuestSystem.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        Placeholder.Install();
        Interaction.Install();
        for i= 1, GetMaxAmountOfPlayer() do
            self.Data[i] = {
                QuestInfo = {},
            };
        end
        self:InitJobs();
    end
end

--[[
Quest = {
    Name        = "foo",
    Receiver    = 1,
    State       = QuestState.Inactive,
    Result      = 0,
    Time        = -1,
    
    Conditions  = {{Condition.Time, 5}},
    Objectives  = {{Objective.Script, AnyFunction, ...}},
    Rewards     = {{Effect.Victory}},
    Reprisals   = {{Effect.Defeat}},
}
]]

function QuestSystem.Internal:CreateQuest(_Data)
    self:Install();

    local Quest = {};
    Quest.Name = _Data.Name;
    Quest.Receiver = _Data.Receiver or 1;
    Quest.State = QuestState.Inactive;
    Quest.Result = QuestResult.None;
    Quest.Time = _Data.Time or -1;

    Quest.Conditions = {};
    if _Data[1] then
        for i= 1, table.getn(_Data[1]) do
            table.insert(Quest.Conditions, _Data[1][i]);
        end
    else
        table.insert(Quest.Conditions, {Condition.Time, 0});
    end

    Quest.Objectives = {};
    if _Data[2] then
        for i= 1, table.getn(_Data[2]) do
            table.insert(Quest.Objectives, _Data[2][i]);
        end
    else
        table.insert(Quest.Objectives, {Objective.InstantSuccess});
    end

    Quest.Reprisals = {};
    if _Data[3] then
        for i= 1, table.getn(_Data[3]) do
            table.insert(Quest.Reprisals, _Data[3][i]);
        end
    end

    Quest.Rewards = {};
    if _Data[4] then
        for i= 1, table.getn(_Data[4]) do
            table.insert(Quest.Rewards, _Data[4][i]);
        end
    end

    table.insert(self.Quests, Quest);
    local ID = table.getn(self.Quests);
    return ID;
end

function QuestSystem.Internal:GetQuestIDByName(_Name)
    for i= 1, table.getn(self.Quests) do
        if self.Quests[i].Name == _Name then
            return i;
        end
    end
    return 0;
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:QuestController(_Index)
    -- Check if quests can be triggered and trigger them.
    if self.Quests[_Index].State == QuestState.Inactive then
        for i= 1, table.getn(self.Quests[_Index].Conditions) do
            if not self:CheckQuestCondition(_Index, i) then
                return;
            end
        end
        self:TriggerQuest(_Index);
        return;
    end

    -- Check the objective of active quests to decide them
    if self.Quests[_Index].State == QuestState.Active then
        if self.Quests[_Index].Result == QuestResult.None then
            local AnyObjectiveFalse = false;
            local AllObjectivesTrue = true;
            for i= 1, table.getn(self.Quests[_Index].Conditions) do
                local ObjectiveCompleted = self:CheckQuestObjective(_Index, i);
                if ObjectiveCompleted == nil then
                    if self.Quests[_Index].Time > 0 then
                        if self.Quests[_Index].StartTime + self.Quests[_Index].Time < Logic.GetTime() then
                            if self.Quests[_Index].Objectives[i][1] == Objective.Protect
                            or self.Quests[_Index].Objectives[i][1] == Objective.None then
                                ObjectiveCompleted = true;
                            else
                                ObjectiveCompleted = false;
                            end
                        end
                    end
                end
                AllObjectivesTrue = (ObjectiveCompleted == true) and AllObjectivesTrue;
                AnyObjectiveFalse = (ObjectiveCompleted == false and true) or AnyObjectiveFalse;
            end
            if AnyObjectiveFalse then
                self.Quests[_Index].FinishTime = Logic.GetTime();
                self.Quests[_Index].Result = QuestResult.Failure;
                self.Quests[_Index].State = QuestState.Decided;
            elseif AllObjectivesTrue then
                self.Quests[_Index].FinishTime = Logic.GetTime();
                self.Quests[_Index].Result = QuestResult.Success;
                self.Quests[_Index].State = QuestState.Decided;
            end
        end
    end

    -- Executes the reprisals or the rewards when decided
    -- (All quests are managed by 1 job so that substate is needed)
    if self.Quests[_Index].State == QuestState.Decided then
        if self.Quests[_Index].Result == QuestResult.Interrupt then
            self:InterruptQuest(_Index);
        end
        if self.Quests[_Index].Result == QuestResult.Failure then
            self:FailQuest(_Index);
        end
        if self.Quests[_Index].Result == QuestResult.Success then
            self:SucceedQuest(_Index);
        end
    end
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:TriggerQuest(_QuestID)
    if self.Quests[_QuestID].State == QuestState.Inactive then
        self.Quests[_QuestID].StartTime = Logic.GetTime();
        self.Quests[_QuestID].Result = QuestResult.None;
        self.Quests[_QuestID].State = QuestState.Active;
        self:ShowQuestMarkers(_QuestID);
        GameCallback_Logic_OnQuestTriggered(_QuestID, self.Quests[_QuestID].Receiver);
    end
end

function QuestSystem.Internal:InterruptQuest(_QuestID)
    if self.Quests[_QuestID].State ~= QuestState.Done then
        self.Quests[_QuestID].FinishTime = Logic.GetTime();
        self.Quests[_QuestID].Result = QuestResult.Interrupt;
        self.Quests[_QuestID].State = QuestState.Done;
        self:RemoveQuestMarkers(_QuestID);
        GameCallback_Logic_OnQuestInterrupt(_QuestID, self.Quests[_QuestID].Receiver);
    end
end

function QuestSystem.Internal:FailQuest(_QuestID)
    if self.Quests[_QuestID].State ~= QuestState.Done then
        self.Quests[_QuestID].Result = QuestResult.Failure;
        self.Quests[_QuestID].State = QuestState.Done;
        self:RemoveQuestMarkers(_QuestID);
        for i= 1, table.getn(self.Quests[_QuestID].Reprisals) do
            self:ApplyQuestResult(_QuestID, "Reprisals", i);
        end
        GameCallback_Logic_OnQuestFailure(_QuestID, self.Quests[_QuestID].Receiver);
    end
end

function QuestSystem.Internal:SucceedQuest(_QuestID)
    if self.Quests[_QuestID].State ~= QuestState.Done then
        self.Quests[_QuestID].State = QuestState.Done;
        self.Quests[_QuestID].Result = QuestResult.Success;
        self:RemoveQuestMarkers(_QuestID);
        for i= 1, table.getn(self.Quests[_QuestID].Rewards) do
            self:ApplyQuestResult(_QuestID, "Rewards", i);
        end
        GameCallback_Logic_OnQuestSuccess(_QuestID, self.Quests[_QuestID].Receiver);
    end
end

function QuestSystem.Internal:RestartQuest(_QuestID)
    if self.Quests[_QuestID].State == QuestState.Done then
        self.Quests[_QuestID].Result = QuestResult.None;
        self.Quests[_QuestID].State = QuestState.Inactive;
        self.Quests[_QuestID].StartTime = nil;
        self.Quests[_QuestID].FinishTime = nil;

        self:RestartQuestObjectives(_QuestID);
        self:RestartQuestConditions(_QuestID);
        self:RestartQuestCallbacks(_QuestID);

        GameCallback_Logic_OnQuestRestart(_QuestID, self.Quests[_QuestID].Receiver);
    end
end

function QuestSystem.Internal:RestartQuestObjectives(_QuestID)
    for i= 1, table.getn(self.Quests[_QuestID].Objectives) do
        -- Reset completed
        self.Quests[_QuestID].Objectives[i].Completed = nil;
        -- Reset custom
        if self.Quests[_QuestID].Objectives[i][1] == Objective.Script then
            if self.Quests[_QuestID].Objectives[i][3].Reset then
                self.Quests[_QuestID].Objectives[i][3]:Reset(self);
            end
        end
        -- Reset destroy type/category
        if self.Quests[_QuestID].Objectives[i][1] == Objective.DestroyType or self.Quests[_QuestID].Objectives[i][1] == Objective.DestroyCategory then
            self.Quests[_QuestID].Objectives[i][5] = 0;
        end
        -- Reset tribute
        if self.Quests[_QuestID].Objectives[i][1] == Objective.Tribute then
            if self.Quests[_QuestID].Objectives[i][4] then
                Logic.RemoveTribute(self.Quests[_QuestID].Receiver, self.Quests[_QuestID].Objectives[i][4]);
            end
            self.Quests[_QuestID].Objectives[i][5] = nil;
        end
        -- Reset steal
        if self.Quests[_QuestID].Objectives[i][1] == Objective.Steal then
            self.Quests[_QuestID].Objectives[i][4] = nil;
        end
        -- Reset NPC
        if self.Quests[_QuestID].Objectives[i][1] == Objective.NPC then
            self.Quests[_QuestID].Objectives[i][5] = nil;
            self.Quests[_QuestID].Objectives[i][6] = nil;
        end
    end
end

function QuestSystem.Internal:RestartQuestCallbacks(_QuestID)
    for i= 1, table.getn(self.Quests[_QuestID].Rewards), 1 do
        -- Reset custom
        if self.Quests[_QuestID].Rewards[i][1] == Objective.Script then
            if self.Quests[_QuestID].Rewards[i][3].Reset then
                self.Quests[_QuestID].Rewards[i][3]:Reset(self);
            end
        end
    end
    for i= 1, table.getn(self.Quests[_QuestID].Reprisals), 1 do
        -- Reset custom
        if self.Quests[_QuestID].Reprisals[i][1] == Objective.Script then
            if self.Quests[_QuestID].Reprisals[i][3].Reset then
                self.Quests[_QuestID].Reprisals[i][3]:Reset(self);
            end
        end
    end
end

function QuestSystem.Internal:RestartQuestConditions(_QuestID)
    for i= 1, table.getn(self.Quests[_QuestID].Conditions) do
        -- Reset custom
        if self.Quests[_QuestID].Conditions[i][1] == Objective.Script then
            if self.Quests[_QuestID].Conditions[i][3].Reset then
                self.Quests[_QuestID].Conditions[i][3]:Reset(self);
            end
        end
        -- Reset payday
        if self.Quests[_QuestID].Conditions[i][1] == Condition.Payday then
            self.Quests[_QuestID].Conditions[i][2] = nil;
        end
    end
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:CheckQuestCondition(_QuestID, _Index)
    local QuestData = self.Quests[_QuestID];
    local Behavior = QuestData.Conditions[_Index];

    if Behavior[1] == Condition.Script then
        return _G[Behavior[2]](Behavior[3], QuestData);

    elseif Behavior[1] == Condition.None then
        -- Do nothing

    elseif Behavior[1] == Condition.Time then
        return Logic.GetTime() >= Behavior[2];

    elseif Behavior[1] == Condition.Briefing then
        return Cinematic.IsConcluded(QuestData.Receiver, Behavior[2]);

    elseif Behavior[1] == Condition.QuestState then
        return QuestData.State == Behavior[2];

    elseif Behavior[1] == Condition.QuestResult then
        return QuestData.Result == Behavior[2];

    elseif Behavior[1] == Condition.QuestOrQuest then
        local QuestID1 = self:GetQuestIDByName(Behavior[2]);
        local QuestID2 = self:GetQuestIDByName(Behavior[3]);
        if QuestID1 == 0 or QuestID2 == 0 then
            return false;
        end
        local ResultQuest1 = self.Quests[QuestID1].Result;
        local ResultQuest2 = self.Quests[QuestID2].Result;
        return ResultQuest1 == Behavior[4] or ResultQuest2 == Behavior[4];

    elseif Behavior[1] == Condition.QuestAndQuest then
        local QuestID1 = self:GetQuestIDByName(Behavior[2]);
        local QuestID2 = self:GetQuestIDByName(Behavior[3]);
        if QuestID1 == 0 or QuestID2 == 0 then
            return false;
        end
        local ResultQuest1 = self.Quests[QuestID1].Result;
        local ResultQuest2 = self.Quests[QuestID2].Result;
        return ResultQuest1 == Behavior[4] and ResultQuest2 == Behavior[4];

    elseif Behavior[1] == Condition.QuestXorQuest then
        local QuestID1 = self:GetQuestIDByName(Behavior[2]);
        local QuestID2 = self:GetQuestIDByName(Behavior[3]);
        if QuestID1 == 0 or QuestID2 == 0 then
            return false;
        end
        local ResultQuest1 = self.Quests[QuestID1].Result == Behavior[4];
        local ResultQuest2 = self.Quests[QuestID2].Result == Behavior[4];
        return (ResultQuest1 and not ResultQuest2) or (not ResultQuest1 and ResultQuest2);

    elseif Behavior[1] == Condition.Diplomacy then
        if Logic.GetDiplomacyState(Behavior[2], Behavior[3]) == Behavior[4] then
            return true;
        end

    elseif Behavior[1] == Condition.Payday then
        return Behavior[2] == true;

    elseif Behavior[1] == Condition.EntityDestroyed then
        return IsExisting(Behavior[2]) == false;

    elseif Behavior[1] == Condition.WeatherState then
        return Logic.GetWeatherState() == Behavior[2];
    end

    return true;
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:CheckQuestObjective(_QuestID, _Index)
    local QuestData = self.Quests[_QuestID];
    local Behavior = QuestData.Objectives[_Index];

    -- Do not check when its already completed
    if Behavior.Completed ~= nil then
        return Behavior.Completed;
    end

    local Completed;
    if Behavior[1] == Objective.Script then
        Completed = _G[Behavior[2]](Behavior[3], QuestData);

    elseif Behavior[1] == Objective.None then
        -- Do nothing

    elseif Behavior[1] == Objective.Failure then
        Completed = false;

    elseif Behavior[1] == Objective.Success then
        Completed = true;

    elseif Behavior[1] == Objective.NPC then
        if self:TalkedToNpc(_QuestID, _Index) then
            self:RemoveQuestMarkers(_QuestID);
            Completed = true;
        end

    elseif Behavior[1] == Objective.Destroy then
        if type(Behavior[2]) == "table" then
            if IsDead(Behavior[2]) then
                Completed = true;
            end
        else
            local EntityID = GetID(Behavior[2]);
            if not IsExisting(EntityID) then
                Completed = true;
            else
                if Logic.IsHero(EntityID) == 1 and Logic.GetEntityHealth(EntityID) == 0 then
                    Completed = true;
                end
            end
        end

    elseif Behavior[1] == Objective.DestroyAllPlayerUnits then
        local PlayerEntities = GetPlayerEntities(Behavior[2], 0);
        if table.getn(PlayerEntities) == 0 then
            Completed = true;
        else
            local LegalEntitiesCount = 0;
            for i= 1, table.getn(PlayerEntities) do
                local Type = Logic.GetEntityType(PlayerEntities[i]);
                if  Type ~= Entities.XD_ScriptEntity
                and Type ~= Entities.XD_BuildBlockScriptEntity
                and Type ~= Entities.XS_Ambient
                and Type ~= Entities.XD_Explore10
                and Type ~= Entities.XD_CoordinateEntity
                and Type ~= Entities.XD_Camp_Internal
                and Type ~= Entities.XD_StandartePlayerColor
                and Type ~= Entities.XD_StandardLarge then
                    if Logic.IsBuilding(PlayerEntities[i]) == 0 then
                        LegalEntitiesCount = LegalEntitiesCount +1;
                        -- No need to check the rest
                        break;
                    else
                        if  Logic.IsEntityInCategory(PlayerEntities[i], EntityCategories.Wall) == 0
                        and Logic.IsConstructionComplete(PlayerEntities[i]) == 1 then
                            LegalEntitiesCount = LegalEntitiesCount +1;
                            -- No need to check the rest
                            break;
                        end
                    end
                end
            end
            -- If nothing is found then the player is destroyed
            if LegalEntitiesCount == 0 then
                Completed = true;
            end
        end

    elseif Behavior[1] == Objective.Create then
        local Position = (type(Behavior[3]) == "table" and Behavior[3]) or GetPosition(Behavior[3]);
        if AreEntitiesInArea(QuestData.Receiver, Behavior[2], Position, Behavior[4], Behavior[5]) then
            if Behavior[7] then
                local CreatedEntities = {Logic.GetPlayerEntitiesInArea(QuestData.Receiver, Behavior[2], Position.X, Position.Y, Behavior[4], Behavior[5])};
                for i= 2, table.getn(CreatedEntities), 1 do
                    ChangePlayer(CreatedEntities[i], Behavior[7]);
                end
            end
            Completed = true;
        end

    elseif Behavior[1] == Objective.Produce then
        local Amount = Logic.GetPlayersGlobalResource(QuestData.Receiver, Behavior[2]);
        if not Behavior[4] then
            Amount = Amount + Logic.GetPlayersGlobalResource(QuestData.Receiver, Behavior[2]+1);
        end
        if Amount >= Behavior[3] then
            Completed = true;
        end

    elseif Behavior[1] == Objective.Protect then
        local EntityID = GetID(Behavior[2]);
        if not IsExisting(EntityID) then
            Completed = false;
        else
            if Logic.IsHero(EntityID) == 1 and Logic.GetEntityHealth(EntityID) == 0 then
                Completed = false;
            end
        end

    elseif Behavior[1] == Objective.Diplomacy then
        if Logic.GetDiplomacyState(Behavior[2], Behavior[3]) == Behavior[4] then
            Completed = true;
        end

    elseif Behavior[1] == Objective.EntityDistance then
        local Distance = GetDistance(Behavior[2], Behavior[3]);
        local LowerThan = (Behavior[5] == nil and true) or Behavior[5];
        if LowerThan then
            if Distance < Behavior[4] then
                Completed = true;
            end
        else
            if Distance >= Behavior[4] then
                Completed = true;
            end
        end

    elseif Behavior[1] == Objective.Settlers or Behavior[1] == Objective.Workers
        or Behavior[1] == Objective.Soldiers or Behavior[1] == Objective.Motivation
        or Behavior[1] == Objective.Units then
        local Amount = 0;
        if Behavior[1] == Objective.Workers then
            Amount = Logic.GetNumberOfAttractedWorker(Behavior[4] or QuestData.Receiver);
        elseif Behavior[1] == Objective.Soldiers then
            Amount = Logic.GetNumberOfAttractedSoldiers(Behavior[4] or QuestData.Receiver);
        elseif Behavior[1] == Objective.Motivation then
            Amount = Logic.GetAverageMotivation(Behavior[4] or QuestData.Receiver);
        elseif Behavior[1] == Objective.Units then
            Amount = Logic.GetNumberOfEntitiesOfTypeOfPlayer(Behavior[4] or QuestData.Receiver, Behavior[2]);
        else
            Amount = Logic.GetNumberOfAttractedSettlers(Behavior[4] or QuestData.Receiver);
        end
        if Behavior[3] then
            if Amount < Behavior[2] then
                Completed = true;
            end
        else
            if Amount >= Behavior[2] then
                Completed = true;
            end
        end

    elseif Behavior[1] == Objective.Technology then
        if Logic.IsTechnologyResearched(QuestData.Receiver, Behavior[2]) == 1 then
            Completed = true;
        end

    elseif Behavior[1] == Objective.Headquarter then
        if Logic.GetPlayerEntities(QuestData.Receiver, Entities.PB_Headquarters1 + Behavior[2], 1) > 0 then
            Completed = true;
        end

    elseif Behavior[1] == Objective.DestroyType or Behavior[1] == Objective.DestroyCategory then
        Behavior[5] = Behavior[5] or 0;
        if Behavior[4] <= Behavior[5] then
            Completed = true;
        end

    elseif Behavior[1] == Objective.Tribute then
        if Behavior[4] == nil then
            local Text = Behavior[3];
            if type(Text) == "table" then
                Text = Text[GetLanguage()];
            end
            local TributeID = Syncer.Internal:NextTributeID();
            Text = Placeholder.Replace(Text);
            Logic.AddTribute(QuestData.Receiver, TributeID, 0, 0, Text, unpack(Behavior[2]));
            Behavior[4] = TributeID;
        end
        if Behavior[5] then
            Completed = true;
        end

    elseif Behavior[1] == Objective.WeatherState then
        if Logic.GetWeatherState() == Behavior[2] then
            Completed = true;
        end

    elseif Behavior[1] == Objective.Quest then
        local QuestID = self:GetQuestIDByName(Behavior[2]);
        if QuestID == 0 then
            Completed = false;
        else
            if self:ContainsObjective(_QuestID, Objective.NoChange) then
                Completed = true;

            elseif self.Quests[_QuestID].State == QuestState.Done then
                if self.Quests[_QuestID].Result ~= QuestResult.Undecided then
                    if Behavior[3] == nil or self.Quests[_QuestID].Result == Behavior[3]
                    or self.Quests[_QuestID].Result == QuestResult.Interrupted then
                        Completed = true;
                    else
                        -- failed and not required -> true
                        -- failed and required -> false
                        Completed = not Behavior[4];
                    end
                else
                    Completed = true;
                end
            end
        end

    elseif Behavior[1] == Objective.Bridge then
        if not IsExisting(Behavior[2]) then
            Completed = false;
        else
            local x, y, z = Logic.EntityGetPos(GetID(Behavior[2]));
            for i= 1, 4, 1 do
                local n, Entity = Logic.GetEntitiesInArea(Entities["PB_Bridge" ..i], x, y, Behavior[3], 1);
                if n > 0 and Logic.IsConstructionComplete(Entity) == 1 then
                    Completed = true;
                    break;
                end
            end
        end

    elseif Behavior[1] == Objective.Steal then
        if (Behavior[4] or 0) >= Behavior[3] then
            Completed = true;
        end
    end

    QuestData.Objectives[_Index].Completed = Completed;
    return Completed;
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:ApplyQuestResult(_QuestID, _ResultType, _Index)
    local QuestData = self.Quests[_QuestID];
    local Behavior = QuestData[_ResultType][_Index];

    if Behavior[1] == Effect.Script then
        _G[Behavior[2]](Behavior[3], QuestData);

    elseif Behavior[1] == Effect.Defeat then
        Logic.PlayerSetGameStateToLost(QuestData.Receiver);
        if XNetwork.Manager_DoesExist() == 0 then
            Trigger.DisableTriggerSystem(1);
        end

    elseif Behavior[1] == Effect.Victory then
        Logic.PlayerSetGameStateToWon(QuestData.Receiver);
        if XNetwork.Manager_DoesExist() == 0 then
            Trigger.DisableTriggerSystem(1);
        end

    elseif Behavior[1] == Effect.Message then
        local PlayerID = -1;
        local Text = Behavior[2];
        if type(Text) == "number" then
            PlayerID = Text;
            Text = Behavior[3];
        end
        if PlayerID == -1 or PlayerID == GUI.GetPlayerID() then
            Message(self:GetLocalizedMessage(Text));
        end

    elseif Behavior[1] == Effect.Briefing then
        _G[Behavior[3]](QuestData.Receiver, Behavior[2]);

    elseif Behavior[1] == Effect.OpenEntry then
        local PlayerID = QuestData.Receiver;
        Logic.AddQuest(PlayerID, Behavior[2], Behavior[3], Behavior[4], Behavior[5], Behavior[6]);
        self.Data[PlayerID].QuestInfo[Behavior[2]] = {Behavior[3], Behavior[4], Behavior[5], Behavior[6]};

    elseif Behavior[1] == Effect.CloseEntry then
        local PlayerID = QuestData.Receiver;
        if self.Data[PlayerID].QuestInfo[Behavior[2]] then
            local QuestType = self.Data[PlayerID].QuestInfo[Behavior[2]][1];
            Logic.SetQuestType(PlayerID, Behavior[2], QuestType +1, Behavior[3]);
        end

    elseif Behavior[1] == Effect.RemoveEntry then
        local PlayerID = QuestData.Receiver;
        if self.Data[PlayerID].QuestInfo[Behavior[2]] then
            Logic.RemoveQuest(PlayerID, Behavior[2]);
            self.Data[PlayerID].QuestInfo[Behavior[2]] = nil;
        end

    elseif Behavior[1] == Effect.QuestSucceed then
        local QuestID = self:GetQuestIDByName(Behavior[2]);
        if QuestID ~= 0 then
            self:SucceedQuest(QuestID);
        end

    elseif Behavior[1] == Effect.QuestFail then
        local QuestID = self:GetQuestIDByName(Behavior[2]);
        if QuestID ~= 0 then
            self:FailQuest(QuestID);
        end

    elseif Behavior[1] == Effect.QuestInterrupt then
        local QuestID = self:GetQuestIDByName(Behavior[2]);
        if QuestID ~= 0 then
            self:InterruptQuest(QuestID);
        end

    elseif Behavior[1] == Effect.QuestActivate then
        local QuestID = self:GetQuestIDByName(Behavior[2]);
        if QuestID ~= 0 then
            self:TriggerQuest(QuestID);
        end

    elseif Behavior[1] == Effect.QuestRestart then
        local QuestID = self:GetQuestIDByName(Behavior[2]);
        if QuestID ~= 0 then
            self:RestartQuest(QuestID);
        end

    elseif Behavior[1] == Effect.Technology then
        Logic.SetTechnologyState(QuestData.Receiver, Behavior[2], Behavior[3]);

    elseif Behavior[1] == Effect.Move then
        Move(Behavior[2], Behavior[3]);

    elseif Behavior[1] == Effect.RevealArea then
        if self.Data.ExploreEntities[Behavior[2]] then
            DestroyEntity(self.Data.ExploreEntities[Behavior[2]][1]);
        end
        local Position = GetPosition(Behavior[2]);
        local ID = Logic.CreateEntity(Entities.XD_ScriptEntity, Position.X, Position.Y, 0, QuestData.Receiver);
        Logic.SetEntityExplorationRange(ID, Behavior[3]/100);
        self.Data.ExploreEntities[Behavior[2]] = {ID, Behavior[3]};

    elseif Behavior[1] == Effect.ConcealArea then
        if self.Data.ExploreEntities[Behavior[2]] then
            DestroyEntity(self.Data.ExploreEntities[Behavior[2]]);
            self.Data.ExploreEntities[Behavior[2]] = nil;
        end

    elseif Behavior[1] == Effect.CreateMarker then
        if QuestData.Receiver == GUI.GetPlayerID() then
            local Position = GetPosition(Behavior[3]);
            if Behavior[2] == MarkerTypes.StaticFriendly then
                GUI.CreateMinimapMarker(Position.X, Position.Y, 0);
            elseif Behavior[2] == MarkerTypes.StaticNeutral then
                GUI.CreateMinimapMarker(Position.X, Position.Y, 2);
            elseif Behavior[2] == MarkerTypes.StaticEnemy then
                GUI.CreateMinimapMarker(Position.X, Position.Y, 6);
            elseif Behavior[2] == MarkerTypes.PulseFriendly then
                GUI.CreateMinimapPulse(Position.X, Position.Y, 0);
            elseif Behavior[2] == MarkerTypes.PulseNeutral then
                GUI.CreateMinimapPulse(Position.X, Position.Y, 2);
            else
                GUI.CreateMinimapPulse(Position.X, Position.Y, 6);
            end
        end

    elseif Behavior[1] == Effect.DestroyMarker then
        if QuestData.Receiver == GUI.GetPlayerID() then
            local Position = GetPosition(Behavior[2]);
            GUI.DestroyMinimapPulse(Position.X, Position.Y);
        end

    elseif Behavior[1] == Effect.ChangePlayer then
        ChangePlayer(Behavior[2], Behavior[3]);

    elseif Behavior[1] == Effect.CreateEffect then
        local Position = GetPosition(Behavior[4]);
        local ID = Logic.CreateEffect(Behavior[3], Position.X, Position.Y, QuestData.Receiver);
        self.Data.EffectNames[Behavior[2]] = ID;

    elseif Behavior[1] == Effect.CreateEntity then
        ReplaceEntity(Behavior[2], Behavior[3]);
        ChangePlayer(Behavior[2], Behavior[4]);

    elseif Behavior[1] == Effect.CreateGroup then
        ReplaceEntity(Behavior[2], Behavior[3]);
        ChangePlayer(Behavior[2], Behavior[5]);
        Tools.CreateSoldiersForLeader(GetID(Behavior[2]), Behavior[4]);

    elseif Behavior[1] == Effect.DestroyEntity then
        local ID = GetID(Behavior[2]);
        local Soldiers = {Logic.GetSoldiersAttachedToLeader(ID)};
        for i= 2, Soldiers[1]+1 do
            DestroyEntity(Soldiers[i]);
        end
        ReplaceEntity(ID, Entities.XD_ScriptEntity);

    elseif Behavior[1] == Effect.DestroyEffect then
        if self.Data.EffectNames[Behavior[2]] then
            Logic.DestroyEffect(self.Data.EffectNames[Behavior[2]]);
        end

    elseif Behavior[1] == Effect.Resource then
        if Behavior[3] > 0 then
            Logic.AddToPlayersGlobalResource(QuestData.Receiver, Behavior[2], Behavior[3]);
        elseif Behavior[3] < 0 then
            Logic.SubFromPlayersGlobalResource(QuestData.Receiver, Behavior[2], (-1)*Behavior[3]);
        end

    elseif Behavior[1] == Effect.Diplomacy then
        local Exploration = (Behavior[4] == Diplomacy.Friendly and 1) or 0;
        Logic.SetShareExplorationWithPlayerFlag(Behavior[2], Behavior[3], Exploration);
		Logic.SetShareExplorationWithPlayerFlag(Behavior[3], Behavior[2], Exploration);
        Logic.SetDiplomacyState(Behavior[2], Behavior[3], Behavior[4]);
    end
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:ShowQuestMarkers(_QuestID)
    local QuestData = self.Quests[_QuestID];

    for i= 1, table.getn(QuestData.Objectives), 1 do
        if QuestData.State == QuestState.Active then
            if QuestData.Objectives[i][1] == Objective.Create then
                if QuestData.Objectives[i][6] then
                    local Position = QuestData.Objectives[i][3];
                    if type(Position) ~= "table" then
                        Position = GetPosition(Position);
                    end
                    local EffectID = Logic.CreateEffect(
                        GGL_Effects.FXTerrainPointer,
                        Position.X,
                        Position.Y,
                        QuestData.Receiver
                    );
                    self.Quests[_QuestID].Objectives[i][8] = EffectID;
                end
            elseif QuestData.Objectives[i][1] == Objective.NPC then
                if not self:IsNpcUsedByOtherQuestOfPlayer(_QuestID, QuestData.Receiver, QuestData.Objectives[i][2]) then
                    if not QuestData.Objectives[i][5] then
                        if GUI.GetPlayerID() == QuestData.Receiver then
                            EnableNpcMarker(QuestData.Objectives[i][2]);
                        end
                        self.Quests[_QuestID].Objectives[i][5] = true;
                    end
                end
            end
        end
    end
end

function QuestSystem.Internal:RemoveQuestMarkers(_QuestID)
    local QuestData = self.Quests[_QuestID];

    for i= 1, table.getn(QuestData.Objectives), 1 do
        if QuestData.State == QuestState.Done then
            if QuestData.Objectives[i][1] == Objective.Create then
                if QuestData.Objectives[i][8] then
                    Logic.DestroyEffect(QuestData.Objectives[i][8]);
                end
            elseif QuestData.Objectives[i][1] == Objective.NPC then
                if not self:IsNpcUsedByOtherQuestOfPlayer(_QuestID, QuestData.Receiver, QuestData.Objectives[i][2]) then
                    if GUI.GetPlayerID() == QuestData.Receiver then
                        DisableNpcMarker(QuestData.Objectives[i][2]);
                    end
                    self.Quests[_QuestID].Objectives[i][5] = false;
                end
            end
        end
    end
end

function QuestSystem.Internal:IsNpcUsedByOtherQuestOfPlayer(_QuestID, _PlayerID, _NPC)
    local QuestData = self.Quests[_QuestID];
    for i= 1, table.getn(self.Quests) do
        local Other = self.Quests[i];
        if QuestData.Name ~= Other.Name then
            if Other.State == QuestState.Active then
                if Other.Receiver == _PlayerID then
                    for j= 1, table.getn(Other.Objectives), 1 do
                        if Other.Objectives[j][1] == Objective.NPC then
                            if GetID(Other.Objectives[j][2]) == GetID(_NPC) then
                                return true;
                            end
                        end
                    end
                end
            end
        end
    end
    return false;
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:InitJobs()
    -- Quest job
    Job.Second(function()
        for i= 1, table.getn(QuestSystem.Internal.Quests) do
            -- FIXME: Run with xpcall?
            QuestSystem.Internal:QuestController(i);
        end
    end);

    -- Hurt job
    Job.Second(function()
        local Attacker  = Event.GetEntityID1();
        local Defenders = {Event.GetEntityID2()};
        for i= 1, table.getn(Defenders), 1 do
            local Soldiers;
            if Logic.IsLeader(Defenders[i]) == 1 then
                Soldiers = {Logic.GetSoldiersAttachedToLeader(Defenders[i])};
                table.remove(Soldiers, 1);
            end
            QuestSystem.Internal.Data.HurtEntities[Defenders[i]] = {
                Attacker, Logic.GetTime(), Soldiers
            };
        end
    end);

    -- Destruction job
    Job.Second(function()
        local Destroyed = {Event.GetEntityID()};
        for i= 1, table.getn(Destroyed), 1 do
            if QuestSystem.Internal.Data.HurtEntities[Destroyed[i]] then
                local AttackerID = QuestSystem.Internal.Data.HurtEntities[Destroyed[i]][1];
                local AttackingPlayer = Logic.EntityGetPlayer(AttackerID);
                local DefendingPlayer = Logic.EntityGetPlayer(Destroyed[i]);
                QuestSystem.Internal:ObjectiveDestroyedEntitiesHandler(
                    AttackingPlayer, AttackerID, DefendingPlayer, Destroyed[i]
                );
            end
        end
    end);

    -- Thief job
    Job.Second(function()
        for i= 1, GetMaxAmountOfPlayer() do
            QuestSystem.Internal:ObjectiveStealHandler(i);
        end
    end);

    -- Tribute job
    Job.Tribute(function()
        QuestSystem.Internal:QuestTributePayed(Event.GetTributeUniqueID());
    end);

    -- Payday job
    Job.Turn(function()
        local PaydayTimeoutFlag;
        local PaydayOverFlag;

        PaydayTimeoutFlag = PaydayTimeoutFlag or {};
        PaydayOverFlag = PaydayOverFlag or {};

        for i= 1, GetMaxAmountOfPlayer(), 1 do
            local Frequency = Logic.GetPlayerPaydayFrequency(i);
            PaydayTimeoutFlag[i] = PaydayTimeoutFlag[i] or false;
            PaydayOverFlag[i] = PaydayOverFlag[i] or false;

            if Logic.GetPlayerPaydayTimeLeft(i) < 1000  then
                PaydayTimeoutFlag[i] = true;
            elseif Logic.GetPlayerPaydayTimeLeft(i) > Frequency - 2000 then
                PaydayTimeoutFlag[i] = false;
                PaydayOverFlag[i] = false;
            end
            if PaydayTimeoutFlag and not PaydayOverFlag then
                QuestSystem.Internal:QuestPaydayEvent(i);
                PaydayOverFlag[i] = true;
            end
        end
    end);

    -- NPC interaction
    self.Orig_GameCallback_NPCInteraction = GameCallback_NPCInteraction;
    GameCallback_NPCInteraction = function(_HeroID, _NpcID)
        QuestSystem.Internal.Orig_GameCallback_NPCInteraction(_HeroID, _NpcID);
        QuestSystem.Internal:OnQuestNpcInteraction(_NpcID, _HeroID);
    end
end

function QuestSystem.Internal:ObjectiveDestroyedEntitiesHandler(_AttackingPlayer, _AttackingID, _DefendingPlayer, _DefendingID)
    for i= 1, table.getn(self.Quests), 1 do
        local Quest = self.Quests[i];
        if Quest.State == QuestState.Active and Quest.Result == QuestResult.Undecided then
            for j= 1, table.getn(Quest.Objectives), 1 do
                -- Destroy type
                if Quest.Objectives[j][1] == Objective.DestroyType then
                    self.Quests[i].Objectives[j][5] = Quest.Objectives[j][5] or 0;
                    if Quest.Receiver == _AttackingPlayer and (Quest.Objectives[j][2] == -1 or _DefendingPlayer == Quest.Objectives[j][2]) then
                        if Logic.GetEntityType(_DefendingID) == Quest.Objectives[j][3] then
                            self.Quests[i].Objectives[j][5] = Quest.Objectives[j][5] + 1;
                        end
                    end
                -- Destroy category
                elseif Quest.Objectives[j][1] == Objective.DestroyCategory then
                    self.Quests[i].Objectives[j][5] = Quest.Objectives[j][5] or 0;
                    if Quest.Receiver == _AttackingPlayer and (Quest.Objectives[j][2] == -1 or _DefendingPlayer == Quest.Objectives[j][2]) then
                        if Logic.IsEntityInCategory(_DefendingID, Quest.Objectives[j][3]) == 1 then
                            self.Quests[i].Objectives[j][5] = Quest.Objectives[j][5] + 1;
                        end
                    end
                end
            end
        end
    end
end

function QuestSystem.Internal:ObjectiveStealHandler(_PlayerID)
    local HeadquartersID = GetHeadquarters(_PlayerID);
    if HeadquartersID ~= 0 then
        local x, y, z = Logic.EntityGetPos(HeadquartersID);
        local ThiefIDs = {Logic.GetPlayerEntitiesInArea(_PlayerID, Entities.PU_Thief, x, y, 2000, 16)};
        for i= 2, ThiefIDs[1]+1, 1 do
            local RessouceID, RessourceAmount = Logic.GetStolenResourceInfo(ThiefIDs[i]);
            if RessouceID ~= 0 then
                if self.Data.CarringThieves[ThiefIDs[i]] == nil then
                    self.Data.CarringThieves[ThiefIDs[i]] = {RessouceID, RessourceAmount};
                end
            else
                if self.Data.CarringThieves[ThiefIDs[i]] ~= nil then
                    local StohlenGood = self.Data.CarringThieves[ThiefIDs[i]][1];
                    local StohlenAmount = self.Data.CarringThieves[ThiefIDs[i]][2];
                    for j= 1, table.getn(self.Quests) do
                        if self.Quests[j].Receiver == _PlayerID then
                            for k= 1, table.getn(self.Quests[j].Objectives), 1 do
                                if self.Quests[j].Objectives[k][1] == Objective.Steal then
                                    if self.Quests[j].Objectives[k][2] == StohlenGood or self.Quests[j].Objectives[k][2] +1 == StohlenGood then
                                        self.Quests[j].Objectives[k][4] = (self.Quests[j].Objectives[k][4] or 0) + StohlenAmount;
                                    end
                                end
                            end
                        end
                    end
                    self.Data.CarringThieves[ThiefIDs[i]] = nil;
                end
            end
        end
    end
end

function QuestSystem.Internal:QuestTributePayed(_TributeID)
    for i= 1, table.getn(self.Quests), 1 do
        local Quest = self.Quests[i];
        if Quest.State == QuestState.Active and Quest.Result == QuestResult.Undecided then
            for j= 1, table.getn(Quest.Objectives), 1 do
                if Quest.Objectives[j][1] == Objective.Tribute then
                    if _TributeID == Quest.Objectives[j][4] then
                        if Quest.Receiver == GUI.GetPlayerID() then
                            GUIAction_ToggleMenu( XGUIEng.GetWidgetID("TradeWindow"), 0);
                            Sound.PlayGUISound(Sounds.OnKlick_Select_helias, 127);
                        end
                        self.Quests[i].Objectives[j][5] = true;
                    end
                end
            end
        end
    end
end

function QuestSystem.Internal:QuestPaydayEvent(_PlayerID)
    for i= 1, table.getn(self.Quests), 1 do
        local QuestData = self.Quests[i];
        if QuestData.Receiver == _PlayerID and QuestData.State == QuestState.Inactive then
            for j= 1, table.getn(QuestData.Conditions), 1 do
                if QuestData.Conditions[j][1] == Condition.Payday then
                    self.Quests[i].Conditions[j][2] = true;
                end
            end
        end
    end
end

function QuestSystem.Internal:TalkedToNpc(_QuestID, _BehaviorIndex)
    return self.Quests[_QuestID].Objectives[_BehaviorIndex][6];
end

function QuestSystem.Internal:OnQuestNpcInteraction(_NpcID, _HeroID)
    local PlayerID = Logic.EntityGetPlayer(_HeroID);
    for QuestID = 1, table.getn(self.Quests) do
        local Quest = self.Quests[QuestID];
        if Quest.State == QuestState.Active then
            for j= 1, table.getn(Quest.Objectives), 1 do
                if Quest.Objectives[j][1] == Objective.NPC then
                    if GetID(Quest.Objectives[j][2]) == GetID(_NpcID) then
                        if Quest.Objectives[j][3] then
                            if GetID(Quest.Objectives[j][3]) ~= GetID(_HeroID) then
                                if Quest.Objectives[j][4] and GUI.GetPlayerID() == PlayerID then
                                    Message(self:GetLocalizedMessage(Quest.Objectives[j][4]));
                                end
                            else
                                self.Quests[QuestID].Objectives[j][6] = true;
                            end
                        else
                            self.Quests[QuestID].Objectives[j][6] = true;
                        end
                    end
                end
            end
        end
    end
end

-- -------------------------------------------------------------------------- --

function QuestSystem.Internal:ContainsObjective(_QuestID, _Objective)
    local QuestData = self.Quests[_QuestID];
    for i= 1, table.getn(QuestData.Objectives), 1 do
        QuestData.Objectives[i].Completed = nil;
        if QuestData.Objectives[i][1] == _Objective then
            return true;
        end
    end
    return false;
end

function QuestSystem.Internal:GetLocalizedMessage(_Msg)
    local Language = GetLanguage();
    local Msg = _Msg;

    if type(Msg) == "table" then
        Msg = Msg[Language];
    end
    if string.find(Msg, "^[A-Za-z0-9_]+/[A-Za-z0-9_]+$") then
        Msg = XGUIEng.GetStringTableText(Msg);
    end
    return Msg;
end

