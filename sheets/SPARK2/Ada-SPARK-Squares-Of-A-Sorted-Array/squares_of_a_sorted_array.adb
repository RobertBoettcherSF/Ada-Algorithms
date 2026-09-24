pragma Ada_2022;
package body Squares_Of_A_Sorted_Array with SPARK_Mode => On is
   function Squares (A : Int_Array) return Square_Array is
      Result : Square_Array;
      Magnitude : Value;
   begin
      for I in Index loop
         if A (I) < 0 then
            Magnitude := -A (I);
         else
            Magnitude := A (I);
         end if;
         Result (I) := Square_Value (Magnitude * Magnitude);
      end loop;
      return Result;
   end Squares;
end Squares_Of_A_Sorted_Array;
