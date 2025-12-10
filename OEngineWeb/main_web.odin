package NuoWeb

import "base:runtime"
import "core:c"
import "core:mem"
import rl "vendor:Raylib"
import OEngine ".."

@(private="file") web_context: runtime.Context
@(private="file") can_run    : bool

@export
web_init :: proc "c" () 
{
	context           = runtime.default_context()
	context.allocator = emscripten_allocator()

	web_context       = context
	can_run           = true

	runtime.init_global_temporary_allocator(1*mem.Megabyte)
	
	OEngine.engine_init()
	OEngine.web_rendering_init()
}

get_web_context :: proc() -> runtime.Context { return web_context }
get_can_run     :: proc() -> bool { return can_run }


@export
web_update :: proc "c" () -> bool 
{
	context = get_web_context()
	OEngine.web_rendering_update()
	when ODIN_OS != .JS do if rl.WindowShouldClose() do can_run = false
	return can_run
}


@export
web_end :: proc "c" () 
{
	context = get_web_context()
	OEngine.web_rendering_end()
	OEngine.engine_deinit()
}

@export
web_window_size_changed :: proc "c" (w: c.int, h: c.int) 
{
	// context = web_context
	// game.parent_window_size_changed(int(w), int(h))
}
