pragma Ada_2022;
package body Third_Maximum_Number with SPARK_Mode => On is
   function Third_Maximum (A : Int_Array) return Value is
      Work : Int_Array := A;
      Temp : Value;
      Distinct : Count := 1;
   begin
      --  A bounded bubble sort keeps the proof and the example transparent.
      for Pass in Index loop
         for J in Index loop
            if J < Index'Last and then Work (J) < Work (J + 1) then
               Temp := Work (J);
               Work (J) := Work (J + 1);
               Work (J + 1) := Temp;
            end if;
         end loop;
      end loop;
      for I in Index range 2 .. Index'Last loop
         if Work (I) /= Work (I - 1) then
            if Distinct < 3 then
               Distinct := Distinct + 1;
            end if;
            if Distinct = 3 then
               return Work (I);
            end if;
         end if;
      end loop;
      return Work (Index'First);
   end Third_Maximum;
end Third_Maximum_Number;
