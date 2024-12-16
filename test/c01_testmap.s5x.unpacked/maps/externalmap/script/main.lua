function OnMapStart()
    Script.Load("E:\\Repositories\\cerberus\\test\\c01_testmap.s5x.unpacked\\maps\\externalmap\\script\\briefingtestcases.lua");
    Script.Load("E:\\Repositories\\cerberus\\test\\c01_testmap.s5x.unpacked\\maps\\externalmap\\script\\npctestcases.lua");
    Script.Load("E:\\Repositories\\cerberus\\test\\c01_testmap.s5x.unpacked\\maps\\externalmap\\script\\questtestcases.lua");
    Script.Load("E:\\Repositories\\cerberus\\test\\c01_testmap.s5x.unpacked\\maps\\externalmap\\script\\triggertestcases.lua");

    Camera.ZoomSetFactorMax(2.0);
    CreateMapEntities();

    -- Script.Load("maps\\externalmap\\cerberus\\loader.lua");
    Script.Load("E:\\Repositories\\cerberus\\loader.lua");
    assert(Lib ~= nil);
    table.insert(Lib.Paths, 1, "E:/Repositories/");

    Lib.Require("comfort/ArePositionsConnected");
    Lib.Require("comfort/GetReachablePosition");
    Lib.Require("comfort/GetUpgradeCategoryByEntityType");
    Lib.Require("comfort/IsDeadWrapper");
    Lib.Require("module/ai/AiArmy");
    Lib.Require("module/ai/AiTroopSpawner");
    Lib.Require("module/ai/AiTroopTrainer");
    Lib.Require("module/archive/Archive");
    Lib.Require("module/cinematic/BriefingSystem");
    Lib.Require("module/lua/Overwrite");
    Lib.Require("module/mp/BuyHero");
    Lib.Require("module/mp/Syncer");
    Lib.Require("module/io/NonPlayerCharacter");
    Lib.Require("module/io/NonPlayerMerchant");
    Lib.Require("module/quest/QuestSystem");
    Lib.Require("module/ui/Clock");
    Lib.Require("module/ui/Workplace");
    Lib.Require("module/weather/WeatherMaker");

    Archive.Install();
    Workplace.Install();
    BuyHero.Install();
    Clock.Install();

    Tools.GiveResouces(1, 99999, 9999, 9999, 9999, 9999, 9999);

    --CreateTroopSpawnersTest()
    --CreateAttackArmiesTest1()
    CreateTroopTrainersTest()
    CreateAttackArmiesTest2()


    UseWeatherSet("HighlandsWeatherSet");
    LocalMusic.UseSet = HIGHLANDMUSIC;

    -- Rain (normal)
    Logic.AddWeatherElement(2, 30, 1, 2, 5, 10);
    -- Rain (with snow)
    Logic.AddWeatherElement(2, 30, 1, 4, 5, 10);
    -- Winter (normal)
    Logic.AddWeatherElement(3, 30, 1, 3, 5, 10);
    -- Winter (without snow)
    Logic.AddWeatherElement(3, 30, 1, 7, 5, 10);
    -- Winter (normal)
    Logic.AddWeatherElement(3, 30, 1, 3, 5, 10);
    -- Winter (with rain)
    Logic.AddWeatherElement(3, 30, 1, 8, 5, 10);
    -- Rain (normal)
    Logic.AddWeatherElement(2, 30, 1, 2, 5, 10);
    -- Summer (normal)
    Logic.AddWeatherElement(1, 30, 1, 1, 5, 10);
end

