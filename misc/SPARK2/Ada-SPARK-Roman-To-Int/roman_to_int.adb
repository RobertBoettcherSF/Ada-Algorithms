pragma Ada_2022;

package body Roman_To_Int with SPARK_Mode => On is
   subtype Roman_Value is Integer range 0 .. 1000;

   function Value_Of (Symbol : Character) return Roman_Value is
   begin
      case Symbol is
         when 'I' => return 1;
         when 'V' => return 5;
         when 'X' => return 10;
         when 'L' => return 50;
         when 'C' => return 100;
         when 'D' => return 500;
         when 'M' => return 1000;
         when others => return 0;
      end case;
   end Value_Of;

   function To_Integer (Input : Roman_Text) return Integer is
      V1 : constant Roman_Value := Value_Of (Input (1));
      V2 : constant Roman_Value := Value_Of (Input (2));
      V3 : constant Roman_Value := Value_Of (Input (3));
      V4 : constant Roman_Value := Value_Of (Input (4));
      V5 : constant Roman_Value := Value_Of (Input (5));
      V6 : constant Roman_Value := Value_Of (Input (6));
      V7 : constant Roman_Value := Value_Of (Input (7));
      Total : Integer range -7000 .. 7000 := 0;
   begin
      if V1 < V2 then Total := Total - V1; else Total := Total + V1; end if;
      if V2 < V3 then Total := Total - V2; else Total := Total + V2; end if;
      if V3 < V4 then Total := Total - V3; else Total := Total + V3; end if;
      if V4 < V5 then Total := Total - V4; else Total := Total + V4; end if;
      if V5 < V6 then Total := Total - V5; else Total := Total + V5; end if;
      if V6 < V7 then Total := Total - V6; else Total := Total + V6; end if;
      Total := Total + V7;
      return Total;
   end To_Integer;
end Roman_To_Int;
