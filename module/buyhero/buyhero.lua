---
--- Buy Hero
---
--- Changes the hero menu. Each hero can now have a description.
--- Special abilities can be indicated there.
---
--- Required:
--- * GetHeadquarters
--- * Syncer
---
--- @require Syncer
--- @author totalwarANGEL
--- @version 1.0.0
---

BuyHero = {}

-- -------------------------------------------------------------------------- --
-- API

--- Installs the hero window.
--- (Must be called on game start!)
function BuyHero.Install()
    BuyHero.Internal:Install();
end

--- Returns the amount of heroes the player can select.
--- @param _PlayerID number ID of player
--- @return number Amount Number of heroes
function BuyHero.GetNumberOfBuyableHeroes(_PlayerID)
    return BuyHero.Internal:GetNumberOfBuyableHeroes(_PlayerID);
end

--- Sets the amount of heroes the player can select.
--- @param _PlayerID number ID of player
--- @param _Amount number   Amount of heroes
function BuyHero.SetNumberOfBuyableHeroes(_PlayerID, _Amount)
    BuyHero.Internal:SetNumberOfBuyableHeroes(_PlayerID, _Amount);
end

--- Marks a hero as allowed or forbidden for all players.
--- @param _Type number     Type of hero
--- @param _Allowed boolean Hero is allowed
function BuyHero.AllowHero(_Type, _Allowed)
    BuyHero.Internal:AllowHero(_Type, _Allowed);
end

-- -------------------------------------------------------------------------- --
-- Game Callback

--- Called when the player has selected a hero.
---
--- Per default the name is build by the player ID and a ongoing number.
--- (e.g. "P1Hero5")
---
--- @param _PlayerID number ID of player
--- @param _ID number       ID of entity
--- @param _Type number     Type of entity
function GameCallback_Logic_BuyHero_OnHeroSelected(_PlayerID, _ID, _Type)
    local HeroCount = BuyHero.Internal:CountHeroes(_PlayerID);
    local ScriptName = "P" .._PlayerID.. "Hero" ..HeroCount;
    Logic.SetEntityName(_ID, ScriptName);
end

--- Prints the headline of the buy hero window.
--- @param _PlayerID any
--- @return string Headline Headline of window
function GameCallback_GUI_BuyHero_GetHeadline(_PlayerID)
    local HeroCount = BuyHero.Internal:CountHeroes(_PlayerID);
    local HeroesToBuy = BuyHero.Internal:GetNumberOfBuyableHeroes(_PlayerID) - HeroCount;
    local Caption = "Die Helden wurden gewählt!";
    if HeroesToBuy > 0 then
        Caption = "Wählt " ..HeroesToBuy.. " Helden!";
    end
    return Caption;
end

--- Prints the tooltip text for the hero in the buy hero window.
--- @param _PlayerID number ID of player
--- @param _Type number     Type of hero
--- @return string Text     Description
function GameCallback_GUI_BuyHero_GetMessage(_PlayerID, _Type)
    local TypeName = Logic.GetEntityTypeName(_Type);
    local Text = "%s @cr @cr Wählt %s als Euren Helden.";
    local Name = XGUIEng.GetStringTableText("Names/" ..TypeName);
    return string.format(Text, string.upper(Name), Name);
end

-- -------------------------------------------------------------------------- --
-- Internal

BuyHero.Internal = {
    Data = {},
    Config = {
        MaxHeroAmount = 1,

        TypesAllowedToChoose = {
            {Entities.PU_Hero1c,             true},
            {Entities.PU_Hero2,              true},
            {Entities.PU_Hero3,              true},
            {Entities.PU_Hero4,              true},
            {Entities.PU_Hero5,              true},
            {Entities.PU_Hero6,              true},
            {Entities.CU_BlackKnight,        true},
            {Entities.CU_Mary_de_Mortfichet, true},
            {Entities.CU_Barbarian_Hero,     true},
            {Entities.PU_Hero10,             true},
            {Entities.PU_Hero11,             true},
            {Entities.CU_Evil_Queen,         true},
        },
        TypeToBuyHeroButton = {
            [Entities.PU_Hero1c]             = "BuyHeroWindowBuyHero1",
            [Entities.PU_Hero2]              = "BuyHeroWindowBuyHero5",
            [Entities.PU_Hero3]              = "BuyHeroWindowBuyHero4",
            [Entities.PU_Hero4]              = "BuyHeroWindowBuyHero3",
            [Entities.PU_Hero5]              = "BuyHeroWindowBuyHero2",
            [Entities.PU_Hero6]              = "BuyHeroWindowBuyHero6",
            [Entities.CU_Mary_de_Mortfichet] = "BuyHeroWindowBuyHero7",
            [Entities.CU_BlackKnight]        = "BuyHeroWindowBuyHero8",
            [Entities.CU_Barbarian_Hero]     = "BuyHeroWindowBuyHero9",
            [Entities.PU_Hero10]             = "BuyHeroWindowBuyHero10",
            [Entities.PU_Hero11]             = "BuyHeroWindowBuyHero11",
            [Entities.CU_Evil_Queen]         = "BuyHeroWindowBuyHero12",
        },
    }
};

