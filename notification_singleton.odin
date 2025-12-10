package OEngine

import rl "vendor:Raylib"


NotificationType :: enum 
{
	WINDOW_SIZE_CHANGED
}


NotificationData :: struct 
{
	callback  : proc(what: NotificationType),
	head,tail : ^NotificationData
}



Notification        :: struct {
	notifications : [RenderingSettings.BUFFER_MAX]^NotificationData,
	// dispatch      : []
}


// notification_push   :: proc(vid: int, what: NotificationType)
// {
// 	allocator           := rendering_get_viewport_allocator(idx)
// 	notifications       := engine_get_notification_singleton()
		

// 	if layer.head == nil
// 	{
// 		layer.head = command
// 		layer.tail = command
// 		return
// 	}

// 	layer.tail.next = command
// 	layer.tail      = command
// }