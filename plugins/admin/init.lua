local plugin = ...
plugin.name = 'Admin'
plugin.author = 'jdb'
plugin.description = 'Useful commands for server administrators, with logs.'

plugin.defaultConfig = {
	-- Logs admin actions in Discord rich embeds.
	webhookEnabled = false,
	webhookHost = 'https://discord.com',
	webhookPath = '/api/webhooks/xxxxxx/xxxxxx'
}

local persistence = plugin:require('persistence')
local manipulation = plugin:require('manipulation')
local moderators = plugin:require('moderators')
local warnings = plugin:require('warnings')

plugin:require('utility')
plugin:require('spawning')
plugin:require('punishment')
plugin:require('teleportation')

function plugin.onEnable ()
	persistence.onEnable()
	manipulation.onEnable()
	moderators.onEnable()
	warnings.onEnable()
end

function plugin.onDisable ()
	warnings.onDisable()
	moderators.onDisable()
	manipulation.onDisable()
	persistence.onDisable()
end

---Log an admin action and keep a permanent record of it.
---@param format string The string or string format to log.
---@vararg any The additional arguments passed to string.format(format, ...)
function adminLog (format, ...)
	if not plugin.isEnabled then return end

	local str = string.format(format, ...)
	plugin:print(str)
	chat.tellAdminsWrap('[Admin] ' .. str)

	local logFile = io.open('admin-log.txt', 'a')
	logFile:write('[' .. os.date("!%c") .. '] ' .. str .. '\n')
	logFile:close()
end

function plugin.hooks.Logic ()
	moderators.hookLogic()
	warnings.hookLogic()
end

plugin.commands['/resetlua'] = {
	info = 'Reset the Lua state and the game.',
	canCall = function (ply) return ply.isConsole or ply.isAdmin end,
	---@param ply Player
	---@param man Human?
	---@param args string[]
	call = function (ply, man, args)
		flagStateForReset(hook.persistentMode)
		adminLog('%s reset the Lua state', ply.name)
	end
}

plugin.commands['/mode'] = {
	info = 'Change the enabled mode.',
	usage = '/mode <mode>',
	canCall = function (ply) return ply.isConsole or ply.isAdmin end,
	---@param ply Player
	---@param man Human?
	---@param args string[]
	call = function (ply, man, args)
		assert(#args >= 1, 'usage')

		local foundPlugin
		for _, plugin in pairs(hook.plugins) do
			if plugin.nameSpace == 'modes' and plugin.fileName == args[1] then
				foundPlugin = plugin
			end
		end
		assert(foundPlugin, 'Invalid mode')

		-- Disable all mode plugins
		for _, plugin in pairs(hook.plugins) do
			if plugin.nameSpace == 'modes' then
				plugin:disable()
			end
		end

		-- If we reset in the middle of chat messages being parsed, things will break
		hook.once('Logic', function ()
			-- Enable the new mode
			foundPlugin:enable()

			hook.persistentMode = args[1]
		end)

		adminLog('%s set the mode to %s', ply.name, args[1])
	end
}

plugin.commands['/resetgame'] = {
	info = 'Reset the game.',
	alias = {'/rg'},
	canCall = function (ply) return ply.isConsole or ply.isAdmin end,
	---@param ply Player
	---@param man Human?
	---@param args string[]
	call = function (ply, man, args)
		-- If we reset in the middle of chat messages being parsed, things will break
		hook.once('Logic', function ()
			server:reset()
		end)

		adminLog('%s reset the game', ply.name)
	end
}