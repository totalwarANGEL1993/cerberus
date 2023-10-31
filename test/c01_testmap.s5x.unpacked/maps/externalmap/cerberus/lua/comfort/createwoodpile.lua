Lib.Register("comfort/CreateWoodPile");

-- Version: 1.0.0
-- Author:  Noigi

--- Creates a pile of wood to extract.
--- @param _posEntity any    Position of pile
--- @param _resources number Amount of resources
--- @return number ID Index of pile
function CreateWoodPile(_posEntity, _resources)
    assert(type(_posEntity) == "string");
    assert(type(_resources) == "number");

    gvWoodPiles = gvWoodPiles or {
        ID = 0,
        JobID = StartSimpleHiResJob("ControlWoodPiles"),
    };
    gvWoodPiles.ID = gvWoodPiles.ID +1;

    local pos = GetPosition( _posEntity );
    local pile_id = Logic.CreateEntity( Entities.XD_Rock3, pos.X, pos.Y, 0, 0 );
    SetEntityName(pile_id, _posEntity.."_WoodPile");
    Logic.SetModelAndAnimSet(pile_id, Models.Effects_XF_ExtractStone);
    local res_id = ReplaceEntity(_posEntity, Entities.XD_ResourceTree);
    Logic.SetModelAndAnimSet(res_id, Models.XD_SignalFire1);
    Logic.SetResourceDoodadGoodAmount( GetEntityId( _posEntity ), _resources*15 );
    table.insert(gvWoodPiles, {
        ID = gvWoodPiles.ID,
        ResourceEntity = _posEntity,
        PileEntity = _posEntity.."_WoodPile",
        ResourceLimit = _resources*14
    });
    return gvWoodPiles.ID;
end

--- Destroys a pile of wood.
--- @param _index number Index of pile
function DestroyWoodPile(_index)
    gvWoodPiles = gvWoodPiles or {};
    for i= table.getn(gvWoodPiles), 1, -1 do
        if gvWoodPiles[i].ID == _index then
            local pos = GetPosition(gvWoodPiles[_index].ResourceEntity);
            DestroyEntity(gvWoodPiles[_index].ResourceEntity);
            DestroyEntity(gvWoodPiles[_index].PileEntity);
            Logic.CreateEffect( GGL_Effects.FXCrushBuilding, pos.X, pos.Y, 0 );
            table.remove(gvWoodPiles, _index);
            return;
        end
    end
end

function ControlWoodPiles()
    for i = table.getn(gvWoodPiles),1,-1 do
        local ID = GetID(gvWoodPiles[i].ResourceEntity);
        if Logic.GetResourceDoodadGoodAmount(ID) <= gvWoodPiles[i].ResourceLimit then
            DestroyWoodPile(i);
        end
    end
end

