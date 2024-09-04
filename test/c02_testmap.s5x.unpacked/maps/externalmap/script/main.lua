function OnMapStart()
    Script.Load("data\\maps\\externalmap\\cerberus\\loader.lua");
    -- Script.Load("data\\maps\\cerberus\\loader.lua");
    -- Script.Load("E:\\Repositories\\cerberus\\loader.lua");
    assert(Lib ~= nil, "Cerberus was not found!");

    Lib.Require("module/mp/BuyHero");
    Lib.Require("module/cinematic/SpectatableBriefing");
    Lib.Require("module/ui/Placeholder");
    Lib.Require("module/io/NonPlayerCharacter");
    Lib.Require("module/io/NonPlayerMerchant");
    Lib.Require("module/entity/Treasure");

    Placeholder.Install();
    BuyHero.Install();
    BuyHero.SetNumberOfBuyableHeroes(1, 1);
    BuyHero.SetNumberOfBuyableHeroes(2, 1);

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
        Hero = "P1Hero1",
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
        Callback   = function(_Data)
            TestBriefing(_Data.ScriptName, 1, "ExclusiveBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc2P1");

    NonPlayerCharacter.Create {
        ScriptName = "Npc2P2",
        Hero = "HansWurst",
        WrongHeroMsg = "It work's but I am not talking to you!",
        Callback   = function(_Data)
            TestBriefing(_Data.ScriptName, 2, "ExclusiveBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc2P2");
end

function CreateSharedBriefingNpcsForPlayers()
    NonPlayerCharacter.Create {
        ScriptName = "Npc3P1",
        Callback   = function(_Data)
            TestBriefing2(_Data.ScriptName, 1, "SharedBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc3P1");

    NonPlayerCharacter.Create {
        ScriptName = "Npc3P2",
        Callback   = function(_Data)
            TestBriefing2(_Data.ScriptName, 2, "SharedBriefing");
        end
    };
    NonPlayerCharacter.Activate("Npc3P2");
end

-- -- --

-- This briefing just tests the default briefing stuff.
function TestBriefing(_ScriptName, _PlayerID, _Name)
    local Briefing = {};
    local AP, ASP, AMC = BriefingSystem.AddPages(Briefing);

    ASP(_ScriptName, "Page 1", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);
    ASP(_ScriptName, "Page 2", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);

    BriefingSystem.Start(_PlayerID, _Name, Briefing);
end

-- This briefing tests the spectatable briefings. Players that are not the
-- leading players can not skip by pressing escape and MC options are not
-- visible to them.
function TestBriefing2(_ScriptName, _PlayerID, _Name)
    local Briefing = {};
    local AP, ASP, AMC = BriefingSystem.AddPages(Briefing);

    -- Avoid getting stuck in Singleplayer tests
    if not Syncer.IsMultiplayer() then
        _PlayerID = 1;
    end

    local PlayerName = UserTool_GetPlayerName(_PlayerID);
    local PlayerColor = "@color:"..table.concat({GUI.GetPlayerColor(_PlayerID)}, ",");

    ASP(_ScriptName, "Page 1", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);
    ASP(_ScriptName, "Page 2", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);

    AP {
        Name         = "ChoicePage1",
        Title        = "Important Choice",
        Text         = "Make a important choice that will inevitable advance the plot!",
        TextAlter    = "Wait until " ..PlayerColor.. " " ..PlayerName.. " @color:255,255,255 has made a decision...",
        Target       = _ScriptName,
        DialogCamera = true,
        MC           = {
            {"Option 1", "PathOption1"},
            {"Option 2", "PathOption2"},
        },
    }

    ASP("PathOption1", _ScriptName, "Page 4", "Option 1 was chosen. @cr Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);
    ASP(_ScriptName, "Page 5", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);
    AP();
    ASP("PathOption2", _ScriptName, "Page 7", "Option 2 was chosen. @cr Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);
    ASP(_ScriptName, "Page 8", "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquy.", true);

    Briefing.Finished = function(_Data, _Abort)
        Message("It just work's! (Player " .._Data.PlayerID.. ")");
    end
    SpectatableBriefing.Start(_PlayerID, _Name, Briefing, 1, 2);
    -- BriefingSystem.Start(_PlayerID, _Name, Briefing, 1, 2);
end

