pragma Ada_2022;
package body Sort_Array_By_Parity with SPARK_Mode => On is
   function By_Parity (A : Int_Array) return Int_Array is
      Result : Int_Array := A;
      Temp : Value;
   begin
      --  A bounded bubble pass moves every even value left of odd values.
      for Pass in Index loop
         for J in Index loop
            if J < Index'Last
              and then Result (J) mod 2 /= 0
              and then Result (J + 1) mod 2 = 0
            then
               Temp := Result (J);
               Result (J) := Result (J + 1);
               Result (J + 1) := Temp;
            end if;
         end loop;
      end loop;
      return Result;
   end By_Parity;
end Sort_Array_By_Parity;
