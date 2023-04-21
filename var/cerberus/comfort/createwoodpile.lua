Lib.Register("comfort/CreateWoodPile");

--- Creates a pile of wood to extract.
--- @param _posEntity any    Position of pile
--- @param _resources number Amount of resources
--- @return number ID Index of pile
---
--- @author Noigi
--- @version 1.0.0
---
function CreateWoodPile(_posEntity, _resources)
    assert(type(_posEntity) == "string");
    assert(type(_resources) == "number");

    gvWoodPiles = gvWoodPiles or {
        ID = 0,
        JobID = StartSimpleJob("ControlWoodPiles"),
    };
    gvWoodPiles.ID = gvWoodPiles.ID +1;

    local pos = GetPosition( _posEntity );
    local pile_id = Logic.CreateEntity( Entities.XD_SingnalFireOff, pos.X, pos.Y, 0, 0 );
    SetEntityName( pile_id, _posEntity.."_WoodPile" );
    ReplaceEntity( _posEntity, Entities.XD_ResourceTree );
    Logic.SetResourceDoodadGoodAmount( GetEntityId( _posEntity ), _resources*10 );
    table.insert(gvWoodPiles, {
        ID = gvWoodPiles.ID,
        ResourceEntity = _posEntity,
        PileEntity = _posEntity.."_WoodPile",
        ResourceLimit = _resources*9
    });
    return gvWoodPiles.ID;
end

--- Destroys a pile of wood.
--- @param _index number Index of pile
---
--- @author Noigi
--- @version 1.0.0
---
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

