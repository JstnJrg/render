package OEngine

import rl         "vendor:Raylib"
import rlgl       "vendor:Raylib/rlgl"




rendering_postcontext_setup :: proc()
{
	// r := rendering_get_singleton()
	// p := project_get_singleton()

	// r.view_rectangle = rl.Rectangle{0,0,auto_cast p.window_width, auto_cast p.window_height}
	
	// for &target in r.target_textures
	// {
	// 	target.rtexture  = rl.LoadRenderTexture(p.window_width,p.window_height)
	// 	target.rectangle = rl.Rectangle{0,0,auto_cast p.window_width, auto_cast -p.window_height}
	// }
}



rendering_update        :: proc()
{
	project          := project_get_singleton()
	render           := rendering_get_singleton()
	main_render_tree := engine_get_main_render_tree()

	rl.SetConfigFlags(project_get_configflags())
	rl.InitWindow(project.window_width,project.window_height,project.project_name)
	rl.SetTargetFPS(project.fps)

	// Nota(jstn): carrega as texturas 
	rendering_postcontext_setup()

	// /////////////////////////////////////////////
	when THREAD_IS_SUPPORTED 
	{
		logic_thread := th_create(thread_update)
		th_start(logic_thread)
		// time_sleep(Second)
		
		defer
		{
			if !th_is_done(logic_thread) do th_terminate(logic_thread,-1)
			th_destroy(logic_thread)
		}
	}
	// /////////////////////////////////////////////
	defer rl.CloseWindow()


	// Nota(jstn): função init que os que estiverem na arvore devem chamar
	when !THREAD_IS_SUPPORTED do render_render_tree(main_render_tree,CallInterfaceFlags{._INIT})

	when TEST do ball_init()
	clear_background := true

	for !rl.WindowShouldClose() //&& !engine_get_can_exit()
	{
		 rl.BeginDrawing()
		defer rl.EndDrawing()

		// when TEST do test_flush()

		// ----------------------- RENDER ---------------------
		
		when !THREAD_IS_SUPPORTED {

			if clear_background do rl.ClearBackground(render.background_color)

			// Nota(jstn): função init que os que estiverem na arvore devem chamar
			// aqui é permitido a renderização, vem antes do render consumir os comandos
			// o Editor também  deve constar ai, no main_scene_tree
			render_render_tree(main_render_tree,CallInterfaceFlags{._PROCESS})
			clear_background = rendering_flush_commands()
			

			rendering_swap_buffers_with_clear()
		}
		else {
			if rendering_flush_commands() do rl.ClearBackground(render.background_color)
		}
		
		// rendering_draw_target_textures()
		// -----------------------________---------------------

		rl.DrawFPS(20,20)
	}
}






rendering_flush_commands :: proc() -> bool
{
	viewport := rendering_get_ready_buffer()

	viewport.ready            or_return
	(viewport.draw_count > 0) or_return

	// render       := rendering_get_singleton()
	frame_buffer := render_texture_get(&viewport.frame_buffer)
	rtexture     := frame_buffer.rtexture

	layers       := viewport.layers
	bg_color     := viewport.bg_color

	draw_layer   : ^DrawLayers
	command      : ^RenderCommand


	rl.BeginTextureMode(rtexture)
	if viewport.clear do rl.ClearBackground(bg_color)

	rl.DrawRectangleLinesEx(frame_buffer.rectangle,4.0,rl.GREEN)

	defer 
	{
		rl.EndTextureMode()
		rl.DrawTextureRec(rtexture.texture,frame_buffer.rectangle,rl.Vector2{0,0},rl.WHITE)	
		
		rl.DrawText(rl.TextFormat("Draw Count : %v", viewport.draw_count),20,40,12,rl.WHITE)
		rendering_set_buffer_free_without_clear(viewport.idx)
	}


	for z_index in 0..< i32(RenderingSettings.Z_MAX)
	{
		draw_layer = &layers[z_index]; draw_layer.is_used or_continue
		command    = draw_layer.head

		defer rendering_clear_drawlayer(draw_layer)

		for command != nil
		{
			rlgl.PushMatrix()

			rotation  := command.rotation
			scale     := command.scale
			origin    := command.origin

			rlgl.Translatef(origin.x,origin.y,0)
			rlgl.Rotatef(rotation,0,0,1)
			rlgl.Scalef(scale.x,scale.y,0)

			defer 
			{
				rlgl.PopMatrix()
				command = command.next				
			}

			#partial switch command.type
			{
				case .DRAW_CIRCLE    : draw_circle(viewport,command,bg_color)
				case .DRAW_LINE      : draw_line(viewport,command,bg_color)
				case .DRAW_RECTANGLE : draw_rectangle(viewport,command,bg_color)
				case .DRAW_TEXTURE   : draw_texture(viewport,command,bg_color)
				case .DRAW_TEXT      : draw_text(viewport,command,bg_color)

				// case .DRAW_BUTTON        : draw_button(viewport,command,bg_color)
				// case .DRAW_TOGGLE        : draw_toggle(viewport,command,bg_color)
				// case .DRAW_MESSAGE_BOX   : draw_message_box(viewport,command,bg_color)
				// case .DRAW_TOGGLE_GROUP  : draw_toggle_group(viewport,command,bg_color)
				// case .DRAW_TOGGLE_SLIDER : draw_toggle_slider(viewport,command,bg_color)
				// case .DRAW_DROP_DOWN_BOX : draw_drop_down_box(viewport,command,bg_color)
				// case .DRAW_COMBO_BOX     : draw_combo_box(viewport,command,bg_color)
				// case .DRAW_WINDOW_BOX    : draw_window_box(viewport,command,bg_color)


				case .LOAD_RESOURCE  : load_resource(viewport,command,bg_color)
				case .UNLOAD_RESOURCE: unload_resource(viewport,command,bg_color)
			}

		}

	}


	return true	
}
