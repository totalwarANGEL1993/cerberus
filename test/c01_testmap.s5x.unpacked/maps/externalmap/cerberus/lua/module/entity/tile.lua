Lib.Register("comfort/IsValidPosition");
Lib.Register("module/trigger/Job");
Lib.Register("module/search/Tile");

Tile = Tile {};



Tile.Internal = Tile.Internal or {
    Data = {
        EntityDictionary = {},
        TileDictionary = {},
        EntityToTileMap = {},
        TileToEntityMap = {},
    },
}

function Tile.Internal:Install()
    if not self.IsInstalled then
        self.IsInstalled = true;

        local TileSize = 1000;
        local TilesX = math.floor(Logic.WorldGetSize() / TileSize);
        local TilesY = math.floor(Logic.WorldGetSize() / TileSize);
        for x = 0, TilesX -1 do
            for y = 0, TilesY -1 do
                local TileID = x + y * TilesX;
                local Tile = {
                    Neighbors = {},
                    Width = TileSize,
                    Height = TileSize,
                    X = x * TileSize,
                    Y = y * TileSize,
                };
                self.Data.TileDictionary[TileID] = Tile;
                self.Data.TileToEntityMap[TileID] = {};
            end
        end

        self:InitalizeTileNeighbors();

        Job.Create(function()
            Tile.Internal:OnEntityCreated();
        end);
        Job.Destroy(function()
            Tile.Internal:OnEntityDestroyed();
        end);
        Job.Second(function()
            Tile.Internal:OnEverySecond();
        end);
    end
end

function Tile.Internal:InitalizeTileNeighbors()
    for TileID, Tile in pairs(self.Data.TileDictionary) do
        local x, y = Tile.X, Tile.Y;
        self:AddConnection(Tile, self:findTile(x - 1000, y - 1000));
        self:AddConnection(Tile, self:findTile(x, y - 1000));
        self:AddConnection(Tile, self:findTile(x + 1000, y - 1000));
        self:AddConnection(Tile, self:findTile(x - 1000, y));
        self:AddConnection(Tile, self:findTile(x + 1000, y));
        self:AddConnection(Tile, self:findTile(x - 1000, y + 1000));
        self:AddConnection(Tile, self:findTile(x, y + 1000));
        self:AddConnection(Tile, self:findTile(x + 1000, y + 1000));
    end
end

function Tile.Internal:AddConnection(_TileID, _NeighborID)
    if not self.Data.TileDictionary[_TileID]
    or not self.Data.TileDictionary[_NeighborID]
    or _TileID == _NeighborID then
        return;
    end
    self.Data.TileDictionary[_TileID].Neighbors[_NeighborID] = true;
end

function Tile.Internal:FindTile(_X, _Y)
    for _, Tile in pairs(self.Data.TileDictionary) do
        if Tile.X == _X and Tile.Y == _Y then
            return Tile.ID;
        end
    end
    return -1;
end

function Tile.Internal:GetNeighbors(_TileID)
    local Neighbors = {};
    if self.Data.TileDictionary[_TileID] then
        for Neighbor in pairs(self.Data.TileDictionary[_TileID].Neighbors) do
            table.insert(Neighbors, Neighbor);
        end
    end
    return Neighbors;
end

function Tile.Internal:GetNeighboringTiles(_TileID, _Size, _Depth)
    _Depth = _Depth or 0;
    if _Depth == 0 then
        return {_TileID};
    else
        local Neighbors = self:GetNeighbors(_TileID);
        local TileList = {_TileID};
        for _, Neighbor in ipairs(Neighbors) do
            local SubTileList = self:getCustomSizeSquare(Neighbor, _Size, _Depth - 1);
            for _, SubTile in ipairs(SubTileList) do
                if not IsInTable(SubTile, TileList) then
                    table.insert(TileList, SubTile);
                end
            end
        end
        return TileList;
    end
end

-- -------------------------------------------------------------------------- --
-- Entity Stuff

function Tile.Internal:GetTileUnderEntity(_Entity)
    local EntityID = GetID(_Entity);
    return self.Data.EntityToTileMap[EntityID] or -1;
end

function Tile.Internal:GetTileAtPosition(_Position)
    local Position = _Position;
    if type(Position) ~= "table" then
        Position = GetPosition(Position);
    end
    if IsValidPosition(Position) then
        local TileSize = 1000;
        local x = math.floor(Position.X / TileSize);
        local y = math.floor(Position.Y / TileSize);
        local ID = math.floor(x + y * (1000 / TileSize));
        return ID;
    end
    return -1;
end

function Tile.Internal:GetTilesInArea(_Position, _AreaSize)
    local Depth = (_AreaSize - 1000) / 1000;
    local TileID = self:GetTileAtPosition(_Position);
    return self:GetNeighboringTiles(TileID, _AreaSize, Depth);
end

function Tile.Internal:GetEntitiesAtTile(_TileID, _Filter)
    local Result = {0};
    for EntityID,_ in pairs(self.Data.TileToEntityMap[_TileID]) do
        if not _Filter or _Filter(_TileID, EntityID) then
            table.insert(Result, EntityID);
            Result[1] = Result[1] + 1;
        end
    end
    return Result;
end

function Tile.Internal:GetEntitiesInArea(_Position, _AreaSize, _Filter)
    local TileList = self:GetTilesInArea(_Position, _AreaSize);
    local Result = {0};

    local CenterID = Logic.CreateEntity(Entities.XD_ScriptEntity, _Position.X, _Position.Y, 0, 8);
    for _, TileID in pairs(TileList) do
        local EntitiesAtTile = self:GetEntitiesAtTile(TileID);
        for _, EntityID in pairs(EntitiesAtTile) do
            if Logic.CheckEntitiesDistance(EntityID, CenterID, _AreaSize) == 1 then
                if not _Filter or _Filter(TileID, EntityID) then
                    table.insert(Result, EntityID);
                    Result[1] = Result[1] + 1;
                end
            end
        end
    end
    DestroyEntity(CenterID);
    return Result;
end

-- -------------------------------------------------------------------------- --
-- Triggers

function Tile.Internal:OnEntityCreated()
    local EntityID = Event.GetEntityID();
    local TileID = self:GetTileAtPosition(EntityID);
    self.Data.EntityDictionary[EntityID] = true;
    if self.Data.TileDictionary[TileID] then
        self.Data.EntityToTileMap[EntityID] = TileID;
        self.Data.TileToEntityMap[TileID][EntityID] = true;
    end
end

function Tile.Internal:OnEntityDestroyed()
    local EntityID = Event.GetEntityID();
    local TileID = self.Data.EntityDictionary[EntityID];
    self.Data.EntityToTileMap[EntityID] = nil;
    self.Data.TileToEntityMap[TileID][EntityID] = nil;
    self.Data.EntityDictionary[EntityID] = nil;
end

function Tile.Internal:OnEverySecond()
    for EntityID,_ in pairs(self.Data.EntityDictionary) do
        local TileID = self:GetTileAtPosition(EntityID);
        self.Data.EntityToTileMap[EntityID] = TileID;
    end
end

