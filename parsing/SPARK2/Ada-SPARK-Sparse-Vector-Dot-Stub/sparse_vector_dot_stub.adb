pragma SPARK_Mode (On);

package body Sparse_Vector_Dot_Stub is
   function Dot (Left, Right : Vector) return Integer is
      Sum : Integer := 0;
   begin
      for I in Component_Index loop
         pragma Loop_Invariant
           (Sum in -10_000 * (Integer (I) - 1) ..
                    10_000 * (Integer (I) - 1));
         Sum := Sum + Left (I) * Right (I);
      end loop;
      pragma Assert (Sum in -80_000 .. 80_000);
      return Sum;
   end Dot;
end Sparse_Vector_Dot_Stub;
