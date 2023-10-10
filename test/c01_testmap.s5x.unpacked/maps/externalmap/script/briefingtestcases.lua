
--- Use case: Single briefing
function TestCaseSingleBriefing()
    TestNormalBriefing1();
end

--- Use case: single briefing with choice
function TestCaseSingleMCBriefing()
    TestMCBriefing1();
end

--- Use case: Single briefing with fader
function TestCaseSingleFaderBriefing()
    TestFaderBriefing1();
end

--- Use case: Single briefing with fader and MC
function TestCaseSingleMCFaderBriefing()
    TestMCBriefing2();
end

--- Use case: 2 briefings after another
function TestCaseFollowupBriefing()
    TestNormalBriefing1();
    TestNormalBriefing2();
end

--- Use case: 2 briefings, 2nd using fader
function TestCaseFollowupFaderBriefing()
    TestNormalBriefing1();
    TestFaderBriefing1();
end

--- Use case: 2 briefings, 2nd using MC
function TestCaseFollowupMCBriefing()
    TestNormalBriefing1();
    TestMCBriefing1();
end

-- -------------------------------------------------------------------------- --

function TestNormalBriefing1()
    local Briefing = {};
    local AP, ASP = BriefingSystem.AddPages(Briefing);

    ASP("ari", "Title 1", "This is a test.", true);
    ASP("ari", "Title 2", "This is a test.", true);

    Briefing.Finished = function()
    end
    BriefingSystem.Start(1, "TestBriefing1", Briefing);
end

function TestNormalBriefing2()
    local Briefing = {};
    local AP, ASP = BriefingSystem.AddPages(Briefing);

    ASP("ari", "Title 1", "This is a test.", true);
    ASP("ari", "Title 2", "This is a test.", true);

    Briefing.Finished = function()
    end
    BriefingSystem.Start(1, "TestBriefing2", Briefing);
end

function TestFaderBriefing1()
    local Briefing = {};
    local AP, ASP = BriefingSystem.AddPages(Briefing);

    AP {
        Target   = "ari",
        FadeIn   = 3,
        Duration = 3,
        CloseUp  = true,
    }
    ASP("ari", "Title 1", "This is a test.", true);
    ASP("ari", "Title 2", "This is a test.", true);
    AP {
        Target   = "ari",
        FadeOut  = 3,
        Duration = 3,
        CloseUp  = true,
    }

    Briefing.Finished = function()
    end
    BriefingSystem.Start(1, "TestFaderBriefing1", Briefing);
end

function TestMCBriefing1()
    local Briefing = {};
    local AP, ASP = BriefingSystem.AddPages(Briefing);

    AP {
        Name    = "C2O2",
        Title   = "Choice 1",
        Text    = "This is a choise. Be wise...",
        Target  = "ari",
        CloseUp  = true,
        MC      = {
            {"Option 1", "C1O1"},
            {"Option 2", "C1O2"},
        }
    }

    ASP("C1O1", "ari", "Title 1", "This is a test.", true);
    ASP("ari", "Title 2", "This is a test.", true);
    AP();

    AP {
        Name    = "C1O2",
        Title   = "Choice 2",
        Text    = "This is a choise. Be wise...",
        Target  = "ari",
        CloseUp  = true,
        MC      = {
            {"Option 1", "C2O1"},
            {"Option 2", "C2O2"},
        }
    }

    ASP("C2O1", "ari", "Title 3", "This is a test.", true);
    ASP("ari", "Title 4", "This is a test.", true);

    Briefing.Finished = function()
    end
    BriefingSystem.Start(1, "TestMCBriefing1", Briefing);
end

function TestMCBriefing2()
    local Briefing = {};
    local AP, ASP = BriefingSystem.AddPages(Briefing);

    AP {
        Name     = "C2O2",
        Target   = "ari",
        FadeIn   = 3,
        Duration = 3,
    }
    AP {
        Title   = "Choice 1",
        Text    = "This is a choise. Be wise...",
        Target  = "ari",
        CloseUp  = true,
        MC      = {
            {"Option 1", "C1O1"},
            {"Option 2", "C1O2"},
        }
    }

    ASP("C1O1", "ari", "Title 1", "This is a test.", true);
    ASP("ari", "Title 2", "This is a test.", true);
    AP();

    AP {
        Name    = "C1O2",
        Title   = "Choice 2",
        Text    = "This is a choise. Be wise...",
        Target  = "ari",
        CloseUp  = true,
        MC      = {
            {"Option 1", "C2O1"},
            {"Option 2", "C2O2"},
        }
    }

    ASP("C2O1", "ari", "Title 3", "This is a test.", true);
    ASP("ari", "Title 4", "This is a test.", true);
    AP {
        Target   = "ari",
        CloseUp  = true,
        FadeOut  = 3,
        Duration = 3,
    }

    Briefing.Finished = function()
    end
    BriefingSystem.Start(1, "TestMCBriefing2", Briefing);
end

