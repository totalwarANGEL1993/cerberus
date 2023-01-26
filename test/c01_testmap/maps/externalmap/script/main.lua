

function OnMapStart()
    Camera.ZoomSetFactorMax(2.0);
    CreateMapEntities();

    Script.Load("maps\\user\\cerberus\\loader.lua");

    Lib.Require("module/ai/AiArmy");
    Lib.Require("module/ai/AiTroopSpawner");
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

