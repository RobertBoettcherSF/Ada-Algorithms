pragma Ada_2022;

package body Sparse_Dot with SPARK_Mode => On is
   function Dot (Values : Sparse_Values; Indices : Sparse_Indices;
                 Dense : Dense_Vector) return Integer is
   begin
      return Integer (Values (1)) * Integer (Dense (Indices (1)))
        + Integer (Values (2)) * Integer (Dense (Indices (2)))
        + Integer (Values (3)) * Integer (Dense (Indices (3)));
   end Dot;
end Sparse_Dot;
