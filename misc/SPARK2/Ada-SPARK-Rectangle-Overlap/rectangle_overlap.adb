pragma Ada_2022;
package body Rectangle_Overlap with SPARK_Mode => On is
   function Has_Overlap (A, B : Rectangle) return Boolean is
      Result : constant Boolean :=
        A.Left < B.Right and B.Left < A.Right
        and A.Bottom < B.Top and B.Bottom < A.Top;
   begin
      pragma Assert
        (Result = (A.Left < B.Right and B.Left < A.Right
                   and A.Bottom < B.Top and B.Bottom < A.Top));
      return Result;
   end Has_Overlap;
end Rectangle_Overlap;
