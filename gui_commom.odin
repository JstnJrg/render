package OEngine

import rl "vendor:Raylib"

GuiType      :: enum
{
	BUTTON
}

Gui          :: struct
{
	update : proc(area: Rectangle, gui: ^Gui),
	area   : Rectangle,
	type   : GuiType
}


gui_begin_scissor_mode  :: proc{gui_begin_scissor_mode0,gui_begin_scissor_mode1}


gui_begin_scissor_mode0 :: proc "contextless" (area : ^Rectangle) {
	rl.BeginScissorMode(i32(area.x),i32(area.y),i32(area.width),i32(area.height))
}

gui_begin_scissor_mode1 :: proc "contextless" (g : ^Gui)
{
	area := &g.area
	rl.BeginScissorMode(i32(area.x),i32(area.y),i32(area.width),i32(area.height))
}

gui_end_scissor_mode   :: proc "contextless" () { rl.EndScissorMode() }


rectangle_contains  :: proc{rectangle_contains1,rectangle_contains2} 

rectangle_contains1 :: proc(r: ^Rectangle, point: ^Vec2) -> bool
{
	result := point.x < r.x || point.y < r.y || point.x >= (r.x+r.width) || point.y >= (r.y+r.height)
	return !result
}


// enclosing ( r0 envolve completamente r1)
rectangle_contains2 :: proc(r0,r1: ^Rectangle) -> bool
{
	result := r1.x >= r0.x && r1.y >= r0.y && (r1.x+r1.width < r0.x+r0.width) && (r1.y+r1.height < r0.y+r0.height)   
	return result
}


overlaps :: proc(r0,r1: ^Rectangle) -> bool
{
	result := r0.x < r1.x+r1.width &&  r0.x+r0.width >= r1.x && r0.y < r1.y+r1.height && r0.y+r0.height >= r1.height  
	return result
}


rectangle_intersects :: #force_inline proc "contextless" (r0,r1: ^Rectangle, include_borders:= true) -> bool
{
	position0   := Vec2{r0.x,r0.y}
	size0  	    := Vec2{r0.width,r0.height}

	position1   := Vec2{r1.x,r1.y}
	size1  	    := Vec2{r1.width,r1.height}

	if include_borders
	{
		if position0.x > position1.x+size1.x do return false
		if position0.x+size0.x < position1.x do return false
		if position0.y > position1.y+size1.y do return false
		if position0.y+size0.y < position1.y do return false
	}
	else 
	{
		if position0.x >= position1.x+size1.x do return false
		if position0.x+size0.x <= position1.x do return false
		if position0.y >= position1.y+size1.y do return false
		if position0.y+size0.y <= position1.y do return false
	}
	return true
}
