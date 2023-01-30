Lib.Require("comfort/GetLanguage");
Lib.Require("comfort/KeyOf");
Lib.Require("module/trigger/Job");
Lib.Register("module/entity/Treasure");

--- 
--- Customizable chests
---
--- Treasures can be placed on the map. The default chests can contain resources
--- or technologies. But they can be configured to do more.
--- 
--- @require Job
--- @author totalwarANGEL
--- @version 1.0.0
--- 

Treasure = Treasure or {
    Opener = {
        ScriptName = 1,
        Hero = 2,
        Military = 3,
        Settler = 4,
    },
    Type = {
        Resource = 1,
        RandomResource = 2,
        Technology = 3,
        Custom = 4,
    }
};

-- -------------------------------------------------------------------------- --
-- API

function Treasure.Install()
    Treasure.Internal:Install();
end

--- Creates a custom defined treasure.
---
--- Possible fields for definition:
--- * ScriptName     (Required) ScriptName of NPC
--- * Distance       (Required) Discover distance
--- * Callback       (Required) Callback of the treasure
--- * BaseType       (Optional) Base entity type of treasue
--- * SwapType       (Optional) Replacement entity type after open
--- * Opener         (Optional) Restrition of opener units
---                  ScriptName - Only named entities can open
---                  Hero       - (Default) All heroes can open
---                  Military   - All military units can open
---                  Settler    - All settlers can open
--- * OpenerList     (Optional) List of named openers
---                  Only evaluated if Opener is set to ScriptName
---
--- @param _Data table Treasure definition table
function Treasure.CreateTreasure(_Data)
    local Data = CopyTable(_Data);
    Data.Type = Treasure.Type.Custom;
    if not Data.Opener then
        Data.Opener = Treasure.Opener.Hero;
    end
    if type(Data.Opener) == "string" then
        Data.Opener = Treasure.Opener[Data.Opener];
    end
    Treasure.Internal:CreateTreasure(Data);
end

--- Creates a chest with a specific amount of a resource.
---
--- The chest can be opened by any hero.
---
--- @param _ScriptName string Script name of treasure
--- @param _Resource number   Type of resource
--- @param _Amount number     Amount of resource
function Treasure.CreateResourceTreasure(_ScriptName, _Resource, _Amount)
    Treasure.Internal:CreateTreasure {
        ScriptName = _ScriptName,
        BaseType = Entities.XD_ChestClose,
        SwapType = Entities.XD_ChestOpen,
        Type = Treasure.Type.Resource,
        Opener = Treasure.Opener.Hero,
        Distance = 400,
        Resource = _Resource,
        Amount = _Amount,
    };
end

--- Creates a chest with a random amount of a random resource.
---
--- The chest can be opened by any hero.
---
--- @param _ScriptName string Script name of treasure
--- @param _Min number Minimum amount of resource
--- @param _Max number Maximum amount of resource
function Treasure.CreateRandomTreasure(_ScriptName, _Min, _Max)
    Treasure.Internal:CreateTreasure {
        ScriptName = _ScriptName,
        BaseType = Entities.XD_ChestClose,
        SwapType = Entities.XD_ChestOpen,
        Type = Treasure.Type.RandomResource,
        Opener = Treasure.Opener.Hero,
        Distance = 400,
        Minimum = _Min or 750,
        Maximum = _Max or 1250,
    };
end

--- Creates a chest that teaches a technology to the finder.
---
--- The chest can be opened by any hero.
---
--- @param _ScriptName string Script name of treasure
--- @param _Technology any
function Treasure.CreateTechnologyTreasure(_ScriptName, _Technology)
    Treasure.Internal:CreateTreasure {
        ScriptName = _ScriptName,
        BaseType = Entities.XD_ChestClose,
        SwapType = Entities.XD_ChestOpen,
        Type = Treasure.Type.Technology,
        Opener = Treasure.Opener.Hero,
        Distance = 400,
        Technology = _Technology,
    };
end