function CreateTroopSpawnersTest()
    P6BarracksSpawner = AiArmyRefiller.CreateSpawner {
        ScriptName = "P6barracks1",
        SpawnPoint = "P6barracks1Spawn",
        SpawnAmount = 1,
        Sequentially = true,
        Endlessly = true,
        AllowedTypes = {
            {Entities.PU_LeaderPoleArm1, 3},
            {Entities.PU_LeaderSword1, 3},
        }
    }

    P6ArcherySpawner = AiArmyRefiller.CreateSpawner {
        ScriptName = "P6archery1",
        SpawnPoint = "P6archery1Spawn",
        SpawnAmount = 2,
        Sequentially = true,
        Endlessly = true,
        AllowedTypes = {
            {Entities.PU_LeaderBow1, 3},
        }
    }

    P6StableSpawner = AiArmyRefiller.CreateSpawner {
        ScriptName = "P6stable1",
        SpawnPoint = "P6stable1Spawn",
        SpawnAmount = 1,
        Sequentially = true,
        Endlessly = true,
        AllowedTypes = {
            {Entities.PU_LeaderCavalry1, 3},
        }
    }

    P6FoundrySpawner = AiArmyRefiller.CreateSpawner {
        ScriptName = "P6foundry1",
        SpawnPoint = "P6foundry1Spawn",
        SpawnAmount = 1,
        Sequentially = true,
        Endlessly = true,
        AllowedTypes = {
            {Entities.PV_Cannon1, 0},
        }
    }
end

function CreateTroopTrainersTest()
    P6BarracksTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6barracks1",
        RallyPoint = GetPosition("P6militaryCenter2"),
    }

    P6ArcheryTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6archery1",
        RallyPoint = GetPosition("P6militaryCenter2"),
    }

    P6StableTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6stable1",
        RallyPoint = GetPosition("P6militaryCenter2"),
    }

    P6FoundryTrainer = AiArmyRefiller.CreateTrainer {
        ScriptName = "P6foundry1",
        RallyPoint = GetPosition("P6militaryCenter2"),
    }
end

function CreateAttackArmiesTest1()
    P6Army1 = AiArmy.New(6, 8, GetPosition("Player6_PatrolPoint1"), 3500);
    AiTroopSpawner.AddArmy(P6BarracksSpawner, P6Army1);
    AiTroopSpawner.AddArmy(P6ArcherySpawner, P6Army1);
    AiTroopSpawner.AddArmy(P6StableSpawner, P6Army1);
    AiTroopSpawner.AddArmy(P6FoundrySpawner, P6Army1);
end

function CreateAttackArmiesTest2()
    P6Army2 = AiArmy.New(6, 8, GetPosition("Player6_PatrolPoint1"), 3500);
    AiTroopTrainer.AddArmy(P6BarracksTrainer, P6Army2);
    AiTroopTrainer.AddArmy(P6ArcheryTrainer, P6Army2);
    AiTroopTrainer.AddArmy(P6StableTrainer, P6Army2);
    AiTroopTrainer.AddArmy(P6FoundryTrainer, P6Army2);
end

function MakeTestArmiesAttack1()
    AiArmy.ClearCommands(P6Army1);
    AiArmy.PushCommand(P6Army1, AiArmy.CreateCommand(AiArmyCommand.Move, "Player2_AttackTarget4"), false);
    AiArmy.PushCommand(P6Army1, AiArmy.CreateCommand(AiArmyCommand.Battle, "Player2_AttackTarget4"), false);
    AiArmy.PushCommand(P6Army1, AiArmy.CreateCommand(AiArmyCommand.Move, "Player6_PatrolPoint3"), false);
end

function MakeTestArmiesAttack2()
    AiArmy.ClearCommands(P6Army2);
    AiArmy.PushCommand(P6Army2, AiArmy.CreateCommand(AiArmyCommand.Move, "Player2_AttackTarget4"), false);
    AiArmy.PushCommand(P6Army2, AiArmy.CreateCommand(AiArmyCommand.Battle, "Player2_AttackTarget4"), false);
    AiArmy.PushCommand(P6Army2, AiArmy.CreateCommand(AiArmyCommand.Move, "Player6_PatrolPoint3"), false);
end

