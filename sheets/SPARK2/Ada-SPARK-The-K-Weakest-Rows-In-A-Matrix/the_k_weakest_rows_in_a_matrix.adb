pragma SPARK_Mode (On);

package body The_K_Weakest_Rows_In_A_Matrix is
   function Strength (M : Matrix; R : Row_Index) return Natural is
   begin
      return M (R, 1) + M (R, 2) + M (R, 3) + M (R, 4);
   end Strength;

   function Weakest_Row (M : Matrix) return Row_Index is
      S1 : constant Natural := Strength (M, 1);
      S2 : constant Natural := Strength (M, 2);
      S3 : constant Natural := Strength (M, 3);
      S4 : constant Natural := Strength (M, 4);
   begin
      if S1 <= S2 and S1 <= S3 and S1 <= S4 then
         return 1;
      elsif S2 <= S3 and S2 <= S4 then
         return 2;
      elsif S3 <= S4 then
         return 3;
      else
         return 4;
      end if;
   end Weakest_Row;
end The_K_Weakest_Rows_In_A_Matrix;