function Treasure.IsOpened(_ScriptName)
    return Treasure.Internal:IsOpened(_ScriptName);
end

-- -------------------------------------------------------------------------- --
-- Internal

Treasure.Internal = Treasure.Internal or {
    DefaultOpenerType = Treasure.Opener.Hero,
    Treasures = {},
}

function Treasure.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.ControlerJobID = Job.Second(function()
            for k,v in pairs(self.Treasures) do
                Treasure.Internal:Controller(k);
            end
        end);
    end
end

function Treasure.Internal:CreateTreasure(_Data)
    self:Install();
    if _Data.BaseType then
        ReplaceEntity(_Data.ScriptName, _Data.BaseType);
    end
    table.insert(self.Treasures, _Data);
end

function Treasure.Internal:DestroyTreasure(_ScriptName)
    for k,v in pairs(self.Treasures) do
        if v.ScriptName == _ScriptName then
            self.Treasures[k] = nil;
            break;
        end
    end
end

function Treasure.Internal:IsOpened(_ScriptName)
    for k,v in pairs(self.Treasures) do
        if v.ScriptName == _ScriptName then
            return self.Treasures[k].Opened == true;
        end
    end
    return false;
end

function Treasure.Internal:Controller(_Index)
    if self.Treasures[_Index] then
        if not self.Treasures[_Index].Opened then
            local PlayerID = self:GetOpeningPlayer(_Index);
            if PlayerID ~= 0 then
                self:OpenTreasure(_Index, PlayerID);
            end
        end
    end
end

-- Opens the treasure and executes the appropriate callback.
function Treasure.Internal:OpenTreasure(_Index, _PlayerID)
    if self.Treasures[_Index] then
        self.Treasures[_Index].Opened = true;

        local Data = self.Treasures[_Index];

        if Data.Type == Treasure.Type.Resource then
            self:OpenResourceTreasure(_Index, _PlayerID);
        elseif Data.Type == Treasure.Type.RandomResource then
            self:OpenRandomResourceTreasure(_Index, _PlayerID);
        elseif Data.Type == Treasure.Type.Technology then
            self:OpenTechnologyTreasure(_Index, _PlayerID);
        elseif Data.Type == Treasure.Type.Custom then
            self:OpenCustomTreasure(_Index, _PlayerID);
        end

        if Data.SwapType then
            ReplaceEntity(Data.ScriptName, Data.SwapType);
        end
    end
end

function Treasure.Internal:OpenResourceTreasure(_Index, _PlayerID)
    if self.Treasures[_Index] then
        local Data = self.Treasures[_Index];
        if _PlayerID == GUI.GetPlayerID() then
            local ResType = KeyOf(Data.Resource, ResourceType);
            local Text = XGUIEng.GetStringTableText("Support/ChestGold2a");
            local Name = XGUIEng.GetStringTableText("WindowStatistics/Info" ..ResType);
            Sound.PlayGUISound(Sounds.VoicesMentor_CHEST_FoundTreasureChest_rnd_01, 70);
            Message(Text .. Data.Amount .. " " .. Name);
        end
        Logic.AddToPlayersGlobalResource(_PlayerID, Data.Resource, Data.Amount);
    end
end

function Treasure.Internal:OpenRandomResourceTreasure(_Index, _PlayerID)
    if self.Treasures[_Index] then
        local Data = self.Treasures[_Index];
        local ResourceList = {"Gold", "Clay", "Wood", "Stone", "Iron", "Sulfur"};
        local Index = math.random(1, 6);
        local Resource = ResourceType[Index];
        local Amount = math.random(Data.Minimum, Data.Maximum);
        if _PlayerID == GUI.GetPlayerID() then
            local Text = XGUIEng.GetStringTableText("Support/ChestGold2a");
            local Name = XGUIEng.GetStringTableText("WindowStatistics/Info" ..ResourceList[Index]);
            Sound.PlayGUISound(Sounds.VoicesMentor_CHEST_FoundTreasureChest_rnd_01, 70);
            Message(Text .. Amount .. " " .. Name);
        end
        Logic.AddToPlayersGlobalResource(_PlayerID, Resource, Amount);
    end
