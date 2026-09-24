pragma Ada_2022;

package body Top_K_Frequent_Stub with SPARK_Mode => On is
   function Top_K (Input : Input_Array; K : Result_Index) return Result_Array is
      Counts : array (Value) of Natural := [others => 0];
      Used : array (Value) of Boolean := [others => False];
      Result : Result_Array := [others => 0];
      Best : Value; Best_Count : Natural;
   begin
      for I in Index loop Counts (Input (I)) := Counts (Input (I)) + 1; end loop;
      for Out_I in Result_Index loop
         Best := Value'First; Best_Count := 0;
         for V in Value loop
            if not Used (V) and then Counts (V) > Best_Count then Best := V; Best_Count := Counts (V); end if;
         end loop;
         if Out_I <= K then Result (Out_I) := Best; Used (Best) := True; end if;
      end loop;
      return Result;
   end Top_K;
end Top_K_Frequent_Stub;
