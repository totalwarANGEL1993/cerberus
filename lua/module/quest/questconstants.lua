Lib.Register("module/quest/QuestConstants");

--- 
--- Enums used by the quest system.
--- 
--- Version 1.0.0
--- 

--- Quest states used in the quest system.
---
--- The possible values are:
--- - `QuestState.Inactive`: The quest is inactive
--- - `QuestState.Active`: The quest is currently running
--- - `QuestState.Decided`: The outcome of the quest has been decided
--- - `QuestState.Done`: The quest is completed
---
--- @class QuestState
--- @field Inactive integer The quest is inactive
--- @field Active integer The quest is currently running
--- @field Decided integer The outcome of the quest has been decided
--- @field Done integer The quest is completed
QuestState = {
    Inactive = 1,
    Active = 2,
    Decided = 3,
    Done = 4,
};

--- Quest results used in the quest system.
---
--- The possible values are:
--- - `QuestResult.None`: The quest result was undecided
--- - `QuestResult.Success`: The quest ended in success
--- - `QuestResult.Failure`: The quest ended in failure
--- - `QuestResult.Interrupt`: The quest has been interrupted
---
--- @class QuestResult
--- @field None integer The quest result was undecided
--- @field Success integer The quest ended in success
--- @field Failure integer The quest ended in failure
--- @field Interrupt integer The quest has been interrupted
QuestResult = {
    None = 1,
    Success = 2,
    Failure = 3,
    Interrupt = 4
};

--- Technology states used in the game.
---
--- The possible values are:
--- - `TechnologyStates.Researched`: The technology is researched
--- - `TechnologyStates.Allowed`: The technology is allowed
--- - `TechnologyStates.Forbidden`: The technology is forbidden
---
--- @class TechnologyStates
--- @field Researched integer The technology is researched
--- @field Allowed integer The technology is allowed
--- @field Forbidden integer The technology is forbidden
TechnologyStates = {
    Researched = 3,
    Allowed    = 2,
    Forbidden  = 0
}

--- Marker types used in the game.
---
--- The possible values are:
--- - `MarkerTypes.StaticFriendly`: A static green marker
--- - `MarkerTypes.StaticNeutral`: A static white marker
--- - `MarkerTypes.StaticEnemy`: A static red marker
--- - `MarkerTypes.PulseFriendly`: A pulsating green marker
--- - `MarkerTypes.PulseNeutral`: A pulsating white marker
--- - `MarkerTypes.PulseEnemy`: A pulsating red marker
---
--- @class MarkerTypes
--- @field StaticFriendly integer A static green marker
--- @field StaticNeutral integer A static white marker
--- @field StaticEnemy integer A static red marker
--- @field PulseFriendly integer A pulsating green marker
--- @field PulseNeutral integer A pulsating white marker
--- @field PulseEnemy integer A pulsating red marker
MarkerTypes = {
    StaticFriendly = 1,
    StaticNeutral  = 2,
    StaticEnemy    = 3,
    PulseFriendly  = 4,
    PulseNeutral   = 5,
    PulseEnemy     = 6,
}

-- -------------------------------------------------------------------------- --
-- Conditions

