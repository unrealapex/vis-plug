local M = {}
M.plugins = {}

local visrc, err = package.searchpath('visrc', package.path)
assert(not err)
local visrc_path = visrc:match('(.*/)') 
assert(visrc_path)

local plugins_path = visrc_path ..'plugins'
local themes_path = visrc_path ..'themes'

local plugins = {}
local themes = {}

function exists(path)
	local file = io.open(path)
	if not file then 
		return false
	else 
		file:close() 
		return true 
	end
end	

function iterate_plugins(op, args)
	if not plugins then return end
	for url, v in pairs(plugins) do
		local file = v[1]
		local custom_name = v[2]
		local name = url:match('.*%/(.*)%..*')
		local path = plugins_path .. '/' .. name
		op(url, file, name, path, custom_name, args)
	end
end

function iterate_themes(op, args)
	if not themes then return end
	for i, url in ipairs(themes) do
		local name = url:match('.*%/(.*)%..*')
		local file = name .. '.lua'
		local path = themes_path .. '/' .. file
		op(url, file, name, path, args)
	end
end

function plug_install(url, file, name, path, custom_name, silent)
	if exists(path) then
		if not silent then
			vis:message(name .. ' (already installed)')
		end
	else
		os.execute('git -C ' .. plugins_path .. ' clone ' .. url .. ' --quiet 2> /dev/null')
		if not silent then
			vis:message(name)
		end 
	end
	vis:redraw()
end

function theme_install(url, file, name, path, silent)
	if exists(path) then
		if not silent then 
			vis:message(name .. ' (already installed)')
		end
	else
		os.execute('curl -s ' .. url .. ' -o ' .. path)
		if not silent then 
			vis:message(name)
		end
	end
	vis:redraw()
end

function plug_update(url, file, name, path)
	if exists(path) then
		os.execute('git -C ' .. path .. ' pull --quiet 2> /dev/null')
		vis:message(name .. ' updated')
	else
		vis:message(name .. ' (not installed, do :plug-install)')
	end 
	vis:redraw()
end

function plug_require(url, file, name, path, custom_name)
	if not exists(path) then return end
	local plugin = require('plugins/' .. name .. '/' .. file)
	if custom_name then
		M.plugins[custom_name] = plugin
	end

end

function plug_count()
	if not plugins then return 0 end
	local count = 0
	for _ in pairs(plugins) do count = count + 1 end
	return count
end

function plug_name(url, file, name, path)
	if exists(path) then 
		vis:message(name .. ' (' .. url .. ')')
	else 
		vis:message(name .. ' (' .. url .. ') (not installed)')
	end
	vis:redraw()
end

function theme_name(url, file, name, path)
	if exists(path) then 
		vis:message(name)
	else 
		vis:message(name .. ' (not installed)')
	end
	vis:redraw()
end

function init_plugins()
	if not exists(plugins_path) then os.execute('mkdir -p ' .. plugins_path) end
	iterate_plugins(plug_install, true)
end

function init_themes()
	if not exists(themes_path) then os.execute('mkdir -p ' .. themes_path) end
	iterate_themes(theme_install, true)
end

vis:command_register('plug-install', function(argv, force, win, selection, range)
	vis:message('installing plugins')
	vis:redraw()
	if not exists(plugins_path) then os.execute('mkdir -p ' .. plugins_path) end
	iterate_plugins(plug_install, false)
	vis:message('')
	vis:message('installing themes')
	vis:redraw()
	if not exists(themes_path) then os.execute('mkdir -p ' .. themes_path) end
	iterate_themes(theme_install, false)
	vis:message('')
	vis:redraw()
	return true
end)

vis:command_register('plug-update', function(argv, force, win, selection, range)
	vis:message('updating plugins')
	vis:redraw()
	iterate_plugins(plug_update, nil)
	vis:message('')
	vis:redraw()
	return true
end)

vis:command_register('plug-list', function(argv, force, win, selection, range)
	vis:message('plugins')
	vis:redraw()
	iterate_plugins(plug_name)
	vis:message('')
	vis:message('themes')
	vis:redraw()
	iterate_themes(theme_name)
	vis:message('')
	vis:redraw()
	return true
end)

M.init = function(plugins_p, themes_p)
	plugins = plugins_p or {}
	themes = themes_p or {}
	init_plugins()
	init_themes()
	iterate_plugins(plug_require)
end

return M

