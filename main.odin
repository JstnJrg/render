package OEngine

import fmt "core:fmt" 
import mem "core:mem"

main :: proc()
{
	when ODIN_DEBUG
	{
		track : mem.Tracking_Allocator
		mem.tracking_allocator_init(&track,context.allocator) 
		context.allocator = mem.tracking_allocator(&track)
		
		defer
		{
			fmt.println("\n\n======================================================")

			len_0 := len(track.allocation_map)
			len_1 := len(track.bad_free_array)

			if len_0 > 0
			{
				fmt.printfln("allocation not freed: %v\n",len_0)
				for _,entry in track.allocation_map do fmt.printfln("bytes: %v\nplace: %v\n",entry.size,entry.location)
			} 

			if len_1 > 0 {
				fmt.printfln("\nincorrect frees: %v",len_1)
				for entry in track.bad_free_array do fmt.printfln("memory: %p\nlocation:%v",entry.memory,entry.location)
			}

			mem.tracking_allocator_destroy(&track)
		}
	}

	_main()
}


_main :: proc()
{
	engine_init()
	defer engine_deinit()

	rendering_update()

	// a := make(map[int]int,13,engine_get_allocator())

	// a[4]=1
	// a[0]=4
	// a[1]=6
	// append(&a,4)
	// clear(&a)

	// println("**********************************> ",a,len(a),cap(a))
}