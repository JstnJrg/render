package OEngine

import rl         "vendor:Raylib"



/* Nota(jstn): a viewport da RenderTree */
RenderTreeWatcher  :: struct
{
	layers        : [RenderingSettings.BUFFER_MAX][RenderingSettings.Z_MAX]DrawLayers,
	frame_buffer  : Handle,
	enclosing     : ^RenderTreeWatcher,
	bg_color      : Color,
	fbindx        : int,
	draw_count    : int,
	clear         : bool
}


/* Nota(jstn): é a interface principal de processamento, */
watcher_main_interface :: proc(th: TreeViewHandle) -> ^RenderInterface
{
	_process :: proc(call_type: CallInterface, ri: ^RenderInterface, data: rawptr )
	{
		#partial switch call_type
		{

			// Nota(jstn): aqui a janela já está aberta 
			// então é seguro fazer o preload
			case ._INIT:

				p                   := project_get_singleton()
				watcher             := (^RenderTreeWatcher)(data)
				watcher.frame_buffer = render_texture_create()
				watcher.fbindx       = rendering_get_logic_index()
				watcher.clear        = true
				watcher.bg_color     = Color{0,0,0,255}

				when !THREAD_IS_SUPPORTED do render_texture_load(&watcher.frame_buffer,p.window_width,p.window_height)
				else do commands_push_load_resource(watcher,watcher.frame_buffer,"",p.window_width,p.window_height)


			case ._PROCESS:

				watcher             := (^RenderTreeWatcher)(data)
				watcher.fbindx       = rendering_get_unsafe_logic_index()
				watcher.draw_count   = 0

		}

	}


	interface,page       := smallnew(RenderInterface)
	interface.page        = page
	interface.handle      = th

	interface.data         = new(RenderTreeWatcher,engine_get_allocator())
	interface._call_handle = _process

	return interface
}


// watcher_make_interface :: proc(th: TreeViewHandle) -> ^RenderInterface
// {
// 	_process :: proc(call_type: CallInterface, ri: ^RenderInterface, data: rawptr)
// 	{
// 		#partial switch call_type
// 		{
// 			case ._INIT:
// 			case ._PROCESS:
// 		}

// 	}

// 	interface,page       := smallnew(RenderInterface)
// 	interface.page        = page
// 	interface.handle      = th

// 	interface.data         = new(Sprite2D,engine_get_allocator())
// 	interface._call_handle = _process

// 	return interface
// }