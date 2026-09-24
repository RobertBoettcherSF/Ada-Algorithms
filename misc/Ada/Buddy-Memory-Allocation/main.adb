-- src/main.adb
-- Version 0.01
-- Description: Simple example usage for the Buddy Allocation project

with Ada.Text_IO; use Ada.Text_IO;
with Buddy_Allocators; use Buddy_Allocators;

procedure Main is
   Bin_Pool : Pool(Binary);
   A1, A2   : Address;
begin
   Put_Line("=== Buddy Memory Allocation Demo ===");
   
   Put_Line("Initializing Binary Buddy System (Total Size: 1024)");
   Initialize(Bin_Pool, 1024);
   
   A1 := Allocate(Bin_Pool, 100);
   Put_Line("Allocated block for Size 100 at Address: " & A1'Image);
   
   A2 := Allocate(Bin_Pool, 250);
   Put_Line("Allocated block for Size 250 at Address: " & A2'Image);
   
   Put_Line("Deallocating block at Address: " & A1'Image);
   Deallocate(Bin_Pool, A1);
   
   Put_Line("Deallocating block at Address: " & A2'Image);
   Deallocate(Bin_Pool, A2);
   
   Put_Line("All demo allocations successfully deallocated and merged.");
end Main;
