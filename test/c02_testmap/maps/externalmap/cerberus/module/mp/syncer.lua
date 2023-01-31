Lib.Require("comfort/CopyTable");
Lib.Register("module/mp/Syncer");

--- 
--- Synchronizer script
--- 
--- This script provides synchronized calls for Multiplayer.
--- 
--- If the map is played in Singleplayer then each call is executed directly.
--- 
--- If played in Multiplayer the script automatically reconizes the community
--- server and uses its API. If the server methods are not defined the script
--- uses tributes and messages for synchronization.
--- 
--- @author totalwarANGEL
--- @version 1.0.0
---

Syncer = Syncer or {};

-- -------------------------------------------------------------------------- --
-- API

--- Installs the syncer.
---
--- (Must be called on game start!)
--- @param _TributeIdSequence number (Optional) Starting value for tribute IDs
function Syncer.Install(_TributeIdSequence)
    Syncer.Internal:Install(_TributeIdSequence);
end

--- Creates an script event and returns the event ID.
---
--- (The ID is used to call the event.)
--- @param _Function any
--- @return integer
function Syncer.CreateEvent(_Function)
    return Syncer.Internal:CreateSyncEvent(_Function);
end

--- Removes an script event.
--- @param _ID number ID of event
function Syncer.DeleteEvent(_ID)
    Syncer.Internal:DeleteSyncEvent(_ID);
end

--- Calls the script event synchronous for all players.
--- @param _ID number ID of event
--- @param ... any List of parameters for the event
function Syncer.InvokeEvent(_ID, ...)
    Syncer.Internal:Call(_ID, unpack(arg));
end

--- Returns the player ID of the host.
--- @return number PlayerID ID of host player
function Syncer.GetHostPlayerID()
    return Syncer.Internal:GetHostPlayerID();
end

--- Returns the number of human players.
---
--- (In Singleplayer this will always be 1!)
--- @return table PlayerList List of players
function Syncer.GetActivePlayers()
    return Syncer.Internal:GetActivePlayers();
end

--- Returns all active teams.
--- @return table Teams List of playing teams
function Syncer.GetActiveTeams()
    return Syncer.Internal:GetActiveTeams();
end

--- Returns the team the player is in.
--- @param _PlayerID number ID of the player
--- @return number ID Team ID of player
function Syncer.GetTeamOfPlayer(_PlayerID)
    return Syncer.Internal:GetTeamOfPlayer(_PlayerID);
end

--- Checks if the current mission is running as a Multiplayer game.
--- @return boolean IsMultiplayer Game is multiplayer game
function Syncer.IsMultiplayer()
    return Syncer.Internal:IsMultiplayerGame();
end

--- Returns if the copy of the game is the History Edition.
--- @return boolean HistoryEdition Game is History Edition
function Syncer.IsHistoryEdition()
    return XNetwork.Manager_IsNATReady ~= nil;
end

--- Returns if the game runs on the community server.
--- @return boolean CommunityServer Game runs on community server 
function Syncer.IsCommunityServer()
    return CMod ~= nil;
end

--- Returns if the game is the original game.
--- @return boolean OriginalGame Game is original
function Syncer.IsVanilla()
    return XNetwork.Manager_IsNATReady == nil and CMod == nil;
end

-- -------------------------------------------------------------------------- --
-- Internal

Syncer.Internal = Syncer.Internal or {
    Data = {},
    Transaction = {
        TributeIdSequence = 0,
        Transactions = {},
        TransactionParameter = {},
        UniqueActionCounter = 1,
    },
};

function Syncer.Internal:Install(_TributeIdSequence)
    if not self.IsInstalled then
        self.Transaction.TributeIdSequence = _TributeIdSequence or 999;
        self.IsInstalled = true;

        if XNetwork.Manager_DoesExist() == 1 and not CNetwork then
            if not EMS then
                self:OverrideMessageReceived();
                self:ActivateTributePaidTrigger();
            end
        end
    end
