pragma Ada_2022;

package body Search_Insert_Position with SPARK_Mode => On is
   function Position (Data : Sorted_Array; Target : Value) return Search_Result is
      Answer : Insertion_Index := Insertion_Index'Last;
      Probes : Probe_Count := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Probes <= I - 1);
         if Answer = Insertion_Index'Last then
            Probes := Probes + 1;
            if Data (I) >= Target then
               Answer := I;
            end if;
         end if;
      end loop;
      return (Position => Answer, Probes => Probes);
   end Position;
end Search_Insert_Position;