function BuyHero.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        self.SyncEvent = Syncer.CreateEvent(function(_PlayerID, _Type)
            BuyHero.Internal:BuyHeroCallback(_PlayerID, _Type);
        end);
        for i= 1, table.getn(Score.Player) do
            self.Data[i] = {
                MaxHeroAmount = self.Config.MaxHeroAmount,
            };
        end
        self:OverrideBuyHeroWindow();
        self:PrepareBuyHeroWindowForLordSelection();
    end
end

function BuyHero.Internal:OverrideBuyHeroWindow()
    BuyHeroWindow_Action_BuyHero = function(_Type)
        BuyHero.Internal:BuyHeroWindowClicked(_Type);
    end

    BuyHeroWindow_Update_BuyHero = function(_Type)
        BuyHero.Internal:BuyHeroWindowUpdateButton(_Type);
    end

    BuyHeroWindow_UpdateInfoLine = function()
        BuyHero.Internal:BuyHeroWindowUpdateDescription();
    end
end

function BuyHero.Internal:PrepareBuyHeroWindowForLordSelection()
    XGUIEng.SetText("BuyHeroWindowHeadline", "");
    XGUIEng.SetText("BuyHeroWindowInfoLine", "");
    XGUIEng.SetWidgetPositionAndSize("BuyHeroWindowInfoLine", 340, 60, 480, 50);
    XGUIEng.ShowAllSubWidgets("BuyHeroLine1", 0);

    local PositionX = 20;
    local PositionY = 20;
    XGUIEng.SetWidgetPosition("BuyHeroLine1", 40, 40);

    for i= 1, table.getn(self.Config.TypesAllowedToChoose) do
        local Type = self.Config.TypesAllowedToChoose[i][1];
        local WidgetID = self.Config.TypeToBuyHeroButton[Type];
        local ButtonW, ButtonH = 60, 90;
        XGUIEng.ShowWidget(WidgetID, 1);
        XGUIEng.SetWidgetPositionAndSize(WidgetID, PositionX, PositionY, ButtonW, ButtonH);
        PositionX = PositionX + 65;
        if math.mod(i, 4) == 0 then
            PositionY = PositionY + 95;
            PositionX = 20;
        end
    end
end

function BuyHero.Internal:BuyHeroCallback(_PlayerID, _Type)
    if self.Data[_PlayerID] then
        local CastleID = GetHeadquarters(_PlayerID);
        if CastleID == 0 then
            return;
        end

        local Orientation = Logic.GetEntityOrientation(CastleID);
        local Position = GetCirclePosition(CastleID, 800, 180);
        ID = Logic.CreateEntity(_Type, Position.X, Position.Y, 0, _PlayerID);
        Logic.RotateEntity(ID, Orientation +180);
        GameCallback_Logic_BuyHero_OnHeroSelected(_PlayerID, ID, _Type);
    end
end

