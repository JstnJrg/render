package OEngine



Resource    :: struct
{
	// canvas2d_manager : ^Canvas2DManager,
	texture_manager        : ^TextureManager,
	render_texture_manager : ^RenderTextureManager,
	// font_manager     : ^FontManager,
	mutex                  : Mutex
}


ResourceSettings :: enum i32
{
	MAX_CHUNKS = 1 << 3,
	CHUNK_SIZE = 1 << 3
}


ResourceType  :: enum u8 
{ 
	NONE,
	// CANVAS2D,
	// VIEWPORT, 
	TEXTURE, 
	RENDER_TEXTURE,
	// FONT, 
	// SOUND, 
	// IMAGE 
}

Handle      :: bit_field u64
{ 
	chunk        :  u32          | 16, //Nota(jstn): indice dentro no pool de chunks
	index        :  u32          | 16, //Nota(jstn): indice dentro da chunk
	version      :  u32          | 16, // 2^(16)-1
	type         :  ResourceType | 8   //2^(8)-1
}

resource_get_singleton :: proc "contextless" () -> ^Resource { return engine_get_resource_singleton() }
resource_handle_kind   :: proc "contextless" (h: ^Handle, type: ResourceType) -> bool { return h.type == type}        



resource_setup :: proc()
{
	r                        := resource_get_singleton()
	// r.canvas2d_manager = engine_new(Canvas2DManager)
	r.texture_manager         = engine_new(TextureManager)
	r.render_texture_manager  = engine_new(RenderTextureManager)
	// r.font_manager     = engine_new(FontManager)
}




rendering_predelete_handle :: proc(h: ^Handle)
{
	switch h.type
	{
		case .NONE    :
		// case .CANVAS2D:  canvas_predelete(h)

		// case .SOUND:        sound_predelete(h)

		// case .IMAGE:        image_predelete(h)

		// case .VIEWPORT:

		case .TEXTURE        :	texture_predelete(h)
		case .RENDER_TEXTURE :  render_texture_predelete(h)
		// case .FONT   :  font_predelete(h)	
	}
}

rendering_load :: proc(h: ^Handle, load_command: ^LoadResource)
{
	switch h.type
	{
		case .NONE    :
		case .TEXTURE :        texture_load(h,load_command.path)
		case .RENDER_TEXTURE : render_texture_load(h,load_command.width,load_command.height)	
		// case .FONT    : font_load(h,path)
	}
}