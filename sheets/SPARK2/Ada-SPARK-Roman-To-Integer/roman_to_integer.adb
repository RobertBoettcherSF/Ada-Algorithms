pragma SPARK_Mode (On);

package body Roman_To_Integer is
   subtype Symbol_Value is Natural range 0 .. 1_000;

   function Symbol (Letter : Character) return Symbol_Value is
   begin
      case Letter is
         when 'I' => return 1;
         when 'V' => return 5;
         when 'X' => return 10;
         when 'L' => return 50;
         when 'C' => return 100;
         when 'D' => return 500;
         when 'M' => return 1_000;
         when others => return 0;
      end case;
   end Symbol;

   function Value_Of (Text : Roman_Text) return Roman_Value is
   begin
      return Roman_Value
        (Symbol (Text (1)) + Symbol (Text (2)) + Symbol (Text (3))
         + Symbol (Text (4)) + Symbol (Text (5)));
   end Value_Of;
end Roman_To_Integer;
