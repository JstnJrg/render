package OEngine

import rl         "vendor:Raylib"
import rgl        "vendor:Raylib/rlgl"


commands_reintepret   :: proc "contextless" (cmd: ^RenderCommand, $T: typeid) -> ^T { return (^T)(cmd) }


draw_circle           :: proc(_: ^Viewport, command: ^RenderCommand, bg : rl.Color)
{
	circle := commands_reintepret(command,DrawCircleCommand)
	if circle.filled { rl.DrawCircleV(circle.center,circle.radius,rl.ColorAlphaBlend(bg,circle.color,circle.modulate)) ; return }
	rl.DrawCircleLinesV(circle.center,circle.radius,rl.ColorAlphaBlend(bg,circle.color,circle.modulate))
}

draw_rectangle        :: proc(_: ^Viewport, command: ^RenderCommand, bg : rl.Color)
{
	r := commands_reintepret(command,DrawRectangleCommand)
	if r.filled { rl.DrawRectangleRec(r.r,rl.ColorAlphaBlend(bg,r.color,r.modulate)); return }
	rl.DrawRectangleLinesEx(r.r,r.thick,rl.ColorAlphaBlend(bg,r.color,r.modulate))
}   

draw_line             :: proc(_: ^Viewport, command: ^RenderCommand, bg : rl.Color)
{
	line := commands_reintepret(command,DrawLineCommand)
	if line.bezier { rl.DrawLineBezier(line.pos_a,line.pos_b,line.thick,rl.ColorAlphaBlend(bg,line.color,line.modulate)); return }
	rl.DrawLineEx(line.pos_a,line.pos_b,line.thick,rl.ColorAlphaBlend(bg,line.color,line.modulate))
}


draw_texture          :: proc(_: ^Viewport, command: ^RenderCommand, bg : rl.Color)
{
	texture := commands_reintepret(command,DrawTextureCommand)
	rl.DrawTextureV(texture_get_rltexture(&texture.handle),texture.position,rl.ColorAlphaBlend(bg,texture.color,texture.modulate))
}



draw_text          :: proc(_: ^Viewport, command: ^RenderCommand, bg : rl.Color)
{
	// text := commands_reintepret(command,DrawTextCommand)
	// rl.DrawTextEx(font_get(&text.handle).font,text.text,text.position,text.font_size,text.spacing,rl.ColorAlphaBlend(bg,text.color,text.modulate))
}







// draw_button          :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui      := commands_reintepret(command,DrawButtonCommand)
// 	if rl.GuiButton(gui.rect2,gui.text) do notification_set_in_queue(buf_data,&gui.callable,.CALL)
// }

// draw_toggle          :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui      := commands_reintepret(command,DrawToggleCommand)
// 	active   := gui.active
// 	previous := active

// 	rl.GuiToggle(gui.rect2,gui.text,&active)
// 	ok       := (previous != active)

// 	if ok  do notification_set_in_queue(buf_data,&gui.callable,.CALL,nuo_variant_val(active))
// }

// draw_toggle_group      :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui       := commands_reintepret(command,DrawToggleGroupCommand)
// 	previous  := gui.active

// 	result    := rl.GuiToggleGroup(gui.rect2,gui.text,&gui.active)
// 	_bool     := (previous != gui.active)
	
// 	if _bool do notification_set_in_queue(buf_data,&gui.callable,.CALL,nuo_variant_val(int(gui.active)))
// }

// draw_toggle_slider     :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui       := commands_reintepret(command,DrawToggleGroupCommand)
// 	previous  := gui.active

// 	result    := rl.GuiToggleSlider(gui.rect2,gui.text,&gui.active)
// 	_bool     := (previous != gui.active)
	
// 	if _bool do notification_set_in_queue(buf_data,&gui.callable,.CALL,nuo_variant_val(int(gui.active)))
// }

// draw_message_box    :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui   := commands_reintepret(command,DrawMessageBoxCommand)
// 	r     := rl.GuiMessageBox(gui.rect2,gui.title,gui.message,gui.buttons)
// 	_bool := (r != -1)

// 	if _bool  do notification_set_in_queue(buf_data,&gui.callable,.CALL,nuo_variant_val(int(r)))
// }

// draw_drop_down_box  :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui       := commands_reintepret(command,DrawDropDownBoxCommand)
// 	result    := rl.GuiDropdownBox(gui.rect2,gui.text,&gui.active,gui.edit_mode)

// 	if result  do notification_set_in_queue(buf_data,&gui.callable,.CALL,nuo_variant_val(int(gui.active)),nuo_variant_val(!gui.edit_mode))
// }

// draw_combo_box     :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui       := commands_reintepret(command,DrawToggleGroupCommand)
// 	previous  := gui.active

// 	result    := rl.GuiComboBox(gui.rect2,gui.text,&gui.active)
// 	_bool     := (previous != gui.active)
	
// 	if _bool do notification_set_in_queue(buf_data,&gui.callable,.CALL,nuo_variant_val(int(gui.active)))
// }

// draw_window_box    :: proc(buf_data: ^Viewport, command: ^RenderCommand, _ : rl.Color)
// {
// 	gui      := commands_reintepret(command,DrawButtonCommand)
// 	if rl.GuiWindowBox(gui.rect2,gui.text) != 0 do notification_set_in_queue(buf_data,&gui.callable,.CALL)
// }













// 
unload_resource       :: proc(_: ^Viewport, command: ^RenderCommand, _ : Color)
{
	// resource := commands_reintepret(command,DeleteResource)
	// res      := rendering_get_singleton()

	// mt_guard(&res.mutex)
	
	// switch resource.handle.type
	// {
	// 	// case .NONE    :
	// 	// case .CANVAS2D:
		
	// 	// case .FONT    : fallthrough
	// 	case .TEXTURE : rendering_delete_handle(&resource.handle)
	// }
}


load_resource         :: proc(_: ^Viewport, command: ^RenderCommand, _ : Color)
{
	load_data := commands_reintepret(command,LoadResource)
	rendering_load(&load_data.handle,load_data)
}
