package OEngine

import rl         "vendor:Raylib"
// import rlgl       "vendor:Raylib/rlgl"


web_rendering_init      :: proc()
{
	project := project_get_singleton()
	render  := rendering_get_singleton()

	rl.SetConfigFlags(project_get_configflags())
	rl.InitWindow(project.window_width,project.window_height,project.project_name)
	rl.SetTargetFPS(project.fps)

	// Nota(jstn): carrega as texturas 
	rendering_postcontext_setup()
	render_render_tree(engine_get_main_render_tree(),CallInterfaceFlags{._INIT})
	when TEST do ball_init()
}


web_rendering_end      :: proc() { rl.CloseWindow() }

web_rendering_update   :: proc()
{
	render  := rendering_get_singleton()

	rl.BeginDrawing()
	rl.ClearBackground(render.background_color)

	defer rl.EndDrawing()

	render_render_tree(engine_get_main_render_tree(),CallInterfaceFlags{._PROCESS})
	when TEST do test_flush()

		// editor_flush()
	rendering_flush_commands()
	rendering_swap_buffers_with_clear()

		// editor_draw()
	rl.DrawFPS(20,20)
}

