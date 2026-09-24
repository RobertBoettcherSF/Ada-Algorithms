with Ada.Text_IO; use Ada.Text_IO;
with Semi_Space_Collector; use Semi_Space_Collector;

procedure Main is
   H : Heap;
   Roots : Root_Set(1..1) := (others => Null_Id);
   Dummy : Object_Id;
begin
   Initialize (H);
   Put_Line ("Semi-Space Collector Initialized.");
   
   Dummy := Allocate (H, 42);
   Roots(1) := Dummy;
   
   Put_Line ("Allocated node with value 42.");
   Put_Line ("Active usage before GC: " & Integer'Image(Active_Space_Usage(H)));
   
   Collect_Cheney (H, Roots);
   
   Put_Line ("Active usage after GC: " & Integer'Image(Active_Space_Usage(H)));
   Put_Line ("Run 'make test' for full Verification & Validation.");
end Main;
