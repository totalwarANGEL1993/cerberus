function InitDiplomacyTrigger()
    Job.Diplomacy(function()
        local PlayerID1 = Event.GetSourcePlayerID();
        local PlayerID2 = Event.GetTargetPlayerID();
        local DiplomacyState = Event.GetDiplomacyState();
        Message(PlayerID1);
        Message(PlayerID2);
        Message(DiplomacyState);
    end)
end

