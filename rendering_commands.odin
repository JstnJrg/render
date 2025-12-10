package OEngine

import strings "core:strings"



CommandType   :: enum 
{

	DRAW_CIRCLE,
	DRAW_RECTANGLE,
	DRAW_TEXTURE,
	DRAW_LINE,
	DRAW_TEXT,

	LOAD_RESOURCE,
	UNLOAD_RESOURCE
}


RenderCommand :: struct
{
	origin   : Vec2,
	scale    : Vec2,
	modulate : Color,
	rotation : f32,

	next     : ^RenderCommand,
	type     : CommandType,
}


DrawCircleCommand :: struct 
{
	using _ : RenderCommand,
	center  : Vec2,
	color   : Color,
	radius  : f32,
	filled  : bool
}

DrawRectangleCommand :: struct 
{
	using _ : RenderCommand,
	r       : Rectangle,
	color   : Color,
	thick   : f32,
	filled  : bool
}

DrawLineCommand :: struct 
{
	using _ : RenderCommand,
	pos_a   : Vec2,
	pos_b   : Vec2,
	color   : Color,
	thick   : f32,
	bezier  : bool
}

DrawTextureCommand :: struct 
{
	using _  : RenderCommand,
	position : Vec2,
	color    : Color,
	handle   : Handle
}

DrawTextCommand :: struct 
{
	using _  : RenderCommand,
	text     : cstring,
	position : Vec2,
	font_size: f32,
	spacing  : f32,
	color    : Color,
	handle   : Handle
}


LoadResource :: struct 
{
	using _ : RenderCommand,
	path    : cstring,
	width   : i32,
	height  : i32,
	handle  : Handle
}


DeleteResource :: struct 
{
	using _ : RenderCommand,
	handle  : Handle 
}



commands_new    :: proc{commands_new1}
commands_make   :: proc{commands_make1,commands_make2}

commands_new1   :: proc($T: typeid, idx: int)      -> ^T { return new(T,rendering_get_viewport_allocator(idx)) }
commands_make1  :: proc($T: typeid, idx: int)      -> ^T { return make(T,rendering_get_viewport_allocator(idx)) }
commands_make2  :: proc($T: typeid, len, idx: int) -> ^T { return make(T,len,rendering_get_viewport_allocator(idx)) }


clone_to_cstring1       :: proc(s: string, vid: int) -> cstring { return strings.clone_to_cstring(s,rendering_get_viewport_allocator(vid)) }
clone_from_cstring      :: proc(s: cstring, allocator: Allocator) -> string { return strings.clone_from_cstring(s,allocator) }
clone_to_cstring        :: proc{clone_from_cstring,clone_to_cstring1}




@(private="file")
commands_push   :: proc(watcher: ^RenderTreeWatcher, command: ^RenderCommand, z_indx : int)
{
	layer  := &watcher.layers[watcher.fbindx][z_indx]

	// Nota(jstn): facilita a procura por comando usados.
	layer.is_used        = true
	watcher.draw_count  += 1


	// Nota(jstn): primeiro comando a ser allocado
	if layer.head == nil
	{
		layer.head        = command
		layer.tail        = command
		return
	}

	layer.tail.next = command
	layer.tail      = command
}

commands_default_transform2D  :: proc(command: ^RenderCommand)
{
	command.origin   = Vec2{0,0}
	command.scale    = Vec2{1,1}
	command.modulate = Color{74,74,74,255}
	command.rotation = 0
}


commands_push_circle :: proc(watcher: ^RenderTreeWatcher, z_indx : int, center: Vec2, radius: f32, color : Color, filled : bool)
{
	circle       := commands_new(DrawCircleCommand,watcher.fbindx)
	circle.type   = .DRAW_CIRCLE
	circle.center = center
	circle.color  = color
	circle.radius = radius
	circle.filled = filled

	commands_default_transform2D(circle)
	commands_push(watcher,circle,z_indx)
}


draw_texture_command :: proc(watcher: ^RenderTreeWatcher, z_indx: int, handle : Handle , position : Vec2, color: Color)
{
	texture         := commands_new(DrawTextureCommand,watcher.fbindx)
	texture.type     = .DRAW_TEXTURE
	texture.position = position
	texture.color    = color

	commands_default_transform2D(texture)
	commands_push(watcher,texture,z_indx)
}


commands_push_load_resource :: proc(watcher: ^RenderTreeWatcher, h: Handle, path : string = "", width : i32 = 0, height : i32 = 0)
{
	resource       := commands_new(LoadResource,watcher.fbindx)
	resource.type   = .LOAD_RESOURCE
	resource.path   = clone_to_cstring(path,watcher.fbindx)
	resource.width  = width
	resource.height = height
	resource.handle = h
	commands_push(watcher,resource,auto_cast RenderingSettings.Z_INIT_RESOURCE)
}
