pragma SPARK_Mode (On);
package body Mark_And_Sweep is
   procedure Allocate (H : in out Heap; O : Object_Id) is begin H.Allocated (O) := True; H.Marked (O) := False; end Allocate;
   procedure Mark (H : in out Heap; O : Object_Id) is begin if H.Allocated (O) then H.Marked (O) := True; end if; end Mark;
   procedure Sweep (H : in out Heap) is
   begin
      for O in Object_Id loop
         if H.Allocated (O) and then not H.Marked (O) then H.Allocated (O) := False; end if;
         H.Marked (O) := False;
      end loop;
   end Sweep;
   function Allocated_Count (H : Heap) return Natural is N : Natural := 0;
   begin for O in Object_Id loop if H.Allocated (O) then N := N + 1; end if; end loop; return N; end Allocated_Count;
end Mark_And_Sweep;
