-- Intended for use with shield bashing

-- Possible args:
--     args.healthRecover      -- How much health (%) to recover on bash
--     args.resource           -- Overrides the resource recovered/drained (healthRecover is still used)
--     args.particles          -- Overrides the particles used
--     args.sound              -- Overrides the sound used

function FRHelper:call(args, ...)
	local res=args.resource or "health"
	local amount=args.healthRecover or 1.2
	if res=="health" then
		amount=amount*math.max(0,1+status.stat("healingBonus"))
	end
    status.modifyResource(res,amount)
    animator.burstParticleEmitter(args.particles or "bonusBlock3")
    animator.playSound(args.sound or "bonusEffect")
end
