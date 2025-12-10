package OEngine

import rl         "vendor:Raylib"
import rand       "core:math/rand"


Sprite2D :: struct
{
	texture : Handle,
	dir      : Vec2,
	position : Vec2,
	color    : Color,
	radius   : f32,
	speed    : f32,
}






// Nota(jstn): função de setup para sprite2D, se é invocado, então
// é porque é um sprite2D
sprite_2d_make_interface :: proc(th: TreeViewHandle) -> ^RenderInterface
{
	_process :: proc(call_type: CallInterface, ri: ^RenderInterface, data: rawptr)
	{
		#partial switch call_type
		{
			case ._INIT:

				context.random_generator = rand.xoshiro256_random_generator()

				sprite        := (^Sprite2D)(data)
				// sprite.texture = texture_create()
				// commands_push_load_resource(rendering_get_logic_index(),sprite.texture,path)

				sprite.speed   = rand.float32_range(300,1000)
				sprite.dir     = Vec2{rand.float32(),rand.float32()}
				sprite.position= Vec2{100,100}
				sprite.radius  = rand.float32_range(5,30)
				sprite.color   = Color{auto_cast rand.int31_max(256),auto_cast rand.int31_max(256),auto_cast rand.int31_max(256),255}

			case ._PROCESS:

				dot     :: proc(a,b: Vec2) -> f32  { r := a*b; return r.x+r.y }
				reflect :: proc(a,n: Vec2)   -> Vec2 { return a-2*dot(a,n)*n} 

				r      :     = project_get_window_rect()
				delta  : f32 = auto_cast rl.GetFrameTime()

				sprite        := (^Sprite2D)(data)

				// println("*****************************> ",sprite)

				sprite.position += sprite.dir*sprite.speed*0.0166678//*(delta)
				position   := sprite.position
				radius     := sprite.radius

				if position.x+radius >= r.width do sprite.dir = reflect(sprite.dir,Vec2{-1,0})
				else if position.x-radius <= 0  do sprite.dir = reflect(sprite.dir,Vec2{1,0})

				if position.y+radius >= r.height do sprite.dir = reflect(sprite.dir,Vec2{0,-1})
				else if position.y-radius <= 0   do sprite.dir = reflect(sprite.dir,Vec2{0,1})

				// // println("********************> ",sprite.position)

				// println("***********************")
				commands_push_circle(render_tree_get_current_watcher(),3,position,radius,sprite.color,true)

				// draw_texture_command(rendering_get_logic_index(),3,sprite.texture,sprite.position,sprite.color)
		
				// rl.DrawCircleV(position,radius,sprite.color)
		}

	}

	interface, page       := smallnew(RenderInterface)
	interface.page         = page
	interface.handle       = th

	interface.data         = new(Sprite2D,engine_get_allocator())
	interface._call_handle = _process

	return interface
}

