pragma Ada_2022;

package body Heap_Push_Pop with SPARK_Mode => On is
   function Empty return Heap is
   begin return (Data => [others => 0], Count => 0); end Empty;

   procedure Push (H : in out Heap; V : Value) is P : Slot; begin
      if H.Count < Capacity then
         H.Count := H.Count + 1; P := H.Count; H.Data (P) := V;
      end if;
   end Push;

   procedure Pop_Min (H : in out Heap; V : out Value) is
      Small : Slot := 1; Last : constant Index := H.Count;
      Temp : Value;
   begin
      if H.Count > 0 then
         for I in 2 .. Last loop
            if H.Data (I) < H.Data (Small) then Small := I; end if;
         end loop;
         V := H.Data (Small);
         for I in Small .. Last - 1 loop
            H.Data (I) := H.Data (I + 1);
         end loop;
         H.Count := Last - 1;
         for I in 1 .. H.Count loop
            for J in I + 1 .. H.Count loop
               if H.Data (J) < H.Data (I) then Temp := H.Data (I); H.Data (I) := H.Data (J); H.Data (J) := Temp; end if;
            end loop;
         end loop;
      else
         V := 0;
      end if;
   end Pop_Min;

   function Size (H : Heap) return Natural is begin return H.Count; end Size;
end Heap_Push_Pop;
