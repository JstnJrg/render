package OEngine

import rl "vendor:Raylib"

Partition :: struct
{
	using _        : Gui,
	rect           : Rectangle,
	line, column   : int,
	size           : Vec2,
}





// Panel                :: struct
// {
// 	rectangle    : rl.Rectangle,
// 	line,column  : int,
// 	size_x,size_y: f32
// }



partition_default_init :: proc(p: ^Partition, line : int = 1, column : int = 1, area := Rectangle{0,0,128,64})
{
	p.area   = area
	p.update = partition_update
	p.line   = column
	p.column = line

	partition_update_sizes(p,true,true,0.01,0.01)
}

partition_update     :: proc(area: Rectangle, p : ^Gui)
{
	p.area = area
	partition_update_sizes((^Partition)(p),true,0.01,0.01)
}



partition_draw       :: proc(p: ^Partition)
{
	rl.DrawRectangleLinesEx(p.area,2.0,rl.GREEN)
	partition_debug_draw(p,rl.RED)
	rl.DrawRectangleLinesEx(partition_get_cell(p,true,0,1,5,1),2.0,rl.BLUE)
}



partition_set_region :: proc "contextless" (p: ^Partition, r: rl.Rectangle)  { p.area = r }

partition_set_update        :: proc "contextless" (p: ^Partition, fn : proc(area: Rectangle, gui: ^Gui))  { p.update = fn }

partition_set_line_column   :: proc(p: ^Partition, line,column: int)
{
	p.line    = line
	p.column  = column
}

partition_update_sizes   :: proc{partition_update_sizes1,partition_update_sizes2,partition_update_sizes3}

partition_update_sizes1  :: proc(p: ^Partition, ratio_x := f32(0.4) , ratio_y := f32(0.4), offset_x := f32(0), offset_y := f32(0))
{ 
	rectangle  := p.area

	position_x := rectangle.width*ratio_x
	position_y := rectangle.height*ratio_y
	
	width      := rectangle.width*(1.0-ratio_x)
	height     := (rectangle.height)*(1.0-ratio_y)

	rectangle   = rl.Rectangle{position_x+offset_x,position_y+offset_y,width-2*offset_x,height-2*offset_y}

	p.rect      = rectangle
	p.size      = Vec2{rectangle.width/f32(p.line),rectangle.height/f32(p.column)}
}

partition_update_sizes2  :: proc(p: ^Partition, _ : bool, ratio_x := f32(0.4) , ratio_y := f32(0.4))
{ 
	rectangle  := p.area

	position_x := rectangle.width*ratio_x
	position_y := rectangle.height*ratio_y
	
	width      := rectangle.width*(1.0-ratio_x)
	height     := (rectangle.height)*(1.0-ratio_y)

	rectangle   = rl.Rectangle{position_x,position_y,width-position_x,height-position_y}

	p.rect      = rectangle
	p.size      = Vec2{rectangle.width/f32(p.line),rectangle.height/f32(p.column)}
}


partition_update_sizes3  :: proc(p: ^Partition, _,_ : bool, ratio_x := f32(0.4) , ratio_y := f32(0.4))
{ 
	rectangle  := p.area

	position_x := rectangle.width*ratio_x
	position_y := rectangle.height*ratio_y
	
	width      := rectangle.width*(1.0-ratio_x)
	height     := (rectangle.height)*(1.0-ratio_y)

	rectangle   = rl.Rectangle{position_x+rectangle.x,position_y+rectangle.y,width-position_x,height-position_y}

	p.rect      = rectangle
	p.size      = Vec2{rectangle.width/f32(p.line),rectangle.height/f32(p.column)}
}

partition_get_cell  :: proc{partition_get_cell1,partition_get_cell2,partition_get_cell3}

partition_get_cell1 :: proc(p: ^Partition, x, y : int) -> Rectangle
{
	rectangle := p.rect
	size_x    := p.size.x
	size_y    := p.size.y

	return  Rectangle{rectangle.x+size_x*f32(y),rectangle.y+size_y*f32(x),size_x,size_y}
}

partition_get_cell2 :: proc(p: ^Partition, x,y :int, offset_x := f32(0), offset_y := f32(0)) -> Rectangle
{
	rectangle := p.rect
	size_x    := p.size.x
	size_y    := p.size.y

	return  rl.Rectangle{rectangle.x+offset_x+size_x*f32(y),rectangle.y+offset_y+size_y*f32(x),size_x-2*offset_x,size_y-2*offset_y}
}