--- Condition Types
--- 
--- * `Script` - Calls the script function with self reference and quest reference.
--- * `None` - Quest must be triggered explicitly.
--- * `Time` - Quest starts after X seconds after game start.
--- * `QuestState` - Quest starts when another quest reaches a state.
--- * `QuestResult` - Quest starts when another quest concludes with a result.
--- * `QuestAndQuestResult` - Starts the quest when both quests have the same result.
--- * `QuestOrQuestResult` - Starts the quest when one or both quests have the same result.
--- * `QuestXorQuestResult` - Starts the quest when one or the other quest but NOT both have the same result.
--- * `Briefing` - The player must have seen the briefing.
--- * `Diplomacy` - Starts the quest when a diplomatic state is reached.
--- * `Payday` - Starts the quest on the next payday of the receiver.
--- * `EntityDestroyed` - Starts the quest when an entity does not exist.
--- * `WeatherState` - Starts the quest when the weather changed to a weather state.
Condition = {
    --- Calls the script function with self reference and quest reference.
    --- 
    --- Parameter: FunctionName, Data
    --- 
    --- Return value meaning:
    --- * true   Quest starts
    --- * false  Nothing happens
    --- * nil    Nothing happens
    Script = 1,
    --- Quest must be triggered explicitly.
    None = 2,
    --- Quest starts after X seconds after game start.
    --- 
    --- Parameter: Time
    Time = 3,

    --- Quest starts when another quest reaches a state.
    ---
    --- Parameter: QuestName, QuestState
    QuestState = 10,
    --- Quest starts when another quest concludes with a result.
    --- 
    --- Parameter: QuestName, QuestResult
    QuestResult = 11,
    --- Starts the quest when both quest have the same result.
    --- 
    --- Parameter: QuestName1, QuestName2, QuestResult
    QuestAndQuestResult = 12,
    --- Starts the quest when one or both quest have the same result.
    --- 
    --- Parameter: QuestName1, QuestName2, QuestResult
    QuestOrQuestResult = 13,
    --- Starts the quest when one or the other quest but NOT both have the
    --- same result.
    --- 
    --- Parameter: QuestName1, QuestName2, QuestResult
    QuestXorQuestResult = 14,

    --- The player must have seen the briefing.
    --- 
    --- Parameter: Briefing
    Briefing = 20,
    --- Starts the quest when a diplomatic state is reached.
    --- 
    --- Parameter: PlayerID1, PlayerID2, DiplomacyState
    Diplomacy = 21,
    --- Starts the quest on the next payday of the receiver.
    Payday = 22,

    --- Starts the quest when a entity does not exist.
    --- 
    --- Parameter: ScriptName
    EntityDestroyed = 30,

    --- Starts the quest when the weather changed to a weather state.
    --- 
    --- Parameter: WeatherState
    WeatherState = 40,
};

-- -------------------------------------------------------------------------- --
-- Objective

