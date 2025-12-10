package OEngine
import rl "vendor:Raylib"

TreeViewHandle :: bit_field u32
{
	pool_indx : u32 | 16,
	version   : u32 | 16
}


TreeItem         :: struct($T: typeid)
{
	parent   : TreeViewHandle,
	next     : TreeViewHandle,
	children : TreeViewHandle,

	data     : T,

	version  : u32,
	free     : bool,
	expanded : bool
}

TreeView :: struct($T: typeid)
{
	itens       : [dynamic]TreeItem(T),
	root        : TreeViewHandle,
	type        : typeid,
	free_itens  : int
}

INVALID_TREEVIEW_HANDLE :: TreeViewHandle{}


treeview_make     :: proc(len, cap : int ,$T: typeid, allocator := context.allocator) -> ^TreeView(T)
{
	t       := new(TreeView(T),allocator)
	t.itens  =  make([dynamic]TreeItem(T),len,cap,allocator)
	t.type   = T
	return t
}

treeview_make_root    :: proc(t: ^TreeView($T))              { treeview_set_root(t,treeitem_make(t))}
treeview_set_root     :: proc(t: ^TreeView($T), tih: TreeViewHandle) { t.root = tih }
treeview_get_root     :: proc(t: ^TreeView($T)) -> TreeViewHandle    { return t.root }

treeview_get_data     :: proc(t: ^TreeView($T), h: TreeViewHandle) -> T
{ 
	if treeview_is_valid_TreeViewhandle(t,h) {
		ti := treeitem_get(t,h)
		return ti.data
	}
	return nil //t.type{}t
}

treeview_get_data_unsafe :: proc(t: ^TreeView($T), h: TreeViewHandle) -> T { 
	return treeitem_get(t,h).data
}

treeview_set_data_unsafe :: proc(t: ^TreeView($T), h: TreeViewHandle , data: T) { 
	treeitem_get(t,h).data = data
}

treeview_peek_free_treeitem :: proc(t: ^TreeView($T)) -> (handle := INVALID_TREEVIEW_HANDLE, sucess := true)
{ 
	(t.free_itens > 0) or_return
	for &ti,i in t.itens do if ti.free 
	{ 
		handle = make_treeviewhandle(i,ti.version)
		break 
	}
	t.free_itens -= 1
	return
}

// treeitem_set_callback :: proc(t: ^TreeView($T), th: TreeViewHandle, callback : TreeItemCallBack ){
// 	treeitem_get(t,th).callback = callback
// }

treeitem_set_expanded :: proc(t: ^TreeView($T), th: TreeViewHandle, value : bool){
	treeitem_get(t,th).expanded = value
}

treeitem_get_prev_sibling :: proc(t: ^TreeView($T), th: TreeViewHandle) -> (handle := INVALID_TREEVIEW_HANDLE , sucess := true)
{
	treeview_is_valid_treeviewhandle(t,th)        or_return
	ti     := treeitem_get(t,th)

	treeview_is_valid_treeviewhandle(t,ti.parent) or_return
	pti    := treeitem_get(t,ti.parent)


	hchild := pti.children
	(!treeview_is_same_treeviewhandle(hchild,th)) or_return

	for treeview_is_valid_treeviewhandle(t,hchild) {
		_ti := treeitem_get(t,hchild)
		if 	treeview_is_same_treeviewhandle(_ti.next,th) do break
		hchild = _ti.next
	}

	handle = hchild
	sucess = treeview_is_valid_treeviewhandle(hchild)
	return 
}

treeitem_remove :: proc(t: ^TreeView($T), th: TreeViewHandle) -> (sucess := true)
{
	treeview_is_valid_treeviewhandle(t,th)        or_return
	ti     := treeitem_get(t,th)

	treeview_is_valid_treeviewhandle(t,ti.parent) or_return
	pti    := treeitem_get(t,ti.parent)

	pth, _ := treeitem_get_prev_sibling(t,th)

	if sucess {
		_ti     := treeitem_get(t,pth)
		_ti.next = ti.next
	}
	else do pti.next = ti.next

	ti.parent = INVALID_TREEVIEW_HANDLE
	ti.next   = INVALID_TREEVIEW_HANDLE
	return
}

treeitem_free :: proc(t: ^TreeView($T), th: TreeViewHandle) -> (sucess := true)
{
	treeview_is_valid_treeviewhandle(t,th)        or_return
	ti           := treeitem_get(t,th)
	ti.version   += 1
	ti.free       = true
	t.free_itens += 1
	return
}


