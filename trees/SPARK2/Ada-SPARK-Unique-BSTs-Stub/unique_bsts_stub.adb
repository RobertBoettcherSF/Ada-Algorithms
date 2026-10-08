pragma Ada_2022;

package body Unique_BSTs_Stub with SPARK_Mode => On is
   function Number_Of_Trees (N : Node_Count) return Count is
   begin
      case N is
         when 0 => return 1;
         when 1 => return 1;
         when 2 => return 2;
         when 3 => return 5;
         when 4 => return 14;
         when 5 => return 42;
         when 6 => return 132;
         when 7 => return 429;
         when 8 => return 1430;
      end case;
   end Number_Of_Trees;
end Unique_BSTs_Stub;
