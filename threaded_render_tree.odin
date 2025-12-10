package OEngine

import time     "core:time"


thread_update :: proc(t: ^Thread)
{
	main_render_tree := engine_get_main_render_tree()

	// Nota(jstn): função init que os que estiverem na arvore devem chamar
	render_render_tree(main_render_tree,CallInterfaceFlags{._INIT})

    project       := project_get_singleton()
	error         : bool

	target_fps    := 1.0/f64(project.fps)
	idle_margin   := f64(0.002) //2ms

	for !error
	{
		start_time     := time.now()


		// Nota(jstn): função init que os que estiverem na arvore devem chamar
		// aqui é permitido a renderização, vem antes do render consumir os comandos
		// o Editor também  deve constar ai, no main_scene_tree
		render_render_tree(main_render_tree,CallInterfaceFlags{._PROCESS})
		error           = rendering_swap_buffers_with_clear() || error

		// 
		frame_duration := time.diff(start_time,time.now())
		elapsed        := time.duration_seconds(frame_duration)

		if elapsed < target_fps 	{
			remaining := (target_fps-elapsed)
			
			// Tempo está acima de 2ms, é muito grande
			if  remaining > idle_margin { duration := Duration((remaining-idle_margin)*1_000); time_sleep(duration) }
			else {}

			// Nota(jstn): garante a precisão.
			for time.duration_seconds(time.diff(start_time,time.now())) < target_fps {}
		}

		elapsed        = time.duration_seconds(time.diff(start_time,time.now()))
		// println("**********> ",elapsed)
		// nuo_variant_val_ptr(&delta,f32(elapsed))
		// engine_set_can_exit(error)
	}

}





// Nota(jstn): actualização por outra thread, actualização do frame da logica
// scripting_thread_update :: proc(t : ^Thread)
// {

// 	update :: proc(delta: ^variant.Value, fn: ^variant.Value) -> bool 
// 	{ 
// 		nuo_push(delta)
// 		defer scripting_nuo_pop_unr()
// 		return nuo_call(fn,1)
// 	}

// 	update_script :: proc(iid: int, delta: ^variant.Value) -> (error : bool)
// 	{
// 		fn, has := scripting_nuo_ctx_get(iid,on_update); has or_return
// 		return update(delta,&fn)
// 	}


// 	project := project_get_singleton()
// 	scripts := scripting_get_scripts()

// 	delta   := nuo_variant_val(0.0)
// 	error   : bool

// 	target_fps    := 1.0/f64(project.fps)
// 	idle_margin   := f64(0.002) //2ms


// 	for !error
// 	{
// 		start_time     := time.now()

// 		// Nota(jstn): trabalhos
// 		for &script in scripts
// 		{
// 			if script.on_update do error  = update(&delta,&script.update)
// 			if error do break
// 		}

// 		// error           = notification_handler() || error
// 		// rendering_swap_buffers()

// 		error           = rendering_swap_buffers_with_clear() || error

// 		// 
// 		frame_duration := time.diff(start_time,time.now())
// 		elapsed        := time.duration_seconds(frame_duration)

// 		if elapsed < target_fps
// 		{
// 			remaining := (target_fps-elapsed)
			
// 			// Tempo está acima de 2ms, é muito grande
// 			if  remaining > idle_margin { duration := Duration((remaining-idle_margin)*1_000); time_sleep(duration) }
// 			else {}

// 			// Nota(jstn): garante a precisão.
// 			for time.duration_seconds(time.diff(start_time,time.now())) < target_fps {}
// 		}

// 		elapsed        = time.duration_seconds(time.diff(start_time,time.now()))
// 		nuo_variant_val_ptr(&delta,f32(elapsed))
// 		engine_set_can_exit(error)
// 	}


// }
