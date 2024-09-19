Lib.Require("comfort/AreEnemiesInArea");
Lib.Require("comfort/ArePositionsConnected");
Lib.Require("comfort/CreateNameForEntity");
Lib.Require("comfort/GetMaxAmountOfPlayer");
Lib.Require("comfort/GetDistance");
Lib.Require("comfort/GetUpgradeCategoryByEntityType");
Lib.Require("comfort/IsValidEntity");
Lib.Require("comfort/IsTraining");
Lib.Require("module/trigger/Job");
Lib.Register("module/ai/AiTroopTrainer");

---
--- Troop recruiter script
---
--- Allows to define buildings as trainers. Trainers recruit troops for armies
--- attached to them.
---
--- Version ALPHA
---

AiTroopTrainer = AiTroopTrainer or {};

AiArmyTrainerData_TrainerIdToTrainerInstance = {};

AiArmyTrainerConstants_CannonCategoryToType = {
    [UpgradeCategories.Cannon1] = Entities.PV_Cannon1,
    [UpgradeCategories.Cannon2] = Entities.PV_Cannon2,
    [UpgradeCategories.Cannon3] = Entities.PV_Cannon3,
    [UpgradeCategories.Cannon4] = Entities.PV_Cannon4,
};

-- -------------------------------------------------------------------------- --
-- API



-- -------------------------------------------------------------------------- --
-- Internal

AiTroopTrainer.Internal = AiTroopTrainer.Internal or {
    Data = {
        TrainerIdSequence = 0,
        Trainers = {},
    },
}

function AiTroopTrainer.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.ControllerJobID = Job.Turn(function()
            for i= table.getn(AiTroopTrainer.Internal.Data.Trainers), 1, -1 do
                local DataMod = math.mod(AiTroopTrainer.Internal.Data.Trainers[i].ID, 10);
                local TimeMod = math.mod(Logic.GetCurrentTurn(), 10);
                if DataMod == TimeMod then
                    AiTroopTrainer.Internal:ControlTrainer(i);
                end
            end
        end);
    end
end

function AiTroopTrainer.Internal:ControlTrainer(_Index)
    local Trainer = self.Data.Trainers[_Index];
    local RecruiterID = Trainer.RecruiterID;
    local PlayerID = Trainer.PlayerID;
    -- Execute for armies
    for i= table.getn(Trainer.Armies), 1, -1 do
        local ArmyID = Trainer.Armies[i];
        if not AiArmy.HasFullStrength(ArmyID) then
            local Types = AiArmy.GetAllowedTypes(ArmyID);
            local TypeCount = table.getn(Types);
            local RandomIndex = math.random(1, TypeCount);
            local UpCat = Types[RandomIndex];
            UpCat = AiArmyTrainerConstants_CannonCategoryToType[UpCat] or UpCat;
            AI.Army_BuyLeader(PlayerID, RecruiterID, UpCat);
        end
    end
end

