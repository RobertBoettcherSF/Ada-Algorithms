pragma Ada_2022;
package Run_Length_Encoding with SPARK_Mode => On is
   Max_Length : constant := 32;
   type Char_Array is array (Positive range <>) of Character;
   --  0 runs for the empty input, otherwise 1 .. Input'Length.
   subtype Run_Count is Natural range 0 .. Max_Length;

   function Number_Of_Runs (Input : Char_Array) return Run_Count
     with
       Global => null,
       Pre    => Input'First = 1 and then Input'Last <= Max_Length,
       Post   =>
         (if Input'Length = 0 then Number_Of_Runs'Result = 0
          else Number_Of_Runs'Result in 1 .. Input'Length);
end Run_Length_Encoding;