treeitem_move_to   :: proc(t: ^TreeView($T), nph,th: TreeViewHandle) -> bool
{
	treeview_is_valid_treeviewhandle(t,th)     or_return
	ti    := treeitem_get(t,th)

	if treeview_is_valid_treeviewhandle(t,ti.parent) do treeitem_remove(t,th)
	return treeitem_set_parent(t,nph,th)
}

treeitem_set_parent   :: proc(t: ^TreeView($T), ph,th: TreeViewHandle) -> (sucess := true)
{
	treeview_is_valid_treeviewhandle(t,th) or_return
	treeview_is_valid_treeviewhandle(t,ph) or_return

	ti    := treeitem_get(t,th)
	pti   := treeitem_get(t,ph)
	last_child : ^TreeItem(T)

	// Nota(jstn): procura o ultimo filho
	children := pti.children

	for treeview_is_valid_treeviewhandle(t,children) {
		last_child = treeitem_get(t,children) 
		children   = last_child.next
	}

	// Nota(jstn): o ultimo filho foi encontrado
	if last_child != nil {
		ti.parent       = ph
		last_child.next = th
	}
	else {
		ti.parent       = ph
		pti.children    = th
	}

	return 
}

vreeitem_set_expanded :: proc(t: ^TreeView($T), th: TreeViewHandle, value: bool){
	treeitem_get(t,th).expanded = value
}

treeitem_is_descendant   :: proc(t: ^TreeView($T), ph,th: TreeViewHandle) -> (sucess := true)
{
	treeview_is_valid_TreeViewhandle(t,th) or_return
	treeview_is_valid_TreeViewhandle(t,ph) or_return

	ti      := treeitem_get(t,th)
	pti     := treeitem_get(t,ph)
	
	current := pti
	valid   := true

	for valid
	{
		if current == th do return true
		current    = pti.parent
		valid      = treeview_is_valid_TreeViewhandle(current) 
		pti        = valid ? treeitem_get(current): nil
	}

	return  ti.parent == pht}

vreeitem_set_callback :: proc(t: ^TreeView($T), th: TreeViewHandle, update : proc(TreeViewhandle: TreeViewHandle, rectangle: Rectangle, expanded: bool) ) -> (sucess := true)
{
	treeview_is_valid_treeviewhandle(t,th) or_return
	ti         := treeitem_get(t,th)
	ti.callback = update
	return 
}

// treeitem_call_draw_callback :: proc(ti: ^TreeItem($T)) -> (sucess: bool)
// {
// 	draw_callback  := ti.draw_callback
// 	(draw_callback != nil) or_return 
// 	draw_callback()
// 	return 
// }

treeview_is_valid_treeviewhandle  :: proc{treeview_is_valid_treeviewhandle1,treeview_is_valid_treeviewhandle2}

treeview_is_valid_treeviewhandle1 :: proc(t: ^TreeView($T), h: TreeViewHandle) -> bool
{
	// Nota(jstn): sempre começa com +1
	(h.version > 0)                   or_return
	(u32(len(t.itens)) > h.pool_indx) or_return 
	return treeitem_get(t,h).version == h.version
}

treeview_is_valid_treeviewhandle2 :: proc(h: TreeViewHandle    ) -> bool { return h.version > 0 }
treeview_is_same_treeviewhandle   :: proc "contextless" (h0,h1: TreeViewHandle) -> bool { return h0.pool_indx == h1.pool_indx && h0.version == h1.version  }


treeitem_make :: proc(t: ^TreeView($T)) -> TreeViewHandle
{
	h, sucess := treeview_peek_free_treeitem(t)
	if sucess 
	{
		ti     := treeitem_get(t,h)
		ti.free = false
		return h
	}


	itens := &t.itens
	idx   := len(itens); append(itens,TreeItem(T){})
	
	ti         := &itens[idx]
	ti.version += 1
	ti.free     = false

	return make_treeviewhandle(idx,ti.version)
}

treeitem_get :: proc(t: ^TreeView($T), h: TreeViewHandle) -> ^TreeItem(T) { return &t.itens[h.pool_indx] }


make_treeviewhandle :: proc(#any_int idx, version: u32) -> TreeViewHandle 
{ 
	h : TreeViewHandle
	h.pool_indx = idx
	h.version   = version
	return h
}




