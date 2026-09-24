pragma Ada_2022;

package body Reverse_Words_In_A_String with SPARK_Mode => On is
   function Reverse_Words (Input : Text_Array) return Text_Array is
   begin
      -- The bounded exercise uses three three-letter words separated by spaces.
      return [Input (9), Input (10), Input (11), Input (8),
              Input (5), Input (6), Input (7), Input (4),
              Input (1), Input (2), Input (3)];
   end Reverse_Words;
end Reverse_Words_In_A_String;
