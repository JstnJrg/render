package OEngine

import rl "vendor:Raylib"


Project :: struct
{
	project_name  : cstring,
	window_width  : i32,
	window_height : i32,
	fps           : i32,
	flags         : ConfigFlags
}


ProjectSettings :: enum i32
{
	DEFAULT_WINDOW_WIDTH  = 640,
	DEFAULT_WINDOW_HEIGHT = 640,
	DEFAULT_FPS           = 60
} 

project_setup        :: proc()
{
	p              := project_get_singleton()
	p.project_name  = "OEngine"
	p.window_width  = i32(ProjectSettings.DEFAULT_WINDOW_WIDTH)
	p.window_height = i32(ProjectSettings.DEFAULT_WINDOW_HEIGHT)
	p.fps           = i32(ProjectSettings.DEFAULT_FPS)
	p.flags        += ConfigFlags{rl.ConfigFlag.WINDOW_RESIZABLE}
}

project_get_singleton   :: proc "contextless" () -> ^Project    { return engine_get_project_singleton() }
project_get_configflags :: proc "contextless" () -> ConfigFlags { return project_get_singleton().flags }
project_set_window_size :: proc(window_width,window_height: i32)
{
	p              := project_get_singleton()
	p.window_width  = window_width
	p.window_height = window_height
}

project_get_window_rect :: proc () -> Rectangle 
{ 
	if !rl.IsWindowReady() 
	{
		p := project_get_singleton()
		return Rectangle{0,0, auto_cast p.window_width, auto_cast p.window_height }
	}
	return Rectangle{0,0, auto_cast rl.GetScreenWidth(), auto_cast rl.GetScreenHeight()} 
}