end

function Syncer.Internal:CreateSyncEvent(_Function)
    self.Transaction.UniqueActionCounter = self.Transaction.UniqueActionCounter +1;
    local ActionIndex = self.Transaction.UniqueActionCounter;

    self.Data[ActionIndex] = {
        Function   = _Function,
        CNetwork   = "Syncer_CNetworkHandler_" .. self.Transaction.UniqueActionCounter,
        EMSHandler = "Syncer_EMS_Handler_" .. self.Transaction.UniqueActionCounter,
    };

    -- Network handler for community server
    if CNetwork then
        local NetworkHandler = function(name, _ID, _PlayerID, ...)
            if CNetwork.IsAllowedToManipulatePlayer(name, _PlayerID) then
                Syncer.Internal.Data[_ID].Function(_PlayerID, unpack(arg));
            end
        end
        CNetwork.SetNetworkHandler(
            self.Data[ActionIndex].CNetwork,
            NetworkHandler
        );
    end
    -- Network handler for EMS
    if not CNetwork and EMS then
        _G[self.Data[ActionIndex].EMSHandler] = function(_ID, _PlayerID, ...)
            Syncer.Internal.Data[_ID].Function(_PlayerID, unpack(arg));
        end
    end
    return self.Transaction.UniqueActionCounter;
end

function Syncer.Internal:DeleteSyncEvent(_ID)
    if _ID and self.Data[_ID] then
        self.Data[_ID] = nil;
    end
end

function Syncer.Internal:Call(_ID, ...)
    arg = arg or {};
    if XNetwork.Manager_DoesExist() == 1 then
        -- Use CNetwork on community server
        if CNetwork then
            local Name = self.Data[_ID].CNetwork;
            CNetwork.SendCommand(Name, _ID, GUI.GetPlayerID(), unpack(arg));
        -- Use EMS syncer if not CNetwork
        elseif not CNetwork and EMS then
            local Name = self.Data[_ID].EMSHandler;
            Sync.Call(Name, _ID, GUI.GetPlayerID(), unpack(arg));
        -- Use tributes and messages
        else
            local PlayerID = GUI.GetPlayerID();
            local Time = Logic.GetTimeMs();
            local Msg = "";
            if table.getn(arg) > 0 then
                for i= 1, table.getn(arg), 1 do
                    Msg = Msg .. tostring(arg[i]) .. ":::";
                end
            end
            self:TransactionSend(_ID, PlayerID, Time, Msg, arg);
        end
        return;
    end
    self.Data[_ID].Function(GUI.GetPlayerID(), unpack(arg));
end

function Syncer.Internal:IsMultiplayerGame()
    return XNetwork.Manager_DoesExist() == 1;
end

function Syncer.Internal:GetHostPlayerID()
    if self:IsMultiplayerGame() then
        for k, v in pairs(self:GetActivePlayers()) do
            local HostNetworkAddress   = XNetwork.Host_UserInSession_GetHostNetworkAddress();
            local PlayerNetworkAddress = XNetwork.GameInformation_GetNetworkAddressByPlayerID(v);
            if HostNetworkAddress == PlayerNetworkAddress then
                return v;
            end
        end
        return 0;
    end
    return GUI.GetPlayerID();
end

function Syncer.Internal:GetActivePlayers()
    local Players = {};
    if self:IsMultiplayerGame() then
        for i= 1, table.getn(Score.Player), 1 do
            if Logic.PlayerGetGameState(i) == 1 then
                table.insert(Players, i);
            end
        end
    else
        table.insert(Players, GUI.GetPlayerID());
    end
    return Players;
end

function Syncer.Internal:GetActiveTeams()
    if self:IsMultiplayerGame() then
        local Teams = {};
        for k, v in pairs(self:GetActivePlayers()) do
            local Team = self:GetTeamOfPlayer(v);
            if not IsInTable(Team, Teams) then
                table.insert(Teams, Team);
            end
        end
        return Teams;
    end
    return {1};
