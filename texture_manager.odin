package OEngine

import rl "vendor:Raylib"


Texture :: struct 
{
	texture      : rl.Texture2D,
	version      : u32,
	is_loaded    : bool
}

TextureChunk   :: struct
{
	textures           : [ResourceSettings.CHUNK_SIZE]Texture,
	textures_free      : [ResourceSettings.CHUNK_SIZE]Handle,
	texture_count      : u32,
	texture_capacity   : u32,
	free_count         : u32
}

TextureManager  :: struct
{
	chunks         : [ResourceSettings.MAX_CHUNKS]^TextureChunk,
	chunk_count    : u32,
	free_count     : u32
}



texture_create  :: proc() -> (Handle)
{
	tm           := resource_get_singleton().texture_manager
    chunk_count  := tm.chunk_count  

	if h, has    := texture_check_free(); has do return h  
	if chunk_count <= 0 do texture_grow()

	chunk_count = tm.chunk_count-1
	chunk      := tm.chunks[chunk_count]

	idx        := chunk.texture_count
	texture    := &chunk.textures[idx]

	texture_h         : Handle
	texture_h.index   = chunk.texture_count
	texture_h.version = texture.version
	texture_h.chunk   = chunk_count
	texture_h.type    = .TEXTURE

	chunk.texture_count += 1

	assert(chunk.texture_count <= (2 << 16)-1,"TextureID overflow.")
	assert(texture.version     <= (2 << 16)-1,"TextureID Version overflow.")

	if chunk.texture_count >= u32(ResourceSettings.CHUNK_SIZE) do texture_grow()
	return texture_h
}

texture_grow :: proc()
{
	tm                    := resource_get_singleton().texture_manager
    chunk_count           := tm.chunk_count

    if chunk_count >= u32(ResourceSettings.MAX_CHUNKS) do assert(false,"increase max chunk [Texture]") 

    tm.chunks[chunk_count] = new(TextureChunk,engine_get_allocator()) 
    tm.chunk_count        += 1
}

texture_get           :: proc "contextless" (h: ^Handle) -> ^Texture     { return &resource_get_singleton().texture_manager.chunks[h.chunk].textures[h.index] } 
texture_get_rltexture :: proc "contextless" (h: ^Handle) -> rl.Texture2D { return resource_get_singleton().texture_manager.chunks[h.chunk].textures[h.index].texture } 


// Nota(jstn): carrega uma textura de um path
texture_load          :: proc(h: ^Handle, path: cstring)
{
	t                          := rl.LoadTexture(path)
	texture_component          := texture_get(h)
	texture_component.texture   = t
	texture_component.is_loaded = true
}

// Nota(jstn): marca a textura como livre e torna o Hanlde invalido
// mas não descarrega 
texture_predelete :: proc(h: ^Handle) {
	texture := texture_get(h)
	texture.version += 1
}

texture_free :: proc(h: ^Handle)
{
	texture_manager := resource_get_singleton().texture_manager
	chunk           := texture_manager.chunks[h.chunk]

	texture_zero(texture_get(h))

	// if chunk.free_count >= u32(ResourceSettings.CHUNK_SIZE) do return

	assert(chunk.free_count < u32(ResourceSettings.CHUNK_SIZE)," bug in texture free.")
	chunk.textures_free[chunk.free_count]    = h^
	chunk.free_count                        += 1
	texture_manager.free_count              += 1
}

texture_zero           :: proc(texture: ^Texture)
{
	rl.UnloadTexture(texture.texture)
	texture.is_loaded = false
}

texture_check_free     :: proc() -> (Handle,bool)
{
	res             := resource_get_singleton()
	texture_manager := res.texture_manager

	// Nota(jstn): como o render é quem deleta e pode estar alterando e colocando
	// na lista de frees, então protegemos.
	// se estiver ocupado, então cria um handle novo
	if !mt_try_guard(&res.mutex)       do return Handle{}, false
	if texture_manager.free_count <= 0 do return Handle{}, false

	for  i in 0..< texture_manager.chunk_count
	{
		chunk := texture_manager.chunks[i]
		(chunk.free_count > 0) or_continue

		handle         := chunk.textures_free[chunk.free_count-1]
		handle.version  = texture_get(&handle).version

		texture_manager.free_count -= 1 
		chunk.free_count          -= 1

		return handle, true
	}

	return Handle{}, false
}










