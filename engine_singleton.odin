package OEngine


Engine :: struct
{
	project_singleton      : ^Project,
	rendering_singleton    : ^Rendering,
	resource_singleton     : ^Resource,
	notification_singleton : ^Notification,
	editor_singleton       : ^Editor,
	page_manager           : ^PageManager,
	render_tree            : ^RenderTree,
	arena                  :  Arena,
	can_exit               :  bool
}

@(private="file") engine_singleton : Engine


// Nota(jstn): inicializa os singleton's
engine_init  :: proc()
{
	init_arena(engine_get_arena())

	engine                       := engine_get_singleton()
	engine.project_singleton      = engine_new(Project)
	engine.rendering_singleton    = engine_new(Rendering)
	engine.resource_singleton     = engine_new(Resource)
	engine.notification_singleton = engine_new(Notification)
	engine.editor_singleton       = engine_new(Editor)
	engine.page_manager           = engine_new(PageManager)
	engine.render_tree            = engine_new(RenderTree)



	// singleton's setup
	project_setup()
	rendering_setup()
	resource_setup()
	editor_setup()

	// 
	page_manager_init()
	render_tree_init(engine_get_main_render_tree())

	// rendering_init()
	// project_init()
	// editor_init()
	// // scripting_init()
	// resource_init()
}


// engine_setup_singletons   :: proc()
// {
// 	project_setup()
// 	// scripting_setup()	
// 	rendering_setup()
// }


engine_deinit :: proc()
{	
	// resource_deinit()
	rendering_deinit()

	// editor_deinit()

	// project_deinit()
	// scripting_deinit()

	arena_free_all(engine_get_arena())
	arena_destroy(engine_get_arena())
}


engine_get_singleton               :: proc "contextless" () -> ^Engine        { return &engine_singleton }
engine_get_project_singleton       :: proc "contextless" () -> ^Project       { return engine_get_singleton().project_singleton }
engine_get_rendering_singleton     :: proc "contextless" () -> ^Rendering     { return engine_get_singleton().rendering_singleton }
engine_get_resource_singleton      :: proc "contextless" () -> ^Resource      { return engine_get_singleton().resource_singleton }
engine_get_notification_singleton  :: proc "contextless" () -> ^Notification  { return engine_get_singleton().notification_singleton }
engine_get_editor_singleton        :: proc "contextless" () -> ^Editor        { return engine_get_singleton().editor_singleton }
engine_get_page_manager            :: proc "contextless" () -> ^PageManager   { return engine_get_singleton().page_manager }
engine_get_main_render_tree        :: proc "contextless" () -> ^RenderTree    { return engine_get_singleton().render_tree }


engine_get_arena      :: proc "contextless" () -> ^Arena  { return &engine_get_singleton().arena }
engine_get_can_exit   :: proc "contextless" () -> bool    { return engine_get_singleton().can_exit }

engine_set_can_exit   :: proc "contextless" (value: bool) { engine_get_singleton().can_exit = value }
engine_get_allocator  :: proc () -> Allocator  { return get_arena_allocator(engine_get_arena()) }

engine_new            :: proc( $T: typeid ) -> ^T           { return new(T,engine_get_allocator()) }
engine_make           :: proc( $T: typeid, len: int ) -> T { return make(T,len,engine_get_allocator()) }



// // Nota(jstn): actualização por frame
// engine_update_singletons  :: proc()
// {

// 	rendering_update()
// }