--- Objective Types
--- 
--- * `Script` - Calls the script function with self reference and quest reference.
--- * `None` - Quest must be decided explicitly.
--- * `Failure` - The quest fails immediately.
--- * `Success` - The quest succeeds immediately.
--- * `NPC` - The player must talk to an NPC.
--- * `Destroy` - Destroy an entity or kill a hero.
--- * `Create` - Create units or buildings in area.
--- * `Protect` - An entity must be protected from being killed.
--- * `EntityDistance` - An entity must be near to a position on the map.
--- * `Headquarter` - Upgrade the headquarter.
--- * `DestroyType` - Destroy an amount of entities of type.
--- * `DestroyCategory` - Destroy an amount of entities in a category.
--- * `DestroyAllPlayerUnits` - All buildings and units of the player must be destroyed.
--- * `Bridge` - The player must build a bridge in the marked area.
--- * `Diplomacy` - Reach a diplomatic state with another player.
--- * `Produce` - Gain a amount of resources.
--- * `Workers` - Reach a number of workers in the settlement.
--- * `Motivation` - Reach a minimum amount of average motivation for the workers.
--- * `Units` - Create an amount of units.
--- * `Technology` - Research a technology.
--- * `Tribute` - Pay a tribute.
--- * `Settlers` - Reach an overall amount of settlers in the settlement.
--- * `Soldiers` - Reach a number of military units in the settlement.
--- * `WeatherState` - The weather must be changed.
--- * `Steal` - The receiver must steal the amount of the required resource.
--- * `Quest` - The player must complete the quest with the desired result.
Objective = {
    --- Calls the script function with self reference and quest reference.
    --- 
    --- Parameter: FunctionName, Data
    --- 
    --- Return value meaning:
    --- * true  -> Quest succeeds
    --- * false -> Quest fails
    --- * nil   -> Nothing happens
    Script = 1,
    --- Quest must be decided explicitly.
    None = 2,

    --- The quest fails immediately.
    Failure = 10,
    --- the quest succeeds immediately.
    Success = 11,

    --- The player must talk to an NPC.
    --- 
    --- Parameter: NPC [, Hero, WrongHeroMsg]
    NPC = 20,
    --- Destroy an entity or kill a hero.
    --- 
    --- Parameter: Target
    Destroy = 21,
    --- Create units or buildings in area.
    --- 
    --- Parameter: EntityType, Position, Range, Amount [, Marker [, ChangeOwner]]
    Create = 22,
    --- An entity must be protected from being killed.
    --- 
    --- Parameter: Target
    Protect = 23,
    --- A entity must be near to a position on the map.
    --- 
    --- Parameter: Entity, Target, Distance [, LowerThan]
    EntityDistance = 24,
    --- Upgrade the headquarter
    --- 
    --- Parameter: Upgrades
    Headquarter = 25,
    --- Destroy an amount of entities of type.
    --- 
    --- Parameter: PlayerID, Type, Amount
    DestroyType = 26,
    --- Destroy an amount of entities in a category.
    --- 
    --- Parameter: PlayerID, Category, Amount
    DestroyCategory = 27,
    --- All buildings and units of the player must be destroyed.
    --- 
    --- Parameter: PlayerID
    DestroyAllPlayerUnits = 51,
    --- The player must build a bridge in the marked area. Because bridges loose
    --- their script names often, use a XD_ScriptEntity instead of the site.
    --- 
    --- Parameter: AreaCenter, AreaSize
    Bridge = 26,

    --- Reach a diplomatic state to another player.
    --- 
    --- Parameter: PlayerID1, PlayerID2, State
    Diplomacy = 40,
    --- Gain a amount of resources.
    --- 
    --- Parameter: Resource, Amount [, WithoutRaw]
    Produce = 41,
    --- Reach a number of workers in the settlement.
    --- 
    --- Parameter: Amount, LowerThan [, OtherPlayer]
    Workers = 42,
    --- Reach a minimum amount of average motivation for the workers.
    --- 
    --- Parameter: Amount, LowerThan [, OtherPlayer]
    Motivation = 43,
    --- Create an amount of units.
    --- 
    --- Parameter: Type, Amount, LowerThan [, OtherPlayer]
    Units = 44,
    --- Research a technology.
    --- 
    --- Parameter: Technology
    Technology = 45,
    --- Pay a tribute.
    --- 
    --- Parameter: CostsTable, Message
    Tribute = 46,
    --- Reach an overall amount of settlers in the settlement.
    --- 
    --- Parameter: Amount, LowerThan, OtherPlayer
    Settlers = 47,
    --- Reach a number of military units in the settlement.
    --- 
    --- Parameter: Amount, LowerThan, OtherPlayer
    Soldiers = 48,
    --- The weather must be changed.
    --- 
    --- Parameter: WeatherState
    WeatherState = 49,

    --- The receiver must steal the amount of the required resource.
    --- 
    --- Parameter: ResourceType, Amount
    Steal = 50,
    --- The player must complete the quest with the desired result. If the result
    --- is not required, failing the result will not fail the quest.
    --- 
    --- Parameter: Quest, Result [, Required]
    Quest = 51,
};

-- -------------------------------------------------------------------------- --
-- Effects

