-- Version: 0.01
-- Disk Scheduling Algorithm Specifications
-- 
-- This package provides disk scheduling algorithms (Elevator Algorithm and variants).

package Disk_Scheduling is

   type Cylinder is new Natural;
   type Cylinder_Array is array (Positive range <>) of Cylinder;
   type Direction is (Up, Down);

   -- 1. SCAN (Elevator Algorithm)
   -- The arm sweeps to the extreme end of the disk before reversing direction.
   function SCAN
     (Requests     : Cylinder_Array;
      Start_Head   : Cylinder;
      Dir          : Direction;
      Max_Cylinder : Cylinder) return Cylinder_Array;

   -- 2. C-SCAN (Circular SCAN)
   -- Sweeps to the end of the disk, then jumps to the other end without 
   -- servicing requests, and sweeps in the same direction again.
   function C_SCAN
     (Requests     : Cylinder_Array;
      Start_Head   : Cylinder;
      Dir          : Direction;
      Max_Cylinder : Cylinder) return Cylinder_Array;

   -- 3. LOOK Algorithm
   -- Similar to SCAN, but only goes as far as the last request in the 
   -- current direction before reversing.
   function LOOK
     (Requests   : Cylinder_Array;
      Start_Head : Cylinder;
      Dir        : Direction) return Cylinder_Array;

   -- 4. C-LOOK (Circular LOOK)
   -- Similar to C-SCAN, but only goes to the furthest request before 
   -- jumping to the first request at the other end.
   function C_LOOK
     (Requests   : Cylinder_Array;
      Start_Head : Cylinder;
      Dir        : Direction) return Cylinder_Array;

   -- 5. F-SCAN
   -- Uses two queues. Processes the Active_Queue fully while new requests 
   -- wait in the Waiting_Queue to prevent starvation, then processes the waiting.
   function F_SCAN
     (Active_Queue  : Cylinder_Array;
      Waiting_Queue : Cylinder_Array;
      Start_Head    : Cylinder;
      Dir           : Direction;
      Max_Cylinder  : Cylinder) return Cylinder_Array;

end Disk_Scheduling;
