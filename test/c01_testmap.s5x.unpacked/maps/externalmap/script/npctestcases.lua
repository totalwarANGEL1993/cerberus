function InitTestNpc()
    NonPlayerCharacter.Create {
        ScriptName  = "liam",
        Player      = 1,
        Callback    = function()
            Message("It just work's!");
        end
    }
    NonPlayerCharacter.Activate("liam");
end

