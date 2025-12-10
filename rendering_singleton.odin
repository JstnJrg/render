package OEngine

import rl         "vendor:Raylib"
import rlgl       "vendor:Raylib/rlgl"
import time       "core:time"
import intrinsics "base:intrinsics"
// import variant    "nuo:variant"


Rendering :: struct
{
	viewports        : []^Viewport,
	target_textures  : rl.RenderTexture, // Elas são desalocadas no final do frame

	mutex            : Mutex,

	view_rectangle   : Rectangle,
	background_color : Color,

	logic_indx       : int,
	render_indx      : int
}

RenderingSettings :: enum i32
{
	Z_INDEX_MIN = 0,
	Z_INDEX_MAX = 1 << 12,

	ENGINE_SLOT = 1,

	Z_MAX             = Z_INDEX_MAX-ENGINE_SLOT,
	Z_INIT_RESOURCE   = 0,
	Z_DEINIT_RESOURCE =Z_MAX,

	BUFFER_MAX = 3
}

DrawLayers    :: struct
{
	head        : ^RenderCommand,
	tail        : ^RenderCommand,
	is_used     : bool // Se está no buffer de used_indexes
}

Viewport     :: struct
{
	layers       : []DrawLayers,
	frame_buffer : Handle, 
	arena        : Arena,
	bg_color     : Color,
	idx          : int,
	draw_count   : int,
	ready        : bool,
	clear        : bool
}





rendering_setup :: proc()
{
	r            := rendering_get_singleton()
	buffer_count := int(RenderingSettings.BUFFER_MAX)
	r.background_color = Color{74,74,74,255}

	r.logic_indx  = 0
	r.render_indx = 1
	r.viewports   = engine_make([]^Viewport,buffer_count)
	
	for i in 0..< buffer_count 
	{ 
		r.viewports[i]             = engine_new(Viewport)
		// r.viewports[i].used_indexs = make([RenderingSettings.Z_MAX]int,engine_get_allocator())
		init_arena(&r.viewports[i].arena) 
	}


	println("*********************************> ",size_of(r.viewports[0].layers)/(1024))
}


rendering_get_singleton :: proc "contextless" () -> ^Rendering { return engine_get_rendering_singleton() }

rendering_deinit        :: proc()
{
	r   := rendering_get_singleton()
	res := resource_get_singleton()

	for &viewport in r.viewports do deinit_arena(&viewport.arena)

	// Texture
	L_Texture: 
	{
		tm := res.texture_manager
		chunk_count := tm.chunk_count

		(chunk_count > 0) or_break L_Texture

		for  i in 0..<chunk_count
		{
			chunk      := tm.chunks[i]
			for j in 0..< chunk.texture_count
			{
				texture := &chunk.textures[j]
				texture.is_loaded or_continue
				rl.UnloadTexture(texture.texture)
			}
		}
	}

	// RenderTexture
	L_RenderTexture: 
	{
		rtm := res.render_texture_manager
		chunk_count := rtm.chunk_count

		(chunk_count > 0) or_break L_RenderTexture

		for  i in 0..<chunk_count
		{
			chunk      := rtm.chunks[i]
			for j in 0..< chunk.render_texture_count
			{
				rtexture := &chunk.render_textures[j]
				rtexture.is_loaded or_continue
				rl.UnloadRenderTexture(rtexture.rtexture)
			}
		}
	}

	// // Font
	// L_Font: 
	// {
	// 	fm := r.font_manager
	// 	chunk_count := fm.chunk_count

	// 	(chunk_count > 0) or_break L_Font

	// 	for  i in 0..<chunk_count
	// 	{
	// 		chunk      := fm.chunks[i]
	// 		for j in 0..< chunk.font_count
	// 		{
	// 			font := &chunk.fonts[j]
	// 			font.is_loaded or_continue
	// 			rl.UnloadFont(font.font)
	// 		}
	// 	}
	// }
}



rendering_get_viewport   :: proc "contextless" (idx: int) -> ^Viewport { return rendering_get_singleton().viewports[idx] }
rendering_get_layers     :: proc "contextless" (idx, z_indx: int) -> ^DrawLayers { return &rendering_get_viewport(idx).layers[z_indx] }
rendering_get_viewport_allocator :: proc (idx: int) -> Allocator   { return arena_allocator(&rendering_get_viewport(idx).arena) }

rendering_set_buffer_free  :: proc (idx: int)
{
	viewport      := rendering_get_viewport(idx)
	arena_free_all(&viewport.arena)
}


/*
	Nota(jstn): porque não limpamos no momento de renderização?
	é porque talvez outro buffer esteja ocupado, então mantemos a image
	do buffer actual intacta
*/
rendering_clear_layers     :: proc(idx: int)
{
	layers       := rendering_get_viewport(idx).layers[:]
	for i in 0..< int(RenderingSettings.Z_MAX)
	{
		draw_layer := &layers[i]
		draw_layer.tail, draw_layer.head = nil,nil	
	}
}



