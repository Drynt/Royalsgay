require "/scripts/util.lua"

function init()
	--Restore stored storage
	if config.getParameter("storageData") then
		storage = config.getParameter("storageData")
		object.setConfigParameter("storageData", nil)
	end

	--Instantly spawn the pet when first created
	storage.spawnTimer = storage.spawnTimer and 0.5 or 0
	storage.petParams = storage.petParams or {}

	self.monsterType = config.getParameter("shipPetType", "petweasel")
	self.spawnOffset = config.getParameter("spawnOffset", {0, 2})
	
	message.setHandler("getPetParams", function()
		return storage.petParams
	end)
	message.setHandler("setShipPet", function(_, _, petType)
		if petType ~= self.monsterType then
			object.setConfigParameter("shipPetType", petType)
			self.monsterType = petType
			respawnPet()
		end
	end)
	message.setHandler("setPetName", function(_, _, petName)
		if petName ~= storage.petParams.shortdescription then
			storage.petParams.shortdescription = petName
			if petName ~= "" then
				object.setConfigParameter("shortdescription", "Pet House (" .. petName .. ")")
			end
			if self.petId then
				world.callScriptedEntity(self.petId, "monster.setName", petName)
			end
		end
	end)
	message.setHandler("randomiseSeed", function(_, _, newSeed)
		storage.petParams.seed = newSeed
		respawnPet()
	end)
	message.setHandler("getPetId", function()
		return self.petId
	end)
	message.setHandler("resetPet", function(_, _, newSeed)
		storage.petParams = {}
		storage.petParams.seed = newSeed	--So that the GUI has the correct seed
		object.setConfigParameter("shortdescription", "Pet House")
		respawnPet()
	end)
	message.setHandler("changeInteractionType", function(_, _, interactionType)
		storage.petParams.interactionType = interactionType
		respawnPet()
	end)
end

function hasPet()
	return self.petId ~= nil
end

function setPet(entityId, params)
	if self.petId == nil or self.petId == entityId then
		self.petId = entityId
		storage.petParams = util.mergeTable(storage.petParams, params or {})
	else
		return false
	end
end

function update(dt)
	if self.petId and not world.entityExists(self.petId) then
		self.petId = nil
	end
	
	local wireCheckResult = wireCheck()
	if not wireCheckResult then
		if storage.spawnTimer < 0 and self.petId == nil then
			storage.petParams.level = 1
			storage.petParams.damageTeamType = "ghostly"
			storage.petParams.capturable = true
			storage.petParams.captureHealthFraction = 1
			self.petId = world.spawnMonster(self.monsterType, object.toAbsolutePosition(self.spawnOffset), storage.petParams)
			world.callScriptedEntity(self.petId, "setAnchor", entity.id())
			storage.spawnTimer = 0.5
		else
			storage.spawnTimer = storage.spawnTimer - dt
		end
	else
		respawnPet()
	end
end

function respawnPet()
	if self.petId then
		world.sendEntityMessage(self.petId, "despawn")
	end
	self.petId = nil
end

function wireCheck()
	if object.isInputNodeConnected(0) then
		return object.getInputNodeLevel(0)
	else
		return false
	end
end