end

function Syncer.Internal:GetTeamOfPlayer(_PlayerID)
    if self:IsMultiplayerGame() then
        return XNetwork.GameInformation_GetPlayerTeam(_PlayerID);
    end
    return _PlayerID;
end

-- -------------------------------------------------------------------------- --
-- Traditional Synchronization
-- From here on out the traditional method for synchronization is implemented.
-- (It's currently not compatiple to EMS.)
-- This will NOT be used on the community server!

function Syncer.Internal:ActivateTributePaidTrigger()
    Trigger.RequestTrigger(
        Events.LOGIC_EVENT_TRIBUTE_PAID,
        nil,
        "Syncer_Trigger_OnTributePaid",
        1
    );
end

function Syncer.Internal:ActivateEveryTurnTrigger(_PlayerID, _ID, _Hash, _Time, ...)
    Trigger.RequestTrigger(
        Events.LOGIC_EVENT_EVERY_TURN,
        nil,
        "Syncer_Trigger_OnEveryTurn",
        1,
        {},
        {_PlayerID, _ID, _Hash, Logic.GetTime(), unpack(arg)}
    );
end

function Syncer.Internal:TransactionSend(_ID, _PlayerID, _Time, _Msg, _Parameter)
    -- Create message
    _Msg = _Msg or "";
    local PreHashedMsg = "".._ID..":::" .._PlayerID..":::" .._Time.. ":::" .._Msg;
    local Hash = _ID.. "_" .._PlayerID.. "_" .._Time;
    local TransMsg = "___MPTransact:::"..Hash..":::" ..PreHashedMsg;
    self.Transaction.Transactions[Hash] = {};
    -- Send message
    if self:IsMultiplayerGame() then
        XNetwork.Chat_SendMessageToAll(TransMsg);
    else
        MPGame_ApplicationCallback_ReceivedChatMessage(TransMsg, 0, _PlayerID);
    end
    -- Wait for ack
    self:ActivateEveryTurnTrigger(_PlayerID, _ID, Hash, Logic.GetTime(), unpack(_Parameter));
end

function Syncer.Internal:TransactionAcknowledge(_Hash, _Time)
    -- Create message
    local PlayerID = GUI.GetPlayerID();
    local TransMsg = "___MPAcknowledge:::" .._Hash.. ":::" ..PlayerID.. ":::" .._Time.. ":::";
    -- Send message
    if self:IsMultiplayerGame() then
        XNetwork.Chat_SendMessageToAll(TransMsg);
    else
        MPGame_ApplicationCallback_ReceivedChatMessage(TransMsg, 0, PlayerID);
    end
end

function Syncer.Internal:TransactionManage(_Type, _Msg)
    -- Handle received request
    if _Type == 1 then
        local Parameters      = self:TransactionSplitMessage(_Msg);
        local Hash            = table.remove(Parameters, 1);
        local Action          = table.remove(Parameters, 1);
        local SendingPlayerID = table.remove(Parameters, 1);
        local Timestamp       = table.remove(Parameters, 1);
        if SendingPlayerID ~= GUI.GetPlayerID() then
            self:TransactionAcknowledge(Hash, Timestamp);
            Syncer.Internal:CreateTribute(SendingPlayerID, Action, unpack(Parameters));
        end
    -- Handle received client ack
    elseif _Type == 2 then
        local Parameters = self:TransactionSplitMessage(_Msg);
        local Hash       = table.remove(Parameters, 1);
        local PlayerID   = table.remove(Parameters, 1);
        local Timestamp  = table.remove(Parameters, 1);
        self.Transaction.Transactions[Hash] = self.Transaction.Transactions[Hash] or {};
        self.Transaction.Transactions[Hash][PlayerID] = true;
    end
end

function Syncer.Internal:TransactionSplitMessage(_Msg)
    local MsgParts = {};
    local Msg = _Msg;
    repeat
        local s, e = string.find(Msg, ":::");
        local PartString = string.sub(Msg, 1, s-1);
        local PartNumber = tonumber(PartString);
        local Part = (PartNumber ~= nil and PartNumber) or PartString;
        table.insert(MsgParts, Part);
        Msg = string.sub(Msg, e+1);
    until Msg == "";
    return MsgParts;
end

function Syncer.Internal:CreateTribute(_PlayerID, _ID, ...)
    self.Transaction.TributeIdSequence = self.Transaction.TributeIdSequence +1;
    Logic.AddTribute(_PlayerID, self.Transaction.TributeIdSequence, 0, 0, "", {[ResourceType.Gold] = 0});
    self.Transaction.TransactionParameter[self.Transaction.TributeIdSequence] = {
        Action    = _ID,
        Parameter = CopyTable(arg),
    };
    return self.Transaction.TributeIdSequence;
end

function Syncer.Internal:PayTribute(_PlayerID, _TributeID)
    GUI.PayTribute(_PlayerID, _TributeID);
end

function Syncer.Internal:OverrideMessageReceived()
    if self.IsActive then
        return true;
    end
    self.IsActive = true;

    self.Orig_MPGame_ApplicationCallback_ReceivedChatMessage = MPGame_ApplicationCallback_ReceivedChatMessage
    MPGame_ApplicationCallback_ReceivedChatMessage = function(_Message, _AlliedOnly, _SenderPlayerID)
        -- Receive transaction
        local s, e = string.find(_Message, "___MPTransact:::");
        if e then
            Syncer.Internal:TransactionManage(1, string.sub(_Message, e+1));
            return;
        end
        -- Receive ack
        s, e = string.find(_Message, "___MPAcknowledge:::");
        if e then
            Syncer.Internal:TransactionManage(2, string.sub(_Message, e+1));
            return;
        end
        -- Execute callback
        Syncer.Internal.Orig_MPGame_ApplicationCallback_ReceivedChatMessage(_Message, _AlliedOnly, _SenderPlayerID);
    end
end

function Syncer.Internal:OnTributePaidTrigger(_ID)
    if self.Transaction.TransactionParameter[_ID] then
        local ActionID  = self.Transaction.TransactionParameter[_ID].Action;
        local Parameter = self.Transaction.TransactionParameter[_ID].Parameter;
        if self.Data[ActionID] then
            self.Data[ActionID].Function(unpack(Parameter));
        end
    end
end

function Syncer.Internal:OnAcknowlegementReceivedTrigger(_PlayerID, _ID, _Hash, _Time, ...)
    arg = arg or {};
    if _Time +2 < Logic.GetTime() then
        return true;
    end
    local Msg = table.remove(arg);
    local Parameter = {unpack(arg)};

    local ActivePlayers = Syncer.Internal:GetActivePlayers();
    local AllAcksReceived = true;
    for i= 1, table.getn(ActivePlayers), 1 do
        if _PlayerID ~= ActivePlayers[i] and not self.Transaction.Transactions[_Hash][ActivePlayers[i]] then
            AllAcksReceived = false;
        end
    end
    if AllAcksReceived == true then
        table.insert(Parameter, 1, -1);
        local ID = Syncer.Internal:CreateTribute(_PlayerID, _ID, unpack(Parameter));
        Syncer.Internal:PayTribute(_PlayerID, ID);
        return true;
    end
end

function Syncer_Trigger_OnEveryTurn(_PlayerID, _ID, _Hash, _Time, ...)
    Syncer.Internal:OnAcknowlegementReceivedTrigger(_PlayerID, _ID, _Hash, _Time, unpack(arg));
end

function Syncer_Trigger_OnTributePaid()
    Syncer.Internal:OnTributePaidTrigger(Event.GetTributeUniqueID());
end

