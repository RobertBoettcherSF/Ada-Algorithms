pragma Ada_2022;
package body Height_Checker with SPARK_Mode => On is
   function Mismatches (A : Int_Array) return Count is
      Sorted : Int_Array := A;
      Temp : Value;
      Result : Count := 0;
   begin
      for Pass in Index loop
         for J in Index loop
            if J < Index'Last and then Sorted (J) > Sorted (J + 1) then
               Temp := Sorted (J);
               Sorted (J) := Sorted (J + 1);
               Sorted (J + 1) := Temp;
            end if;
         end loop;
      end loop;
      for I in Index loop
         if A (I) /= Sorted (I) and then Result < Length then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Mismatches;
end Height_Checker;
