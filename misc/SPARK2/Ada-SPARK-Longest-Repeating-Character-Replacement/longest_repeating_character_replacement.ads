pragma Ada_2022;

package Longest_Repeating_Character_Replacement with SPARK_Mode => On is
   Max_Length : constant := 1_000_000;
   subtype Index is Positive range 1 .. Max_Length;
   subtype Result is Natural range 0 .. Max_Length;
   type Text_Array is array (Index range <>) of Character;

   --  Length of the longest window of Input that can be made a run of one
   --  character by replacing at most K of its characters.
   function Longest (Input : Text_Array; K : Result) return Result
     with Global => null,
          Post   => Longest'Result <= Input'Length
                    and then (if Input'Length > 0 then Longest'Result >= 1)
                    and then Longest'Result >= Natural'Min (Input'Length, K + 1);
end Longest_Repeating_Character_Replacement;