rendering_swap_buffers_with_clear :: proc  () -> bool
{
	r := rendering_get_singleton()

	when !THREAD_IS_SUPPORTED
	{
		logic_indx 	  := r.logic_indx
		viewport      := rendering_get_viewport(logic_indx)
		
		viewport.ready = true
		r.logic_indx   = int(RenderingSettings.BUFFER_MAX)-(r.render_indx+logic_indx)

		// Nota(jstn): caso não seja o mesmo indx e não tem notificacoes
		// caso sejam indeces iguais, então significa que um buffer
		// está ocupado.
		
		// Nota(jstn): Caso não seja o mesmo indice, então 
		// se pode se apagar a arena
		if (logic_indx != r.logic_indx) 
		{
			idx := r.logic_indx
			// Nota(jstn): trata as notificações
			// notification_handler(idx)

			// limpa o buffer
			// rendering_set_buffer_free()
			rendering_set_buffer_free(idx)
			// rendering_clear_layers(idx)
		}

		return false
	}
	else
	{   
		if mt_try_guard(&r.mutex)
		{
			logic_indx 	  := r.logic_indx
			viewport      := rendering_get_viewport(logic_indx)
			
			viewport.ready = true
			r.logic_indx   = int(RenderingSettings.BUFFER_MAX)-(r.render_indx+logic_indx)

			// Nota(jstn): caso não seja o mesmo indx e não tem notificacoes
			// caso sejam indeces iguais, então significa que um buffer
			// está ocupado.
			
			// Nota(jstn): Caso não seja o mesmo indice, então 
			// se pode se apagar a arena
			if (logic_indx != r.logic_indx) 
			{
				idx := r.logic_indx
				// Nota(jstn): trata as notificações
				// notification_handler(idx)

				// limpa o buffer
				// rendering_set_buffer_free()
				rendering_set_buffer_free(idx)
				// rendering_clear_layers(idx)
			}
		}

		return false
	}
}




// Nota(jstn):chamado somente pelo render
rendering_get_ready_buffer     :: proc() -> ^Viewport
{
	when THREAD_IS_SUPPORTED
	{
		r := rendering_get_singleton()
		if mt_try_guard(&r.mutex)
		{
			render_indx    := r.render_indx
			// Nota(jstn): render_indx, é antigo, portanto é seguro elimina-los
			// pois quem altera o index é esta função.
			render_indx     = int(RenderingSettings.BUFFER_MAX)-(render_indx+r.logic_indx)
			r.render_indx   = render_indx

			viewport        := rendering_get_viewport(render_indx)
			viewport.idx     = render_indx

			return viewport
		}
		
		render_indx    := r.render_indx
		viewport       := rendering_get_viewport(render_indx)
		viewport.idx    = render_indx

		return viewport
	}
	else
	{
		r := rendering_get_singleton()
		// if mt_try_guard(&r.mutex)

		logic_indx     := r.logic_indx
		render_indx    := r.render_indx

			// Nota(jstn): render_indx, é antigo, portanto é seguro elimina-los
			// pois quem altera o index é esta função.
		render_indx     = int(RenderingSettings.BUFFER_MAX)-(render_indx+logic_indx)
		r.render_indx   = render_indx

		viewport        := rendering_get_viewport(render_indx)
		viewport.idx     = render_indx

		return viewport
	}

}

// Nota(jstn): 
rendering_set_buffer_free_without_clear :: proc (idx: int)
{
	viewport            := rendering_get_viewport(idx)
	viewport.ready       = false
	viewport.draw_count  = 0
	viewport.clear       = false
	viewport.idx         = -1
}

rendering_clear_drawlayer :: proc "contextless" (layer: ^DrawLayers)
{
	layer.tail    = nil
	layer.head    = nil
	layer.is_used = false
}


rendering_get_logic_index      :: proc "contextless" () -> int { 
	 when THREAD_IS_SUPPORTED do return intrinsics.atomic_load(&rendering_get_singleton().logic_indx )
	 else                     do return rendering_get_singleton().logic_indx 
}

rendering_get_unsafe_logic_index      :: proc "contextless" () -> int { 
	return rendering_get_singleton().logic_indx 
}

// rendering_get_render_index            :: proc "contextless" () -> int { return rendering_get_singleton().render_indx }
rendering_get_unsafe_render_index     :: proc "contextless" () -> int { return rendering_get_singleton().render_indx }
rendering_get_render_index      :: proc "contextless" () -> int { 
	 when THREAD_IS_SUPPORTED do return intrinsics.atomic_load(&rendering_get_singleton().render_indx )
	 else                     do return rendering_get_singleton().render_indx 
}
