cc.exports.Gmath = cc.exports.Gmath or {}

local EPSILON = 0.000001

local Gmath = cc.exports.Gmath


function cc.exports.Gmath.ray(_org,_dir)
    return { org = _org, dir = _dir }
end

function cc.exports.Gmath.subRay(_ray)
    return { org = _ray.org, dir = cc.p(-_ray.dir.x, -_ray.dir.y) }
end

function cc.exports.Gmath.plane(_n,_l)
    return { n = _n, l = _l }
end

function cc.exports.Gmath.getPlane(line)
	--print("line ",line[1].x,line[1].y,line[2].x,line[2].y)
	local normalRay = cc.pNormalize(cc.pSub(line[2], line[1]))
	--print("normalRay",normalRay.x,normalRay.y)
	local n = cc.pRotate( normalRay,cc.pForAngle(math.rad(-90)))
	local l = cc.pDot(line[2], n)
	return Gmath.plane(n,l)
end


function cc.exports.Gmath.isPointCrossPlane(pos,plane)
	
	--print("isPointCrossLine",n.x,n.y, l)
	local length = cc.pDot(pos,plane.n)
	--print("length",length)
	if length - plane.l < 0 then
		return true
	end
	return false
end

function cc.exports.Gmath.isRectCrossPlane(rect,plane)
	if Gmath.isPointCrossPlane(cc.p(cc.rectGetMinX(rect),cc.rectGetMinY(rect)),plane) 
		and Gmath.isPointCrossPlane(cc.p(cc.rectGetMaxX(rect),cc.rectGetMinY(rect)),plane) 
		and Gmath.isPointCrossPlane(cc.p(cc.rectGetMaxX(rect),cc.rectGetMaxY(rect)),plane)
		and Gmath.isPointCrossPlane(cc.p(cc.rectGetMinX(rect),cc.rectGetMaxY(rect)),plane) then
		return true
	end
	return false
end

function cc.exports.Gmath.isRayPlaneIntersection(ray,plane)

	local t = cc.pDot(ray.dir,plane.n)
	if (t < 0 and t > -EPSILON) or (t > 0 and t < EPSILON) then
		printError("Ray-Plane intersection test failed")
		return nil
	end

	t = ( plane.l - cc.pDot(ray.org,plane.n) ) / t
	--print("t : ",t)
	local point = cc.pAdd(ray.org,cc.pMul(ray.dir,t))
	return point
end

return cc.exports.Gmath