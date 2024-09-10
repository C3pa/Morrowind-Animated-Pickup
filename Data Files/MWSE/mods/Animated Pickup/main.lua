---@class AnimatedPickupAnimationData
---@field k number In range [0, 1]. The relative position of the item from it's starting position to the player.
---@field startPos tes3vector3

---@type table<niNode, AnimatedPickupAnimationData>
local animating = {}

local parentNode = niNode.new()
parentNode.name = "AnimatedPickupRoot"

local speed = 750
-- The relative position between the item and player at which
-- the item's node will dissapear. Normalized to [0, 1] range.
local maxK = 0.7
local heightFactor = 0.6

local function updateParentNode()
	parentNode:update()
	parentNode:updateEffects()
	parentNode:updateProperties()
end

---@param e simulateEventData
local function update(e)
	---@type niNode[]
	local expiredAnimations = {}
	local updateParent = false
	local playerPos = tes3.player.position:copy()
	playerPos.z = playerPos.z + tes3.mobilePlayer.height * heightFactor

	-- Move our nodes
	for node, data in pairs(animating or {}) do
		local k = data.k + speed * 0.01 * e.delta
		node.translation = data.startPos:lerp(playerPos, k)
		-- End of the animation?
		if k >= maxK then
			table.insert(expiredAnimations, node)
		end
		data.k = k
		updateParent = true
	end

	-- Clear the nodes that reached the end of their animation
	for _, node in ipairs(expiredAnimations) do
		animating[node] = nil
		node.parent:detachChild(node)
	end

	if updateParent then
		updateParentNode()
	end
end
event.register(tes3.event.simulate, update)

---@param node niNode
local function startAnim(node)
	local startPos = node.translation:copy()
	animating[node] = {
		k = 0,
		startPos = startPos,
	}
end


local nonAnimatable = {
	[tes3.objectType.activator] = true,
	[tes3.objectType.book] = true,
	[tes3.objectType.container] = true,
	-- No need to list the creature and npc instance types since we filter by baseObject type
	[tes3.objectType.creature] = true,
	[tes3.objectType.door] = true,
	[tes3.objectType.npc] = true,
}

---@param e activateEventData
local function onActivate(e)
	local target = e.target
	if nonAnimatable[target.baseObject.objectType] then return end
	local node = target.sceneNode:clone()
	parentNode:attachChild(node)
	updateParentNode()
	startAnim(node)
end
event.register(tes3.event.activate, onActivate, { prioriry = -343 })

local function onInitialized()
	local root = tes3.game.worldObjectRoot
	root:attachChild(parentNode)
	root:update()
end
event.register(tes3.event.initialized, onInitialized)
