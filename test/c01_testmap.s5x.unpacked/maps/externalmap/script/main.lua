

function OnMapStart()
    Camera.ZoomSetFactorMax(2.0);
    CreateMapEntities();

    Script.Load("maps\\externalmap\\cerberus\\loader.lua");

    Lib.Require("comfort/IsDeadWrapper");
    -- Lib.Require("module/ai/AiArmy");
    -- Lib.Require("module/ai/AiTroopSpawner");
    Lib.Require("module/archive/Archive");
    Lib.Require("module/lua/Overwrite");
    Lib.Require("module/mp/BuyHero");
    Lib.Require("module/mp/Syncer");
    Lib.Require("module/io/NonPlayerMerchant");
    Lib.Require("module/quest/QuestSystem");
    Lib.Require("module/ui/Clock");
    Lib.Require("module/ui/Workplace");
    Lib.Require("module/weather/WeatherMaker");

    Archive.Install();
    Workplace.Install();
    BuyHero.Install();
    Clock.Install();

    Tools.GiveResouces(1, 9999, 9999, 9999, 9999, 9999, 9999);

    -- Script.Load("C:/Users/marti/Downloads/alliedrefill.lua");
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
    AiTroopSpawner.AddArmy(TestSpawnerID, TestArmyID, 30);
end

function CreateMapEntities()
    ReplaceEntity("P4residence1",Entities.PB_Residence2);
    ReplaceEntity("P4brickworks1",Entities.PB_Brickworks1);
    ReplaceEntity("P6archery1",Entities.PB_Archery2);
    ReplaceEntity("P6foundry1",Entities.PB_Foundry2);
    ReplaceEntity("P6residence1",Entities.PB_Residence1);
    ReplaceEntity("P6gate1",Entities.XD_DarkWallStraightGate);
    ReplaceEntity("P6farm2",Entities.PB_Farm2);
    ReplaceEntity("P6farm1",Entities.PB_Farm3);
    ReplaceEntity("P6residence2",Entities.PB_Residence3);
    ReplaceEntity("P5residence1",Entities.PB_Residence1);
    ReplaceEntity("P5farm1",Entities.PB_Farm2);
    ReplaceEntity("P5farm2",Entities.PB_Farm2);
    ReplaceEntity("P7residence1",Entities.PB_Residence2);
    ReplaceEntity("P2farm1",Entities.PB_Farm3);
    ReplaceEntity("P2farm2",Entities.PB_Farm3);
    ReplaceEntity("P2residence1",Entities.PB_Residence3);
    ReplaceEntity("P2residence2",Entities.PB_Residence3);
    ReplaceEntity("P2cathedral1",Entities.PB_Monastery3);
    ReplaceEntity("P2gunsmith1",Entities.PB_GunsmithWorkshop2);
    ReplaceEntity("P2tavern1",Entities.PB_Tavern1);
    ReplaceEntity("P8tavern1",Entities.PB_Tavern1);
    ReplaceEntity("P8residence1",Entities.PB_Residence1);
    ReplaceEntity("P8residence2",Entities.PB_Residence2);
    ReplaceEntity("HQ2",Entities.PB_Headquarters3);
end

