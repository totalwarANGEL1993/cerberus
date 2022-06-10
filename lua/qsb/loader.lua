gvBasePath = gvBasePath or "data/maps/externalmap/";

API = API or {};
QSB = QSB or {};

Script.Load(gvBasePath.. "qsb/library/oop.lua");

-- Load library
Script.Load(gvBasePath.. "qsb/library/core/source.lua");
Script.Load(gvBasePath.. "qsb/library/core/api.lua");

-- try loading lib
Script.Load("data/maps/user/EMS/tools/s5CommunityLib/packer/devload.lua");
if not mcbPacker then
    gvS5cLibPath = gvS5cLibPath or gvBasePath.. "s5c/";
    Script.Load(gvS5cLibPath.. "s5CommunityLib/packer/devload.lua");
end

-- only if community lib is found
if mcbPacker then
    mcbPacker.Paths = {
        {gvS5cLibPath, ".lua"},
        {gvS5cLibPath, ".luac"}
    };

    if GameCallback_QSB_OnCommunityLibLoaded then
        return GameCallback_QSB_OnCommunityLibLoaded();
    end
    mcbPacker.require("s5CommunityLib/tables/ArmorClasses");
    mcbPacker.require("s5CommunityLib/tables/AttachmentTypes");
    mcbPacker.require("s5CommunityLib/tables/EntityAttachments");
    mcbPacker.require("s5CommunityLib/tables/LeaderFormations");
    mcbPacker.require("s5CommunityLib/tables/MouseEvents");
    mcbPacker.require("s5CommunityLib/tables/TerrainTypes");
    mcbPacker.require("s5CommunityLib/tables/animTable");

    mcbPacker.require("s5CommunityLib/comfort/math/Lerp");
    mcbPacker.require("s5CommunityLib/comfort/math/Polygon");
    mcbPacker.require("s5CommunityLib/comfort/math/Vector");
    mcbPacker.require("s5CommunityLib/comfort/pos/IsInCone");
    mcbPacker.require("s5CommunityLib/comfort/table/CopyTable");
end

