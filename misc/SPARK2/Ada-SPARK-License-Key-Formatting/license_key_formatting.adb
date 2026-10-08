pragma Ada_2022;

package body License_Key_Formatting with SPARK_Mode => On is
   function Format (Input : Key_Array) return Formatted_Array is
      Result : Formatted_Array := (others => '-');
   begin
      Result (1) := Input (1);
      Result (2) := Input (2);
      Result (4) := Input (3);
      Result (5) := Input (4);
      Result (7) := Input (5);
      Result (8) := Input (6);
      return Result;
   end Format;
end License_Key_Formatting;
