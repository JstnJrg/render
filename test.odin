package OEngine

import rl         "vendor:Raylib"
import rand       "core:math/rand"

TEST :: !true
// path :: "icon.png"

h    : Handle


Ball :: struct
{
	dir      : Vec2,
	position : Vec2,
	color    : Color,
	radius   : f32,
	speed    : f32,
}


balls : [10_000]Ball


ball_init :: proc()
{

	// h   = texture_create()
	// idx := rendering_get_logic_index()

	// commands_push_load_resource(idx,h,path)
	context.random_generator = rand.xoshiro256_random_generator()

	for &b in balls
	{
		// println("**************************************************> ",b,rand.float32())
		b.speed    = rand.float32_range(300,1000)
		b.dir      = Vec2{rand.float32(),rand.float32()}
		b.position = Vec2{100,100}
		b.radius   = rand.float32_range(5,30)
		b.color    = Color{auto_cast rand.int31_max(256),auto_cast rand.int31_max(256),auto_cast rand.int31_max(256),255}
	}
}




test_flush ::  proc()
{
	dot     :: proc(a,b: Vec2) -> f32  { r := a*b; return r.x+r.y }
	reflect :: proc(a,n: Vec2)   -> Vec2 { return a-2*dot(a,n)*n} 

	r      := project_get_window_rect()
	delta  : f32 = auto_cast rl.GetFrameTime()

	for &b in balls
	{
		// commands_push_circle(
		// 	rendering_get_logic_index(),
		// 	3,
		// 	b.position,
		// 	b.radius,
		// 	b.color,
		// 	true
		// 	)

		// draw_texture_command(
		// 	rendering_get_logic_index(),
		// 	3,
		// 	h,
		// 	b.position,
		// 	b.color,
		// 	// true
		// 	)


		// commands_push_circle (
		// 	rendering_get_logic_index(),
		// 	3,
		// 	b.position,
		// 	12.0,
		// 	b.color,
		// 	true
		// 	// true
		// 	)

		b.position += b.dir*b.speed*(delta)
		position   := b.position
		radius     := b.radius

		if position.x+radius >= r.width do b.dir = reflect(b.dir,Vec2{-1,0})
		else if position.x-radius <= 0  do b.dir = reflect(b.dir,Vec2{1,0})

		if position.y+radius >= r.height do b.dir = reflect(b.dir,Vec2{0,-1})
		else if position.y-radius <= 0   do b.dir = reflect(b.dir,Vec2{0,1})


		rl.DrawCircleV(position,radius,b.color)
	}

}