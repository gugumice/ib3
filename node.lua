local w=NATIVE_WIDTH
local h=NATIVE_HEIGHT
local BORDER = 0
local mainwin_w = w - BORDER
local mainwin_h = h - BORDER

print(mainwin_w, mainwin_h)
gl.setup(w, h)

local INTERVAL = 20
-- enough time to load next image
local SWITCH_DELAY = 1
-- transition time in seconds.
-- set it to 0 switching instantaneously
local SWITCH_TIME = 2.0
--BACKGROUND = resource.load_image('background.jpg')
local pict = nil
local video = nil

assert(SWITCH_TIME + SWITCH_DELAY < INTERVAL,
    "INTERVAL must be longer than SWITCH_DELAY + SWITCHTIME")

	local interval = INTERVAL

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

function get_next()
	show_start = sys.now()
	current_file_idx = current_file_idx + 1
	if current_file_idx > #playlist then
		current_file_idx = 1
	end
	local f = {}
	for p in playlist[current_file_idx]:gmatch("([^,]+)") do
		table.insert(f, p )
	end
	--next_file = playlist[current_file_idx]
	local next_file = f[1]
	interval = INTERVAL
	if f[2] ~= nil then
		local numval
		numval = tonumber(f[2])
		if numval and (SWITCH_TIME + SWITCH_DELAY < numval) then
			interval = numval
		end
	end
	print("Showing ..." .. next_file .. " interval: " .. interval)
	return next_file
end

function load_next(file)
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
--util.set_interval(interval, show_next)
next_file = get_next()
-- Skip if comment
while string.sub(next_file, 1, 1) == "#" do
	next_file = get_next()
end
load_next(next_file)

function node.render()
	--gl.clear(0, .2, 0, 1) -- green
	gl.clear(1, 1, 1, 1)
	local delta = sys.now() - show_start - SWITCH_TIME
	--print(delta .. " > " .. 1+delta/SWITCH_TIME)
	--BACKGROUND:draw(5, 5, mainwin_w-BORDER, mainwin_h-BORDER)
	if pict then
		if delta > interval then
			print("Delta: " .. delta)
			load_next(get_next())
		end
		if delta > 0 then 
			util.draw_correct(pict,BORDER, BORDER, mainwin_w-BORDER, mainwin_h-BORDER)
		elseif delta < 0 then
			local progress = delta / SWITCH_TIME
			util.draw_correct(pict,BORDER, BORDER, mainwin_w-BORDER, mainwin_h-BORDER, 1+progress)
		end
	elseif video then
		if not video:next() then
			video:dispose()
			video=nil
			load_next(get_next())
		else
			util.draw_correct(video,10, 10, mainwin_w-BORDER, mainwin_h-BORDER)
		end
	end

end
