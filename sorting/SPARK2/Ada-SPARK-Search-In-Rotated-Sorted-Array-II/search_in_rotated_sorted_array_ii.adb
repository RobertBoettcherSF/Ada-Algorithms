pragma Ada_2022;

package body Search_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   function Contains (Data : Data_Array; Target : Value) return Search_Result is
      Found  : Boolean := False;
      Probes : Probe_Count := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Probes = I - 1);
         Probes := Probes + 1;
         if Data (I) = Target then
            Found := True;
         end if;
      end loop;
      return (Found => Found, Probes => Probes);
   end Contains;
end Search_In_Rotated_Sorted_Array_II;
