pragma Ada_2022;

package body Reverse_Pairs with SPARK_Mode => On is
   function Count (Input : Input_Array) return Natural is
      Result : Natural := 0;
   begin
      for I in Index loop
         for J in I + 1 .. Length loop
            if Input (I) > 2 * Input (J) and then Result < Length * Length then
               Result := Result + 1;
            end if;
         end loop;
      end loop;
      return Result;
   end Count;
end Reverse_Pairs;