end

function Treasure.Internal:OpenTechnologyTreasure(_Index, _PlayerID)
    if self.Treasures[_Index] then
        local Data = self.Treasures[_Index];
        if Logic.IsTechnologyResearched(_PlayerID, Data.Technology) == 0 then
            ResearchTechnology(Data.Technology, _PlayerID);
            if _PlayerID == GUI.GetPlayerID() then
                local TechType = KeyOf(Data.Technology, Technologies);
                local TechName = XGUIEng.GetStringTableText("Names/" ..TechType);
                local Text = XGUIEng.GetStringTableText("VoicesMentor/RESEARCH_ResearchReady_rnd_07");
                Sound.PlayGUISound(Sounds.VoicesMentor_CHEST_FoundTreasureChest_rnd_01, 70);
                Message(Text .. " " .. TechName .. "!");
            end
        else
            if _PlayerID == GUI.GetPlayerID() then
                Message(XGUIEng.GetStringTableText("Support/ChestRandomEmpty"));
            end
        end
    end
end

function Treasure.Internal:OpenCustomTreasure(_Index, _PlayerID)
    if self.Treasures[_Index] then
        assert(self.Treasures[_Index].Callback);
        self.Treasures[_Index]:Callback(_PlayerID);
    end
end

-- Checks if an opener is close to the treasure and returns the player ID of
-- the entity. If no opener is in range than 0 is returned.
function Treasure.Internal:GetOpeningPlayer(_Index)
    if self.Treasures[_Index] then
        local Data = self.Treasures[_Index];
        if Data.Opener == Treasure.Opener.Hero then
            return self:IsHeroOpenerClose(Data);
        elseif Data.Opener == Treasure.Opener.Military then
            return self:IsMilitaryOpenerClose(Data);
        elseif Data.Opener == Treasure.Opener.Settler then
            return self:IsAnyOpenerClose(Data);
        elseif Data.Opener == Treasure.Opener.ScriptName then
            return self:IsNamedOpenerClose(Data);
        end
    end
    return 0;
end

function Treasure.Internal:IsHeroOpenerClose(_Data)
    local x,y,z = Logic.EntityGetPos(GetID(_Data.ScriptName));
    for i= 1, table.getn(Score.Player) do
        if Logic.IsPlayerEntityOfCategoryInArea(i, x, y, _Data.Distance, "Hero") == 1 then
            return i;
        end
    end
    return 0;
end

function Treasure.Internal:IsMilitaryOpenerClose(_Data)
    local x,y,z = Logic.EntityGetPos(GetID(_Data.ScriptName));
    for i= 1, table.getn(Score.Player) do
        if Logic.IsPlayerEntityOfCategoryInArea(i, x, y, _Data.Distance, "Military") == 1 then
            return i;
        end
    end
    return 0;
end

function Treasure.Internal:IsNamedOpenerClose(_Data)
    local x,y,z = Logic.EntityGetPos(GetID(_Data.ScriptName));
    for i= 1, table.getn(_Data.OpenerList) do
        if IsNear(_Data.ScriptName, _Data.OpenerList[i], _Data.Distance) then
            return Logic.EntityGetPlayer(GetID(_Data.OpenerList[i]));
        end
    end
    return 0;
end

function Treasure.Internal:IsAnyOpenerClose(_Data)
    local x,y,z = Logic.EntityGetPos(GetID(_Data.ScriptName));
    for i= 1, table.getn(Score.Player) do
        local PlayerEntities = {Logic.GetPlayerEntitiesInArea(i, 0, x, y, _Data.Distance, 16)};
        for j= 2, PlayerEntities[1] +1 do
            if Logic.IsSettler(PlayerEntities[j]) == 1 then
                return i;
            end
        end
    end
    return 0;
end

