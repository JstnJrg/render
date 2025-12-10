package OEngine

import mem      "core:mem"
import slice    "core:slice"
import runtime  "base:runtime"
import thread   "core:thread"
import sync     "core:sync"
import fmt      "core:fmt"
import time     "core:time"
import linalg   "core:math/linalg"
import rl       "vendor:Raylib"


Rectangle   :: rl.Rectangle
Vec2        :: [2]f32
Color       :: rl.Color
ConfigFlags :: rl.ConfigFlags

Byte       :: mem.Byte
KiloByte   :: mem.Kilobyte
MegaByte   :: mem.Megabyte
GigaByte   :: mem.Gigabyte
TeraByte   :: mem.Terabyte
PetaByte   :: mem.Petabyte


Allocator  :: mem.Allocator
Arena      :: runtime.Arena
Arena_Temp :: runtime.Arena_Temp
// 

arena_init            :: runtime.arena_init
arena_allocator       :: runtime.arena_allocator
arena_destroy         :: runtime.arena_destroy

arena_temp_begin      :: runtime.arena_temp_begin
arena_temp_end        :: runtime.arena_temp_end
arena_free_all        :: runtime.arena_free_all

Buddy_Block           :: mem.Buddy_Block
Buddy_Allocator       :: mem.Buddy_Allocator
buddy_allocator       :: mem.buddy_allocator
buddy_allocator_init  :: mem.buddy_allocator_init
buddy_allocator_free  :: mem.buddy_allocator_free

// 
from_ptr   ::  slice.from_ptr

// 
to_degrees :: linalg.to_degrees

// 
println    :: fmt.println
caprintf   :: fmt.caprintf


// thread
Thread              :: thread.Thread
Mutex               :: sync.Mutex

Thread_Proc			:: thread.Thread_Proc
THREAD_IS_SUPPORTED :: thread.IS_SUPPORTED

Duration            :: time.Duration

Nanosecond          :: time.Nanosecond
Microsecond			:: time.Microsecond
Millisecond			:: time.Millisecond
Second 				:: time.Second
       
// MAX_TASK      :: 1 << 2
// Task          ::  #type proc()



th_create     :: proc (_proc: Thread_Proc ) -> ^Thread { return thread.create(_proc)}
th_destroy    :: proc (t: ^Thread)                     { thread.destroy(t)}

th_start      :: proc (t : ^Thread) { thread.start(t) }
th_is_done    :: proc (t: ^Thread) -> bool  { return thread.is_done(t)}
th_join       :: proc (t: ^Thread)  { thread.join(t)  }
th_id         :: proc () -> int { return sync.current_thread_id() }
th_terminate  :: proc (t: ^Thread,exit_code : int ) { thread.terminate(t,exit_code)}


mt_lock       :: proc "contextless" (m: ^Mutex) { sync.mutex_lock(m)}
mt_try_lock   :: proc "contextless" (m: ^Mutex) -> bool { return sync.mutex_try_lock(m)}
mt_unlock     :: proc "contextless" (m: ^Mutex) { sync.mutex_unlock(m)}

@(deferred_in=mt_unlock)
mt_guard      :: proc "contextless" (m: ^Mutex) { mt_lock(m) }

@(deferred_in_out=mt_try_unlock)
mt_try_guard  :: proc(m: ^Mutex) -> bool { return mt_try_lock(m) }
mt_try_unlock :: proc "contextless" (m: ^Mutex, sucess: bool) { if sucess do mt_unlock(m) }


time_sleep    :: proc( d : time.Duration ) { time.sleep(d)}
time_now      :: time.now
time_since    :: time.since
