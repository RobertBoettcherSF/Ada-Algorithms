pragma Ada_2022;
package body Array_Partition_I with SPARK_Mode => On is
   procedure Sort (Input : in out Int_Array) is
      Temp : Value;
   begin
      for Pass in Index loop
         for J in 1 .. 7 loop
            if Input (J) > Input (J + 1) then
               Temp := Input (J);
               Input (J) := Input (J + 1);
               Input (J + 1) := Temp;
            end if;
         end loop;
      end loop;
   end Sort;
   function Pair_Sum (Input : Int_Array) return Natural is
      Result : Natural := 0;
   begin
      for J in 1 .. 4 loop
         Result := Result + Input (2 * J - 1);
      end loop;
      return Result;
   end Pair_Sum;
end Array_Partition_I;