--- Effect Types
--- 
--- * `Script` - Calls the script function with self reference and quest reference.
--- * `Victory` - The receiver wins the game.
--- * `Defeat` - The receiver loses the game.
--- * `Message` - A message is displayed. If given, only for a certain player.
--- * `Briefing` - Displays a briefing for the quest receiver.
--- * `RevealArea` - Creates exploration of an area the receiver can see.
--- * `ConcealArea` - Deletes an exploration.
--- * `CreateMarker` - Creates a minimap marker or minimap pulsar at the position.
--- * `DestroyMarker` - Removes a minimap marker or pulsar at the position.
--- * `OpenEntry` - Adds a quest description to the quest book for the receiver.
--- * `CloseEntry` - Marks a quest description in the quest book as done for the receiver.
--- * `RemoveEntry` - Removes a quest description from the quest book of the receiver.
--- * `QuestSucceed` - A not finished quest succeeds.
--- * `QuestFail` - A not finished quest fails.
--- * `QuestInterrupt` - A not finished quest is interrupted.
--- * `QuestActivate` - An inactive quest is triggered.
--- * `QuestReset` - A finished quest is reset.
--- * `QuestRestart` - A finished quest is reset.
--- * `Technology` - Changes the state of a technology.
--- * `Resource` - Gives or takes away a resource from the receiver.
--- * `Diplomacy` - Changes the diplomacy state between 2 players.
--- * `Move` - Moves an entity to another.
--- * `CreateEffect` - Creates a graphic effect at the location.
--- * `DestroyEffect` - Destroys a graphic effect.
--- * `CreateEntity` - Replaces a script entity with a new entity.
--- * `CreateGroup` - Replaces a script entity with a military group.
--- * `DestroyEntity` - Replaces an entity or group with a script entity.
--- * `ChangePlayer` - Changes the owner of the entity.
Effect = {
    --- Calls the script function with self reference and quest reference.
    --- 
    --- Parameter: FunctionName, Data
    Script = 1,
    --- The receiver wins the game.
    Victory = 2,
    --- The receiver looses the game.
    Defeat = 3,

    --- A message is displayed. If given, only for a certain player
    --- 
    --- Parameter: [Player, ] Text
    --- 
    --- Player can be:
    --- * nil  -> all players receive message
    --- * 1..n -> only player with ID gets message
    Message = 10,
    --- Displays a briefing for the quest receiver.
    --- 
    --- Parameter: Name, Function
    Briefing = 11,
    --- Creates exploration of an area the receiver can see.
    --- 
    --- Parameter: Location, Area
    RevealArea = 12,
    --- Deleates an exploration.
    --- 
    --- Parameter: Location
    ConcealArea = 13,
    --- Creates an minimap marker or minimap pulsar at the position.
    --- 
    --- Parameter: Location, MarkerType
    CreateMarker = 13,
    --- Removes a minimap marker or pulsar at the position.
    --- 
    --- Parameter: Location
    DestroyMarker = 15,

    --- Adds a quest description to the quest book for the receiver.
    --- 
    --- Parameter: ID, Type, Title, Text [, Info]
    OpenEntry = 20,
    --- Marks a quest description in the quest book as done for the receiver.
    --- 
    --- Parameter: ID [, Info]
    CloseEntry = 21,
    --- Removes a quest description from the quest book of the receiver.
    --- 
    --- Parameter: ID
    RemoveEntry = 22,

    --- A not finished quest succeeds.
    --- 
    --- Parameter: Name
    QuestSucceed = 30,
    --- A not finished quest fails.
    --- 
    --- Parameter: Name
    QuestFail = 31,
    --- A not finished quest is interrupted.
    --- 
    --- Parameter: Name
    QuestInterrupt = 32,
    --- A inactive quest is triggered.
    --- 
    --- Parameter: Name
    QuestActivate = 33,
    --- A finished quest is reset.
    --- 
    --- Parameter: Name
    QuestReset = 34,
    --- A finished quest is reset.
    --- 
    --- Parameter: Name
    QuestRestart = 35,

    --- Changes the state of a technology
    --- 
    --- Parameter: Technology, State
    --- 
    --- The state decides the availablility of the technology.
    --- * TechnologyStates.Researched -> Technology is researched
    --- * TechnologyStates.Allowed    -> Technology can be researched
    --- * TechnologyStates.Forbidden  -> Technology is locked
    Technology = 40,
    --- Gives or takes away a resource from the receiver.
    --- 
    --- Parameter: ResourceType, Amount
    Resource = 41,
    --- Changes the diplomacy state between 2 players.
    --- 
    --- Parameter: PlayerID1, PlayerID2, State
    Diplomacy = 42,

    --- Moves an entity to another.
    --- 
    --- Parameter: Entity, Target
    Move = 50,
    --- Creates an graphic effect at the location.
    --- 
    --- Parameter: Name, Type, Location
    CreateEffect = 51,
    --- Destroys an graphic effect.
    --- 
    --- Parameter: Name
    DestroyEffect = 52,
    --- Replaces a script entity with a new entity.
    --- 
    --- Parameter: ScriptName, Type, PlayerID
    CreateEntity = 53,
    --- Replaces a script entity with a military group.
    --- 
    --- Parameter: ScriptName, Type, Soldiers, PlayerID
    CreateGroup = 54,
    --- Replaces a entity or group with a script entity.
    --- 
    --- Parameter: ScriptName
    DestroyEntity = 55,
    --- Changes the owner of the entity.
    --- 
    --- Parameter: Entity, PlayerID
    ChangePlayer = 56,
};

