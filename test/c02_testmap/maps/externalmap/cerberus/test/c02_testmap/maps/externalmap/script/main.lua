function OnMapStart()
    Script.Load("data\\maps\\externalmap\\cerberus\\loader.lua");
    assert(Lib ~= nil, "Cerberus was not found!");

    Lib.Require("module/ui/BuyHero");
    Lib.Require("module/cinematic/BriefingSystem");
    Lib.Require("module/io/NonPlayerCharacter");
    Lib.Require("module/io/NonPlayerMerchant");
    Lib.Require("module/entity/Treasure");

    BuyHero.Install();

    CreateChestsForPlayers();
    CreateMerchantsForPlayers();
    CreateNormalNpcsForPlayers();
    CreateExclusiveBriefingNpcsForPlayers();
    CreateSharedBriefingNpcsForPlayers();

    Tools.GiveResouces(1, 5000, 5000, 5000, 5000, 5000, 5000);
    Tools.GiveResouces(2, 5000, 5000, 5000, 5000, 5000, 5000);
end

-- -- --

function CreateChestsForPlayers()
    for i= 1, 3 do
        Treasure.RandomChest("Chest" ..i.. "P1", 500, 750);
        Treasure.RandomChest("Chest" ..i.. "P2", 500, 750);
    end
end

function CreateMerchantsForPlayers()
    local MerchantP1 = "MerchantP1";
    NonPlayerMerchant.Create {
        ScriptName = MerchantP1,
        SpawnPoint = "MerchSpawnP1",
    };
    NonPlayerMerchant.AddResourceOffer(MerchantP1, ResourceType.Sulfur, 1000, {Gold = 750}, 10, 60);
    NonPlayerMerchant.AddTroopOffer(MerchantP1, Entities.PU_LeaderHeavyCavalry2, {Iron = 1250}, 5, 60);
    NonPlayerMerchant.AddTechnologyOffer(MerchantP1, Technologies.GT_Literacy, {Gold = 50, Wood = 150});
    NonPlayerMerchant.Activate(MerchantP1);

    local MerchantP2 = "MerchantP2";
    NonPlayerMerchant.Create {
        ScriptName = MerchantP2,
        SpawnPoint = "MerchSpawnP2",
    };
    NonPlayerMerchant.AddResourceOffer(MerchantP2, ResourceType.Sulfur, 1000, {Gold = 750}, 10, 60);
    NonPlayerMerchant.AddTroopOffer(MerchantP2, Entities.PU_LeaderHeavyCavalry2, {Iron = 1250}, 5, 60);
    NonPlayerMerchant.AddTechnologyOffer(MerchantP2, Technologies.GT_Literacy, {Gold = 50, Wood = 150});
    NonPlayerMerchant.Activate(MerchantP2);
end

function CreateNormalNpcsForPlayers()
    NonPlayerCharacter.Create {
        ScriptName = "Npc1P1",
        Callback   = function()
            Message("Player 1 talked to Npc1!");
        end
    };
    NonPlayerCharacter.Activate("Npc1P1");

    NonPlayerCharacter.Create {
        ScriptName = "Npc1P2",
        Callback   = function()
            Message("Player 1 talked to Npc1!");
        end
    };
    NonPlayerCharacter.Activate("Npc1P2");
end

function CreateExclusiveBriefingNpcsForPlayers()
    NonPlayerCharacter.Create {
        ScriptName = "Npc2P1",
        Callback   = function()
            TestBriefing(1, "ExclusiveBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc2P1");

    NonPlayerCharacter.Create {
        ScriptName = "Npc2P2",
        Callback   = function()
            TestBriefing(2, "ExclusiveBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc2P2");
end

function CreateSharedBriefingNpcsForPlayers()
    NonPlayerCharacter.Create {
        ScriptName = "Npc3P1",
        Callback   = function()
            TestBriefing(1, "SharedBriefing");
            TestBriefing(2, "SharedBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc3P1");

    NonPlayerCharacter.Create {
        ScriptName = "Npc3P2",
        Callback   = function()
            TestBriefing(2, "SharedBriefing");
            TestBriefing(1, "SharedBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc3P2");
end

-- -- --

function TestBriefing(_PlayerID, _Name)
    local Briefing = {};
    local AP, ASP, AMC = BriefingSystem.AddPages(Briefing);

    ASP(gvLastInteractionNpcName, "Page 1", "This is test page 1!", true);
    ASP(gvLastInteractionNpcName, "Page 2", "This is test page 2!", true);

    BriefingSystem.Start(_PlayerID, _Name, Briefing)
end

