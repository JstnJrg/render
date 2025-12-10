package OEngine

import rl "vendor:Raylib"



RenderTexture :: struct  
{
	rtexture     : rl.RenderTexture,
	rectangle    : Rectangle,
	version      : u32,
	is_loaded    : bool
}


RenderTextureChunk   :: struct
{
	render_textures           : [ResourceSettings.CHUNK_SIZE]RenderTexture,
	render_textures_free      : [ResourceSettings.CHUNK_SIZE]Handle,
	render_texture_count      : u32,
	render_texture_capacity   : u32,
	free_count                : u32
}

RenderTextureManager  :: struct
{
	chunks         : [ResourceSettings.MAX_CHUNKS]^RenderTextureChunk,
	chunk_count    : u32,
	free_count     : u32
}



render_texture_create  :: proc() -> (Handle)
{
	rtm          := resource_get_singleton().render_texture_manager
    chunk_count  := rtm.chunk_count  

	if h, has    := render_texture_check_free(); has do return h  
	if chunk_count <= 0 do render_texture_grow()

	chunk_count = rtm.chunk_count-1
	chunk      := rtm.chunks[chunk_count]

	idx         := chunk.render_texture_count
	rtexture    := &chunk.render_textures[idx]

	rtexture_h         : Handle
	rtexture_h.index   = chunk.render_texture_count
	rtexture_h.version = rtexture.version
	rtexture_h.chunk   = chunk_count
	rtexture_h.type    = .RENDER_TEXTURE

	chunk.render_texture_count += 1

	assert(chunk.render_texture_count <= (2 << 16)-1,"RenderTextureID overflow.")
	assert(rtexture.version     <= (2 << 16)-1,"RenderTextureID Version overflow.")

	if chunk.render_texture_count >= u32(ResourceSettings.CHUNK_SIZE) do render_texture_grow()
	return rtexture_h
}

render_texture_grow :: proc()
{
	rtm                   := resource_get_singleton().render_texture_manager
    chunk_count           := rtm.chunk_count

    if chunk_count >= u32(ResourceSettings.MAX_CHUNKS) do assert(false,"increase max chunk [RenderTexture]") 

    rtm.chunks[chunk_count] = new(RenderTextureChunk,engine_get_allocator()) 
    rtm.chunk_count        += 1
}

render_texture_get           :: proc "contextless" (h: ^Handle) -> ^RenderTexture { return &resource_get_singleton().render_texture_manager.chunks[h.chunk].render_textures[h.index] } 

// Nota(jstn): carrega uma textura de um path
render_texture_load          :: proc(h: ^Handle, #any_int width, height: i32) {
	rtexture_component          := render_texture_get(h)
	rtexture_component.rtexture  = rl.LoadRenderTexture(width,height)
	rtexture_component.rectangle = Rectangle{0,0,auto_cast width,auto_cast height}
	rtexture_component.is_loaded = true
}

// Nota(jstn): marca a textura como livre e torna o Hanlde invalido
// mas não descarrega 
render_texture_predelete :: proc(h: ^Handle) {
	rtexture := render_texture_get(h)
	rtexture.version += 1
}

render_texture_free :: proc(h: ^Handle)
{
	render_texture_manager := resource_get_singleton().render_texture_manager
	chunk                  := render_texture_manager.chunks[h.chunk]

	render_texture_zero(render_texture_get(h))

	// if chunk.free_count >= u32(ResourceSettings.CHUNK_SIZE) do return

	assert(chunk.free_count < u32(ResourceSettings.CHUNK_SIZE)," bug in texture free.")
	chunk.render_textures_free[chunk.free_count]    = h^
	chunk.free_count                        += 1
	render_texture_manager.free_count       += 1
}

render_texture_zero           :: proc(rtexture: ^RenderTexture) {
	rl.UnloadRenderTexture(rtexture.rtexture)
	rtexture.is_loaded = false
}

render_texture_check_free     :: proc() -> (Handle,bool) {

	res                    := resource_get_singleton()
	render_texture_manager := res.render_texture_manager

	// Nota(jstn): como o render é quem deleta e pode estar alterando e colocando
	// na lista de frees, então protegemos.
	// se estiver ocupado, então cria um handle novo
	if !mt_try_guard(&res.mutex)              do return Handle{}, false
	if render_texture_manager.free_count <= 0 do return Handle{}, false

	for  i in 0..< render_texture_manager.chunk_count
	{
		chunk := render_texture_manager.chunks[i]
		(chunk.free_count > 0) or_continue

		handle         := chunk.render_textures_free[chunk.free_count-1]
		handle.version  = render_texture_get(&handle).version

		render_texture_manager.free_count -= 1 
		chunk.free_count          -= 1

		return handle, true
	}

	return Handle{}, false
}










