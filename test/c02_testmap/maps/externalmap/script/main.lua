function OnMapStart()
    -- Script.Load("data\\maps\\externalmap\\cerberus\\loader.lua");
    -- Script.Load("data\\maps\\cerberus\\loader.lua");
    Script.Load("data\\maps\\user\\cerberus\\loader.lua");
    assert(Lib ~= nil, "Cerberus was not found!");

    Lib.Require("module/ui/BuyHero");
    Lib.Require("module/cinematic/BriefingSystem");
    Lib.Require("module/ui/Placeholder");
    Lib.Require("module/io/NonPlayerCharacter");
    Lib.Require("module/io/NonPlayerMerchant");
    Lib.Require("module/entity/Treasure");

    Placeholder.Install();
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
        Hero = "kerberos",
        WrongHeroMsg = "Mit euch rede ich nicht!",
        Callback   = function()
            Message("Spieler 1 hat den {scarlet}ERICH{white} richtig eingesetzt!");
        end
    };
    NonPlayerCharacter.Activate("Npc1P1");

    NonPlayerCharacter.Create {
        ScriptName = "Npc1P2",
        Callback   = function()
            Message("Spieler 2 hat den {scarlet}ERICH{white} richtig eingesetzt!");
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

    -- Long text to test escape
    ASP(Interaction.Npc(_PlayerID), "Page 1", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);
    ASP(Interaction.Npc(_PlayerID), "Page 2", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);

    BriefingSystem.Start(_PlayerID, _Name, Briefing)
end

