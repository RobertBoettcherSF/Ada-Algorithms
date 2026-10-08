pragma SPARK_Mode (On);
package Mark_And_Sweep is
   Max_Objects : constant := 8;
   subtype Object_Id is Positive range 1 .. Max_Objects;
   type Mark_Bits is array (Object_Id) of Boolean;
   type Heap is record Allocated : Mark_Bits := (others => False); Marked : Mark_Bits := (others => False); end record;
   procedure Allocate (H : in out Heap; O : Object_Id);
   procedure Mark (H : in out Heap; O : Object_Id);
   procedure Sweep (H : in out Heap);
   function Allocated_Count (H : Heap) return Natural;
end Mark_And_Sweep;
