pragma Ada_2022;

package body Contiguous_Array with SPARK_Mode => On is
   function One_Count (A : Bits) return Count is
      Result : Count := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Result <= I - Index'First);
         if A (I) = 1 then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end One_Count;
end Contiguous_Array;