partition_get_cell3 :: proc(p: ^Partition, _: bool, x0,y0,x1,y1 :int ) -> Rectangle
{
	r         := partition_get_cell(p,x0,y0)
	r.width   *= f32(x1)
	r.height  *= f32(y1)
	return r
}



partition_debug_draw :: proc(p: ^Partition, color : rl.Color)
{ 
	rectangle := p.rect
	size_x    := p.size.x
	size_y    := p.size.y

	// size_x    := rectangle.width/f32(gui.line)
	// size_y    := rectangle.height/f32(gui.column)

	// rl.DrawRectangleLinesEx(gui.rectangle,3.0,rl.GREEN)

	// fmt.println("******************************> ",p.line,p.column)

	for x in 0..< p.line
	{
		for y in 0..< p.column
		{
			r := rl.Rectangle{rectangle.x+size_x*f32(x),rectangle.y+size_y*f32(y),size_x,size_y}
			rl.DrawRectangleLinesEx(r,2.0,color)

		}
	}
}

// gui_update_rects_yx :: proc(gui: ^Panel)
// { 
// 	rectangle := gui.rectangle

// 	size_x    := rectangle.width/f32(gui.column)
// 	size_y    := rectangle.height/f32(gui.line)

// 	for y in 0..< gui.line
// 	{
// 		for x in 0..< gui.column
// 		{
// 			//gui.rects[x][y] = rl.Rectangle{rectangle.x+size_x*f32(x),rectangle.y+size_y*f32(y),size_x,size_y}
// 		}
// 	}
// }


// gui_debug_draw :: proc(gui: ^Panel)
// {
// 	for x in 0..< gui.line
// 	{
// 		for y in 0..< gui.column 
// 		{
// 			// rl.DrawRectangleLinesEx(gui.rects[x][y],3.0,rl.BLUE)
// 		}
// 	}

// 	rl.DrawRectangleLinesEx(gui.rectangle,3.0,rl.GREEN)
// }

// gui_debug_draw_yx :: proc(gui: ^Panel)
// {

// 	for y in 0..< gui.line
// 	{
// 		for x in 0..< gui.column 
// 		{
// 			//rl.DrawRectangleLinesEx(gui.rects[x][y],3.0,rl.BLUE)
// 		}
// 	}

// 	rl.DrawRectangleLinesEx(gui.rectangle,3.0,rl.GREEN)

// }




// rectangle_contains  :: proc{rectangle_contains1,rectangle_contains2} 


// rectangle_contains1 :: proc(r: ^Rectangle, point: ^Vec2) -> bool
// {
// 	result := point.x < r.x || point.y < r.y || point.x >= (r.x+r.width) || point.y >= (r.y+r.height)
// 	return !result
// }


// // enclosing ( r0 envolve completamente r1)
// rectangle_contains2 :: proc(r0,r1: ^Rectangle) -> bool
// {
// 	result := r1.x >= r0.x && r1.y >= r0.y && (r1.x+r1.width < r0.x+r0.width) && (r1.y+r1.height < r0.y+r0.height)   
// 	return result
// }


// overlaps :: proc(r0,r1: ^Rectangle) -> bool
// {
// 	result := r0.x < r1.x+r1.width &&  r0.x+r0.width >= r1.x && r0.y < r1.y+r1.height && r0.y+r0.height >= r1.height  
// 	return result
// }


// rectangle_intersects :: #force_inline proc "contextless" (r0,r1: ^Rectangle, include_borders:= true) -> bool
// {
// 	position0   := Vec2{r0.x,r0.y}
// 	size0  	    := Vec2{r0.width,r0.height}

// 	position1   := Vec2{r1.x,r1.y}
// 	size1  	    := Vec2{r1.width,r1.height}

// 	if include_borders
// 	{
// 		if position0.x > position1.x+size1.x do return false
// 		if position0.x+size0.x < position1.x do return false
// 		if position0.y > position1.y+size1.y do return false
// 		if position0.y+size0.y < position1.y do return false
// 	}
// 	else 
// 	{
// 		if position0.x >= position1.x+size1.x do return false
// 		if position0.x+size0.x <= position1.x do return false
// 		if position0.y >= position1.y+size1.y do return false
// 		if position0.y+size0.y <= position1.y do return false
// 	}
// 	return true
// }

