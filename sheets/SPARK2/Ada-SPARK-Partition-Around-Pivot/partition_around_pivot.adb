pragma Ada_2022;

package body Partition_Around_Pivot with SPARK_Mode => On is
   function Partition (Input : Value_Array; Pivot : Value) return Value_Array is
      Result : Value_Array := Input;
      Position : Index := Index'First;
   begin
      for I in Index loop
         if Input (I) <= Pivot then
            Result (Position) := Input (I);
            if Position < Index'Last then
               Position := Position + 1;
            end if;
         end if;
      end loop;
      for I in Index loop
         if Input (I) > Pivot then
            Result (Position) := Input (I);
            if Position < Index'Last then
               Position := Position + 1;
            end if;
         end if;
      end loop;
      return Result;
   end Partition;
end Partition_Around_Pivot;