function BuyHero.Internal:BuyHeroWindowUpdateDescription()
    -- Get active player
    local EntityID = GUI.GetSelectedEntity();
    local SelectedPlayer = Logic.EntityGetPlayer(EntityID);
    local GuiPlayer = GUI.GetPlayerID();
    local PlayerID = (SelectedPlayer ~= 0 and SelectedPlayer) or GuiPlayer;

    -- Get screen coordinates
    local ScreenX, ScreenY = GUI.GetScreenSize();
    local MouseX, MouseY = GUI.GetMousePosition();
    MouseX = MouseX * (1024/ScreenX);
    MouseY = MouseY * (768/ScreenY);
    local RowX, RowY = 122, 155;
    local ButtonW, ButtonH = 65, 90;

    -- Set headline text
    local Caption = GameCallback_GUI_BuyHero_GetHeadline(PlayerID);
    XGUIEng.SetText("BuyHeroWindowHeadline", Caption);

    -- Position message and set text
    local Text = "";
    for i= 1, table.getn(self.Config.TypesAllowedToChoose) do
        local Type = self.Config.TypesAllowedToChoose[i][1];
        local ButtonStartX = (RowX + (ButtonW * (math.mod(i-1, 4))));
        local ButtonEndX = ButtonStartX + ButtonW;
        local ButtonStartY = RowY;
        local ButtonEndY = RowY + ButtonH;

        local WidgetName = self.Config.TypeToBuyHeroButton[Type];
        if XGUIEng.IsWidgetShown(WidgetName) == 1 then
            if (MouseX >= ButtonStartX and MouseX <= ButtonEndX) and (MouseY >= ButtonStartY and MouseY <= ButtonEndY) then
                Text = GameCallback_GUI_BuyHero_GetMessage(PlayerID, Type);
            end
        end

        if math.mod(i, 4) == 0 then
            RowY = RowY + 95;
            RowX = 122;
        end
    end
    XGUIEng.SetText("BuyHeroWindowInfoLine", Text);
end

function BuyHero.Internal:BuyHeroWindowClicked(_Type)
    local PlayerID = GUI.GetPlayerID();
    -- Spectator can not pick
    if PlayerID == 17 then
        return;
    end
    -- Check can still pick hero
    local HeroCount = self:CountHeroes(PlayerID);
    local HeroesToBuy = self:GetNumberOfBuyableHeroes(PlayerID) - HeroCount;
    if HeroesToBuy < 1 then
        return;
    end
    for k,v in pairs(self:GetHeroes(PlayerID)) do
        if Logic.GetEntityType(v) == _Type then
            return;
        end
    end
    -- Send event
    Syncer.InvokeEvent(self.SyncEvent, PlayerID, _Type);
    XGUIEng.ShowWidget("BuyHeroWindow", 0);
end

function BuyHero.Internal:BuyHeroWindowUpdateButton(_Type)
    -- Get active player
    local EntityID = GUI.GetSelectedEntity();
    local SelectedPlayer = Logic.EntityGetPlayer(EntityID);
    local GuiPlayer = GUI.GetPlayerID();
    local PlayerID = (SelectedPlayer ~= 0 and SelectedPlayer) or GuiPlayer;

    -- Update button
    local Button = self.Config.TypeToBuyHeroButton[_Type];
    local HeroCount = self:CountHeroes(PlayerID);
    local PickedHeroes = {};
    for k,v in pairs(self:GetHeroes(PlayerID)) do
        PickedHeroes[Logic.GetEntityType(v)] = true;
    end
    local IsDisabled = 0;
    if  self:GetNumberOfBuyableHeroes(PlayerID) - HeroCount < 1
    and not PickedHeroes[_Type] then
        IsDisabled = 1;
    end
    XGUIEng.DisableButton(Button, IsDisabled);
end

function BuyHero.Internal:AllowHero(_Type, _Allowed)
    for i= 1, table.getn(self.Config.TypesAllowedToChoose) do
        if self.Config.TypesAllowedToChoose[i][1] == _Type then
            self.Config.TypesAllowedToChoose[i][2] = _Allowed == true;
        end
    end
end

function BuyHero.Internal:SetNumberOfBuyableHeroes(_PlayerID, _Amount)
    if self.Data[_PlayerID] then
        self.Data[_PlayerID].MaxHeroAmount = _Amount;
    end
end

function BuyHero.Internal:GetNumberOfBuyableHeroes(_PlayerID)
    if self.Data[_PlayerID] then
        return self.Data[_PlayerID].MaxHeroAmount;
    end
    return 0;
end

function BuyHero.Internal:CountHeroes(_PlayerID)
    return table.getn(self:GetHeroes(_PlayerID));
end

function BuyHero.Internal:GetHeroes(_PlayerID)
    local HeroList = {};
    Logic.GetHeroes(_PlayerID, HeroList);
    return HeroList;
end

