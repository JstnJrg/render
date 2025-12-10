package OEngine

// Os nomes dos metodos que serão chamados
CallInterface   :: enum u8
{

	_INIT,
	_PROCESS,


	_DRAW_ICON,
}


/* 
	Nota(jstn): nos seguintes modos:
	Editor -> os itens desenharão (terão a oportunidade de desenhar seus icons)
	game   -> só a logica é desenhada
*/
RenderTreeAPi      :: enum u8 
{ 
	EDITOR, 
	GAME  
}


CallInterfaceFlags :: bit_set[CallInterface;u8]
RenderTreeApiFlags :: bit_set[RenderTreeAPi;u8]


// Uma interface que compoe o tree item
RenderInterface :: struct 
{
	_call_handle     : proc(type: CallInterface, ri: ^RenderInterface, data: rawptr ),
	page             : ^Page, //Onde foi alocado a interface
	data             : rawptr,
	handle           : TreeViewHandle
}



// Nota(jstn): responsavel por gerir a renderização, o desenho e no 
RenderTree      :: struct 
{
	watcher    : ^RenderTreeWatcher,
	scenes     : ^TreeView(^RenderInterface), //Arvore das cenas
	api        : RenderTreeApiFlags,
}



// Nota(jstn): cria um root default para o RenderTree
render_tree_init         :: proc(rt: ^RenderTree) 
{ 
	rt.scenes  = treeview_make(0,256,^RenderInterface,engine_get_allocator()) 

	//Nota(jstn): caso não foi definido, então esta no modo editor e jogo
	render_tree_set_default_api_flags(rt) 
	render_tree_make_main_watcher(rt)


	// test
	render_tree_test(rt)
}

render_tree_set_api_flags :: proc(rt: ^RenderTree, flags: RenderTreeApiFlags) { 
	rt.api = flags
}

render_tree_get_api_flags :: proc "contextless" (rt: ^RenderTree) -> RenderTreeApiFlags { 
	return rt.api
}

render_tree_set_default_api_flags :: proc(rt: ^RenderTree) { 
	if card(rt.api) > 0 do return
	rt.api = {.EDITOR,.GAME}
}

render_tree_get_scenes :: proc "contextless" (rt: ^RenderTree) -> ^TreeView(^RenderInterface) { 
	return rt.scenes
}

render_tree_set_ri_handle :: proc "contextless" (ri: ^RenderInterface, th:TreeViewHandle){
	ri.handle = th
}


// Nota(jstn): obtem o watcher corrent
render_tree_get_current_watcher       :: proc {render_tree_get_current_watcher1,render_tree_get_current_watcher2}
render_tree_get_current_watcher1      :: proc "contextless" (rt: ^RenderTree) -> ^RenderTreeWatcher { return rt.watcher }
render_tree_get_current_watcher2      :: proc "contextless" () -> ^RenderTreeWatcher { return render_tree_get().watcher }


// Nota(jstn): seta um watcher corrent, como actual
render_tree_current_watcher :: proc "contextless" (rt: ^RenderTree, watcher: ^RenderTreeWatcher) { 
	watcher.enclosing = rt.watcher
	rt.watcher        = watcher
}

render_tree_get :: proc "contextless" () -> ^RenderTree  { return engine_get_main_render_tree() }

/* 
	Nota(jstn): cria a viewport raiz, a principal, usada para o render
	principal
*/
render_tree_make_main_watcher :: proc(rt: ^RenderTree) {
	t    := render_tree_get_scenes(rt)
	root := treeitem_make(t)

	treeview_set_root(t,root)
	treeview_set_data_unsafe(t,root,watcher_main_interface(root))

	ri := treeview_get_data_unsafe(t,root)
	render_tree_current_watcher(rt,(^RenderTreeWatcher)(ri.data))
}

/* Nota(jstn): transfere seus comandos para a viewport */
render_tree_send_commands  :: proc(rt: ^RenderTree) 
{
	watcher            := render_tree_get_current_watcher(rt)
	frame_buffer_indx  := watcher.fbindx

	viewport           := rendering_get_viewport(frame_buffer_indx)
	viewport.layers     = watcher.layers[frame_buffer_indx][:]
	viewport.clear      = watcher.clear
	viewport.draw_count = watcher.draw_count
	viewport.idx        = frame_buffer_indx
	viewport.bg_color   = watcher.bg_color
}




render_tree_test   :: proc(rt: ^RenderTree)
{
	t     := render_tree_get_scenes(rt)

	root  := treeview_get_root(t)


	for i in 0..<1_000
	{
		_t := treeitem_make(t)
		treeview_set_data_unsafe(t,_t,sprite_2d_make_interface(_t))
		treeitem_set_parent(t,root,_t)
	}

	// t0    := treeitem_make(t)
	// t1    := treeitem_make(t)

	// treeview_set_data_unsafe(t,t0,sprite_2d_make_interface(t0))
	// treeview_set_data_unsafe(t,t1,sprite_2d_make_interface(t1))

	// treeitem_set_parent(t,root,t0)
	// treeitem_set_parent(t,t0,t1)
}


// Nota(jstn): função que despacha, ou sabe como despachar os diferentes tipos de chamadas
render_render_tree :: proc(render_tree: ^RenderTree, flags : CallInterfaceFlags)
{

	render_tree_game_mode :: proc(render_tree: ^RenderTree, flag : CallInterface) {
		t      := render_tree_get_scenes(render_tree)
		tih    := treeview_get_root(t)

		for treeview_is_valid_treeviewhandle(t,tih){
			ti := treeitem_get(t,tih)
			ri := treeview_get_data_unsafe(t,tih)

			// Nota(jstn): quem quiser deletar o item deve guardar a sua referencia
			if ri != nil  do ri._call_handle(flag,ri,ri.data)

			// 1. Começa pelos filhos
			if treeview_is_valid_treeviewhandle(t,ti.children) { 
				tih    = ti.children
				continue 
			}

			// 2. Avança pelos irmãos
			if treeview_is_valid_treeviewhandle(t,ti.next) { tih = ti.next ; continue }		

			// 3. sobe para o pai
			for treeview_is_valid_treeviewhandle(t,tih) && !treeview_is_valid_treeviewhandle(t,ti.next) {
		 		tih    = ti.parent
				ti     = treeview_is_valid_treeviewhandle(t,tih) ? treeitem_get(t,tih): nil
			}

			// 4. seus tios
			if treeview_is_valid_treeviewhandle(t,tih) do tih = ti.next				
		}
	}	

	/* Nota(jstn): esse é o coração da chamada */
	for mode in render_tree_get_api_flags(render_tree)
	{
		switch mode 
		{
			case .GAME    : for flag in flags do render_tree_game_mode(render_tree,flag)
			case .EDITOR  :
		}
	}

	// Nota(jstn): pega a viewport root e seus commandos e envia para serem desenhados
	render_tree_send_commands(render_tree)
}