pragma Ada_2022;

package body CSR_Row_Sum with SPARK_Mode => On is
   function Row_Sum (Values : Value_Array; Row : Row_Index) return Integer is
   begin
      case Row is
         when 1 => return Values (1) + Values (2);
         when 2 => return Values (3) + Values (4);
         when 3 => return Values (5) + Values (6);
      end case;
   end Row_Sum;
end CSR_Row_Sum;
