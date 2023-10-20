Lib.Register("comfort/GetAngleBetween");

--- Returns the angle between the positions.
--- @param _Pos1 any First position
--- @param _Pos2 any Second position
--- @return number Angle Angle between positions
---
--- @require IsValidPosition
---
--- @author totalwarANGEL
--- @version 1.0.0
---
function GetAngleBetween(_Pos1,_Pos2)
	local delta_X = 0;
	local delta_Y = 0;
	local alpha   = 0;
	if type (_Pos1) == "string" or type (_Pos1) == "number" then
		_Pos1 = GetPosition(GetEntityId(_Pos1));
	end
	if type (_Pos2) == "string" or type (_Pos2) == "number" then
		_Pos2 = GetPosition(GetEntityId(_Pos2));
	end
	delta_X = _Pos1.X - _Pos2.X;
	delta_Y = _Pos1.Y - _Pos2.Y;
	if delta_X == 0 and delta_Y == 0 then
		return 0;
	end
	alpha = math.deg(math.asin(math.abs(delta_X)/(math.sqrt(delta_X^2 + delta_Y^2))));
	if delta_X >= 0 and delta_Y > 0 then
		alpha = 270 - alpha;
	elseif delta_X < 0 and delta_Y > 0 then
		alpha = 270 + alpha;
	elseif delta_X < 0 and delta_Y <= 0 then
		alpha = 90  - alpha;
	elseif delta_X >= 0 and delta_Y <= 0 then
		alpha = 90  + alpha;
	end
	return alpha;
end