function WeakenTestArmies()
    for k= 1, 3 do
        for i= table.getn(AiArmy.Get(k).Troops), 1, -1 do
            local ID = AiArmy.Get(k).Troops[i];
            if i > 3 then
                local Soldiers = {Logic.GetSoldiersAttachedToLeader(ID)};
                for j= 2, Soldiers[1] +1 do
                    DestroyEntity(Soldiers[j]);
                end
            else
                DestroyEntity(ID);
            end
        end
    end
end



function CreateTestQuest()
    CreateQuest {
        Name        = "TestQuest1",
        Receiver    = 1,
        Time        = 10,

        {{Condition.Time, 10}},
        {{Objective.EntityDistance, "ari", "serf2", 500, true}},
        {{Effect.Message, "Oh no! It won't just work. :("}},
        {{Effect.Message, "It just work's. :)"}},
    }
end

function CreateTestMerchant()
    NonPlayerMerchant.Create {
        ScriptName      = "P7trader1",
        Spawnpoint      = "P7trader1"
    };
    NonPlayerMerchant.AddTroopOffer("P7trader1", Entities.PU_LeaderPoleArm1, {Wood = 500}, 5, 60);
    NonPlayerMerchant.AddTroopOffer("P7trader1", Entities.PU_LeaderBow1, {Wood = 500}, 5, 60);
    NonPlayerMerchant.Activate("P7trader1");
end

function CreateTestArmyOne()
    TestArmyID = AiArmy.New(3, 8, GetPosition("Player3_PatrolPoint1"), 3000);
end

function CreateTestSpawnerOne()
    TestSpawnerID = AiTroopSpawner.Create {
        ScriptName      = "P3robberyTower1",
        SpawnPoint      = "P3robberySpawn1",
        AllowedTypes    = {
            {Entities.PU_LeaderPoleArm1, 3},
            {Entities.PU_LeaderBow1, 3}
        }
    };
    AiTroopSpawner.AddArmy(TestSpawnerID, TestArmyID);
end

function CreateMapEntities()
    ReplaceEntity("P4residence1",Entities.PB_Residence2);
    ReplaceEntity("P4brickworks1",Entities.PB_Brickworks1);
    -- ReplaceEntity("P6archery1",Entities.PB_Archery2);
    -- ReplaceEntity("P6foundry1",Entities.PB_Foundry2);
    -- ReplaceEntity("P6residence1",Entities.PB_Residence1);
    -- ReplaceEntity("P6gate1",Entities.XD_DarkWallStraightGate);
    -- ReplaceEntity("P6farm2",Entities.PB_Farm2);
    -- ReplaceEntity("P6farm1",Entities.PB_Farm3);
    -- ReplaceEntity("P6residence2",Entities.PB_Residence3);
    ReplaceEntity("P5residence1",Entities.PB_Residence1);
    ReplaceEntity("P5farm1",Entities.PB_Farm2);
    ReplaceEntity("P5farm2",Entities.PB_Farm2);
    ReplaceEntity("P7residence1",Entities.PB_Residence2);
    ReplaceEntity("P2farm1",Entities.PB_Farm3);
    ReplaceEntity("P2farm2",Entities.PB_Farm3);
    -- ReplaceEntity("P2residence1",Entities.PB_Residence3);
    ReplaceEntity("P2residence2",Entities.PB_Residence3);
    ReplaceEntity("P2cathedral1",Entities.PB_Monastery3);
    ReplaceEntity("P2gunsmith1",Entities.PB_GunsmithWorkshop2);
    -- ReplaceEntity("P2tavern1",Entities.PB_Tavern1);
    ReplaceEntity("P8tavern1",Entities.PB_Tavern1);
    ReplaceEntity("P8residence1",Entities.PB_Residence1);
    ReplaceEntity("P8residence2",Entities.PB_Residence2);
    ReplaceEntity("HQ2",Entities.PB_Headquarters3);
end

