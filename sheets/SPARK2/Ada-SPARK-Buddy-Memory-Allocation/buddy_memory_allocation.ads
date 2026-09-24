pragma SPARK_Mode (On);
package Buddy_Memory_Allocation is
   Pool_Size : constant := 16;
   subtype Block_Id is Positive range 1 .. Pool_Size;
   subtype Block_Size is Positive range 1 .. Pool_Size;
   type Used_Bits is array (Block_Id) of Boolean;
   type State is record Used : Used_Bits := (others => False); end record;
   function Is_Power_Of_Two (N : Block_Size) return Boolean;
   procedure Allocate (S : in out State; Size : Block_Size; B : out Block_Id);
   procedure Deallocate (S : in out State; B : Block_Id);
   function Is_Free (S : State; B : Block_Id) return Boolean;
end Buddy_Memory_Allocation;
