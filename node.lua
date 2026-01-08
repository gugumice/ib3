local w=NATIVE_WIDTH
local h=NATIVE_HEIGHT
--Set window offset 
local WIN_OFFSET_W = 10
local WIN_OFFSET_H = 10

local INTERVAL = 20
-- enough time to load next image
local SWITCH_DELAY = 1
-- transition time in seconds.
-- set it to 0 switching instantaneously
local SWITCH_TIME = 2.0
--BACKGROUND = resource.load_image('background.jpg')
local pict = nil
local video = nil
local interval = INTERVAL

mainwin_w = w - WIN_OFFSET_W	
mainwin_h = h - WIN_OFFSET_H
gl.setup(w, h)

assert(SWITCH_TIME + SWITCH_DELAY < interval,
    "INTERVAL must be longer than SWITCH_DELAY + SWITCHTIME")

util.file_watch("playlist.txt", function(content) 
	playlist = {}
	for filename in string.gmatch(content, "[^\r\n]+") do
		if filename ~= nil or filename ~= "" then
    			playlist[#playlist+1] = filename
		end
	end
	current_file_idx = 0
	print("Playlist")
	pp(playlist)
end)

function split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

function get_next()
		interval = INTERVAL
		show_start = sys.now()
		local n,s
		
		current_file_idx = current_file_idx + 1
		if current_file_idx > #playlist then
			current_file_idx = 1
		end
		n = split(playlist[current_file_idx],",")
		next_file = n[1]
		if n[2] ~= nil then
			s = tonumber(n[2])
			if  s ~= nil and (SWITCH_TIME + SWITCH_DELAY < s) then
				interval = s
			end
		end
		print("Showing ..." .. next_file .. " for " .. interval .. "s")
		return next_file
end

function load_next()
	if string.upper(next_file):match(".*JPG") then
		pict = resource.load_image(next_file)
		if video then
			video:dispose()
			video=nil
		end
	elseif string.upper(next_file):match(".*MP4") then
		video = util.videoplayer(next_file, {audio=true})
		--video = util.videoplayer(playlist[current_video_idx], {audio=true, loop=true})
		--video = resource.load_video(playlist[current_video_idx], true, true)
		if pict then
			pict:dispose()
			pict = nil
		end
	end
end
--util.set_interval(INTERVAL, show_next)
load_next(get_next())

function node.render()
	if next_file == "" or next_file:sub(1, 1) == "#" then
		load_next(get_next())
		return
	end
	gl.clear(1, 1, 1, 1)
	local delta = sys.now() - show_start - SWITCH_TIME
	--print(delta .. " > " .. 1+delta/SWITCH_TIME)
	--BACKGROUND:draw(5, 5, mainwin_w-7, mainwin_h-7)
	if pict then
		if delta>interval then
			load_next(get_next())
		end
		if delta > 0 then 
			util.draw_correct(pict, WIN_OFFSET_W, WIN_OFFSET_H, mainwin_w-WIN_OFFSET_W, mainwin_h-WIN_OFFSET_H)
		elseif delta <0 then
			local progress = delta / SWITCH_TIME
			util.draw_correct(pict, WIN_OFFSET_W, WIN_OFFSET_H, mainwin_w-WIN_OFFSET_W, mainwin_h-WIN_OFFSET_H, 1+progress)
		end
	elseif video then
		if not video:next() then
			video:dispose()
			video=nil
			load_next(get_next())
		else
			util.draw_correct(video,WIN_OFFSET_W, WIN_OFFSET_H, mainwin_w-WIN_OFFSET_W, mainwin_h-WIN_OFFSET_H)
		end
	end
end
