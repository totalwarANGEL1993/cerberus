function CreateTestTrainers()
    P6BarracksTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6barracks1",
        AllowedTypes = {
            UpgradeCategories.LeaderSword,
            UpgradeCategories.LeaderPoleArm,
        },
    }

    P6ArcheryTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6archery1",
        AllowedTypes = {
            UpgradeCategories.LeaderBow,
        },
    }

    P6StableTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6stable1",
        AllowedTypes = {
            UpgradeCategories.LeaderHeavyCavalry,
        },
    }

    P6FoundryTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6foundry1",
        AllowedTypes = {
            UpgradeCategories.Cannon1,
        },
    }
end

function CreateTestAttackArmies()

end

function CreateTestDefendArmies()
    P6Army1 = AiArmy.New(6, 8, GetPosition("Player6_PatrolPoint1"), 3500);
    AiTroopTrainer.AddArmy(P6BarracksTrainer, P6Army1);
    AiTroopTrainer.AddArmy(P6ArcheryTrainer, P6Army1);
    AiTroopTrainer.AddArmy(P6StableTrainer, P6Army1);
    AiTroopTrainer.AddArmy(P6FoundryTrainer, P6Army1);

    AiArmy.ClearCommands(P6Army1);
    local Command = AiArmy.CreateCommand(AiArmyCommand.Refill);
    AiArmy.PushCommand(P6Army1, Command, false);
end

