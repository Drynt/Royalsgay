require "/scripts/util.lua"
require "/scripts/messageutil.lua"

function init()
	self.warnOnce={}
	--unnecessary,unused
	--self.detectArea = config.getParameter("detectArea")
	--self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
	--self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])

	storage.uuid = storage.uuid or sb.makeUuid()
	storage.tricorder = storage.tricorder or {}
	object.setInteractive(true)

	message.setHandler("onTeleport",
		function(message, isLocal, data)
			if not storage.vanishTime then
				storage.vanishTime = world.time() + config.getParameter("vanishTime")
			end
		end
	)
end

function update(dt)
	promises:update()

	local messagePlayers = world.playerQuery(object.position(), config.getParameter("tricorderCheckRange"))
	if messagePlayers then
		for _, playerId in pairs (messagePlayers) do
			promises:add(
				world.sendEntityMessage(playerId, "fu_key", "statustablet"),
				function(successful)
					if world.entityUniqueId(playerId) then
						if successful then
							storage.tricorder[world.entityUniqueId(playerId)] = true
						else
							storage.tricorder[world.entityUniqueId(playerId)] = false
						end
					else
						if not self.warnOnce[playerId] then
							sb.logWarn("Poptop Cavern Door: Player with ID %s has no unique ID.",playerId)
							self.warnOnce[playerId]=true
						end
					end
				end,
				function()
					sb.logWarn("Poptop Cavern Door:  Either the player query is detecting some non-players or the message can't be received.")
				end
			)
		end
	end
	--unnecessary, unused
	--local players = world.playerQuery(self.detectArea[1], self.detectArea[2], {boundMode = "CollisionArea"})
end

function onInteraction(args)
	if args.sourceId and world.entityUniqueId(args.sourceId) and storage.tricorder[world.entityUniqueId(args.sourceId)] == true then
		if config.getParameter("returnDoor") then
			return { "OpenTeleportDialog",
				{
					canBookmark = false,
					includePlayerBookmarks = false,
					destinations = {{
						name = "Departure Radar",
						planetName = "Beam back...hopefully!",
						icon = "return",
						warpAction = "Return"
					}}
				}
			}
		else
			return { "OpenTeleportDialog",
				{
					canBookmark = false,
					includePlayerBookmarks = false,
					destinations = {{
						name = "???",
						planetName = "Dark Cavern",
						icon = "default",
						warpAction = string.format(config.getParameter("destination"), storage.uuid, world.threatLevel())
					}}
				}
			}
		end
	else
		return {config.getParameter("noTricorderInteractAction"), config.getParameter("noTricorderInteractData")}
	end
end
