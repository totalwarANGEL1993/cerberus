function InitNpcTestQuest()
    CreateQuest {
        Name        = "NpcTestQuest",
        Receiver    = 2,

        {{Condition.Time, 15}},
        {{Objective.NPC, "liam"}},
        {},
        {{Effect.Message, "It just work's!"}},
    }
end

