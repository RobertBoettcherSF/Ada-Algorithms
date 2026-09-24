pragma Ada_2022;
package body Matrix_Chain_Multiplication with SPARK_Mode => On is
   function Minimum_Cost (Dimensions : Dimension_Array) return Cost is
      First : constant Integer :=
        Integer (Dimensions (1)) * Integer (Dimensions (2))
          * Integer (Dimensions (3))
        + Integer (Dimensions (1)) * Integer (Dimensions (3))
          * Integer (Dimensions (4));
      Second : constant Integer :=
        Integer (Dimensions (2)) * Integer (Dimensions (3))
          * Integer (Dimensions (4))
        + Integer (Dimensions (1)) * Integer (Dimensions (2))
          * Integer (Dimensions (4));
   begin
      if First < Second then
         return Cost (First);
      else
         return Cost (Second);
      end if;
   end Minimum_Cost;
end Matrix_Chain_Multiplication;
