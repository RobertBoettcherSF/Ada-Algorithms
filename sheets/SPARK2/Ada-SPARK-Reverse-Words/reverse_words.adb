pragma Ada_2022;
package body Reverse_Words with SPARK_Mode => On is
   function Reversed (Input : Word_List) return Word_List is
      Result : Word_List := [others => [others => ' ']];
   begin
      for I in Position loop
         for J in Word_Index loop
            Result (I) (J) := Input (Position'Last - I + 1) (J);
         end loop;
      end loop;
      return Result;
   end Reversed;
end Reverse_Words;
