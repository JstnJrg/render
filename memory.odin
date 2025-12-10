package OEngine
import intrinsics "base:intrinsics" 


init_arena          :: proc (arena: ^Arena, size : uint = 1*KiloByte, backing_allocator := context.allocator ) -> bool { return arena_init(arena,size,backing_allocator)  == .None }
get_arena_allocator :: proc(arena: ^Arena) -> Allocator { return arena_allocator(arena) }
deinit_arena        :: proc(arena: ^Arena) { arena_destroy(arena) }


get_buddy_allocator :: buddy_allocator
MAX_CAPACITY        :: 1*MegaByte

PageManager   :: struct 
{ 
  allocator  : Allocator,
  
  page_list  : ^Page,
  current_p  : ^Page,

  depth      : int,
  alignment  : uint
}

Page :: struct
{
  allocator  : Buddy_Allocator,
  capacity   : int,
  used       : int,
  next       : ^Page
}

Header :: struct
{
  page : uintptr
}


page_manager_init :: proc()
{
  page_manager          := engine_get_singleton().page_manager
  page_manager.allocator = engine_get_allocator()
  page_manager.alignment = 8
  begin_new_page()
}

begin_new_page :: proc(capacity := 4*KiloByte)
{
  n_capacity := capacity
  if capacity > MAX_CAPACITY do n_capacity = MAX_CAPACITY


  /* Nota(jstn): O Page vive dentro do seu buffer, então */
  page_manager := engine_get_page_manager()
  buffer       := get_buffer(n_capacity)
  buddy        : Buddy_Allocator

  buddy_allocator_init(&buddy,buffer,page_manager.alignment)

  page           := new(Page,get_buddy_allocator(&buddy))
  page.allocator  = buddy
  page.capacity   = n_capacity
  page.used      += auto_cast get_real_size(size_of(Page))

  add_page(page)
  set_current_page(page)
}

add_page :: proc(page: ^Page)
{
  // page_manager        := engine_get_page_manager()
  manager             := get_page_manager()
  manager.depth       += 1
  page.next            = manager.page_list
  manager.page_list    = page
}

set_current_page :: proc(page: ^Page) {
  get_page_manager().current_p = page
}

get_buffer :: proc(capacity: int) -> []u8
{
  manager          := get_page_manager()
  bsize            := capacity
  alignment_passed := manager.alignment
  alignment        := max(alignment_passed,size_of(Buddy_Block))

  bake_buffer    := make([dynamic]u8,bsize+int(alignment),manager.allocator)
  raw_buffer     := raw_data(bake_buffer[:])

  ptr_int        := uintptr(raw_buffer)
  aligned_int    := (ptr_int+uintptr(alignment-1)) & ~(uintptr(alignment-1))
  aligned_buffer := from_ptr(cast(^u8)(aligned_int),bsize)

  return aligned_buffer
}

maneger_get_allocator :: #force_inline proc() -> Allocator             { return get_buddy_allocator(&get_page_manager().current_p.allocator) }
maneger_get_page      :: #force_inline proc "contextless" () -> ^Page  { return get_page_manager().current_p }
page_get_allocator    :: #force_inline proc (page: ^Page) -> Allocator { return get_buddy_allocator(&page.allocator) }


get_buddy             :: #force_inline proc "contextless" () -> ^Buddy_Allocator { return &maneger_get_page().allocator }
get_page_manager      :: #force_inline proc "contextless" () -> ^PageManager { return engine_get_page_manager() }
get_actual_page       :: #force_inline proc "contextless" () -> ^Page { return engine_get_page_manager().page_list }
get_real_size         :: #force_inline proc "contextless" (#any_int N : uint) -> uint { return 1 << (size_of(uint) * 8 - intrinsics.count_leading_zeros(N+16)) }
get_depth             :: #force_inline proc "contextless" () -> int { return get_page_manager().depth }

// get_page_with_allocator ::#force_inline proc "contextless"() -> (^page,Allocator) { 
//   return
// }

smallnew              :: proc ($T: typeid, r_count := 0, max_recursion := 16) -> (^T , ^Page)                   
{ 
  manager     := get_page_manager()
  page        := get_actual_page()
  p           := new(T,get_buddy_allocator(&page.allocator))
  actual_size : int = auto_cast get_real_size(size_of(T))
  
  if p != nil { page.used += actual_size; return p, page }

  page_n     := page.next
  for page_n != nil
  {
  	if actual_size <= page_n.capacity-page_n.used 
  	{   p     = new(T,get_buddy_allocator(&page_n.allocator))
  		if p != nil
  		{
  			page_n.used += actual_size
  			return p, page_n
  		}
  	}
  	page_n = page_n.next
  }

  assert(r_count <= max_recursion,"[ PAGED ALLOCATOR MAX_RECURSION REACHED ]")

  // Nota(jstn): buscamos uma nova pagina
  begin_new_page(2*page.capacity)
  return smallnew(T,r_count+1)
}

smallmake :: proc ($T: typeid/[]$E , len : int , r_count := 0, max_recursion := 16) -> (T , ^Page)                   
{ 
  manager     := get_page_manager()
  page        := get_actual_page()
  p,err       := make(T,len,get_buddy_allocator(&page.allocator))
  actual_size : int = auto_cast get_real_size(len*size_of(E)+size_of(T))

  // Nota(jstn): há espaço 
  if err == .None { page.used += actual_size; return p, page }

  /* Nota(jstn): procura por uma pagina livre, e com espaço */
  page_n     := page.next
  for page_n != nil
  {
  	if actual_size <= page_n.capacity-page_n.used 
  	{   p, err = make(T,len,get_buddy_allocator(&page_n.allocator))
  		if err == .None
  		{
  			page_n.used += actual_size
  			return p, page_n
  		}
  	}
  	page_n = page_n.next
  }

  assert(r_count <= max_recursion,"[ PAGED ALLOCATOR MAX_RECURSION REACHED ]")

  // Nota(jstn): buscamos uma nova pagina
  begin_new_page(2*page.capacity)
  return smallmake(T,len,r_count+1)
}

memfree  :: proc{memfree1,memfree2}

memfree1 :: #force_inline proc (L: ^$T) 
{ 
	page      := get_actual_page()
	page.used -= auto_cast get_real_size(size_of(T))
	buddy_allocator_free(get_buddy(),L) 
}

memfree2 :: #force_inline proc (L: ^$T, page: ^Page) { 
	page.used -= auto_cast get_real_size(size_of(T))
	buddy_allocator_free(&page.allocator,L) 
}

memdelete  :: proc{memdelete1,memdelete2}

memdelete1 :: #force_inline proc (T: []$E) 
{ 
	page      := get_actual_page()
	page.used -= auto_cast get_real_size(len(T)*size_of(E)+size_of(T))
	delete(T,page_get_allocator(page)) 
}

memdelete2 :: #force_inline proc (T: []$E, page: ^Page) 
{ 
	page.used -= auto_cast get_real_size(len(T)*size_of(E)+size_of(T))
	delete(T,page_get_allocator(page)) 
}


// create_T :: proc($T: typeid, type : VariantType) -> ^T 
// {
//   obj, page    := smallnew(T)
//   obj.type      = type
//   obj.ref_count = 1
//   obj.ptr       = page
//   gc_set_in_list(obj)
//   return obj
// }
