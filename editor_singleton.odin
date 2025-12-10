package OEngine

import rl "vendor:Raylib"

Editor :: struct
{
	partiton_a  : Partition,
	partiton_aa : Partition,

	// 
	scene_tree  : ^TreeView(u8)
}


editor_setup :: proc()
{
	e               := engine_get_editor_singleton()
	allocator       := engine_get_allocator()

	// t := treeview_make(allocator,u8) 
	// treeview_make_root(t)

	// // 
	// root := treeview_get_root(t)
	// ti0  := treeitem_make(t)
	// ti1  := treeitem_make(t)
	// ti2  := treeitem_make(t)

	// // 
	// treeitem_set_parent(t,root,ti0)
	// treeitem_set_parent(t,ti0,ti1)
	// treeitem_set_parent(t,root,ti2)

	// Aloca arvore de renderização
	e.scene_tree     = treeview_make(0,256,u8,allocator)
	treeview_make_root(e.scene_tree)

	// 
	partiton_a      := &e.partiton_a
	partiton_aa     := &e.partiton_aa
	scene_tree      := e.scene_tree

	partition_default_init(partiton_a,1,5,project_get_window_rect())
	partition_default_init(partiton_aa,3,1,partition_get_cell(partiton_a,0,4))

	r               := partition_get_cell(partiton_aa,false,0,0,1,2)
	// scroll           := scene_tree.scroll
	// scroll.content    = Rectangle{r.x,r.y, auto_cast (1 << 8), r.height}
	// scroll.area       = Rectangle{r.x,r.y, r.width ,r.height}
	// tree_update_root_area(scene_tree)

	// for i in 0..< 1_000 do tree_view_push(scene_tree,treeitem_make("Angola",allocator))
	

	// partition_update_sizes(partiton_aa,true,true,0.01,0.01)
}

@(deferred_none=rl.EndTextureMode)
editor_mode   :: proc()
{
	// render   := rendering_get_singleton()
	// rl.BeginTextureMode(render.target_textures[1].rtexture)
	// rl.ClearBackground(Color{255,255,255,0})
}




// Nota(jstn): função principal de renderização do editor
editor_flush  :: proc()
{
	editor_mode()

	e           := engine_get_editor_singleton()
	partiton_a  := &e.partiton_a
	partiton_aa := &e.partiton_aa
	scene_tree  := e.scene_tree

	// partition_debug_draw(partiton_a,Color{0,255,0,255})
	// partition_debug_draw(partiton_aa,Color{0,0,255,255})

	// rl.DrawRectangleRec(partition_get_cell(partiton_a,0,4),Color{255,0,0,255})

	// println("==============================> ",)

	// rl.GuiPanel(partition_get_cell(partiton_aa,false,0,0,1,2),"TreeView")

	tree_scene_render :: proc(t: ^TreeView($T), unit_rect : Rectangle, unit_offset : Vec2)
	{
		root   := treeview_get_root(t)
		tih    := root

		level  := 0
		rect   := unit_rect
		arect  := rect
		x0     := rect.x

		for treeview_is_valid_treeviewhandle(t,tih)
		{
			ti := treeitem_get(t,tih)

			{
				_offset      := unit_offset.x*f32(level)
				rect.x        = x0+_offset
				rect.y       += unit_offset.y
				
				arect.height += unit_offset.y
				// arect.width   = max(arect.width,rect.width+_offset)

				// rl.DrawRectangleLinesEx(rect,1.0,rl.Color{255,0,255,255})
				// rl.DrawRectangleLinesEx(arect,1.0,rl.Color{255,255,0,255})

				// if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) 
				// {
				// 	// t.drag_pos = rl.GetMousePosition()
				// 	// if rectangle_contains(&varea,&t.drag_pos) do t.dragging = true
				// }

				if rl.GuiLabelButton(rect,"") {
					treeitem_set_expanded(t,tih,!ti.expanded)
				} 
			}

			// //////////////////////////
			// Nota(jstn):o root sempre é chamado
				   callback  := ti.callback
				if callback  != nil do callback(tih,rect,ti.expanded)
			// /////////////////////////



			// 1. Começa pelos filhos
			if ti.expanded && treeview_is_valid_treeviewhandle(t,ti.children) { 
				tih    = ti.children
				level += 1
				continue 
			}

			// 2. Avança pelos irmãos
			if treeview_is_valid_treeviewhandle(t,ti.next) { tih = ti.next ; continue }		

			// 3. sobe para o pai
			for treeview_is_valid_treeviewhandle(t,tih) && !treeview_is_valid_treeviewhandle(t,ti.next) {
		 		tih    = ti.parent
				ti     = treeview_is_valid_treeviewhandle(t,tih) ? treeitem_get(t,tih): nil
				level -= 1
			}

			// 4. seus tios
			if treeview_is_valid_treeviewhandle(t,tih) do tih = ti.next				
		}
	}


	// tree_scene_render(scene_tree,Rectangle{100,40,16,32},Vec2{12,16})
}
