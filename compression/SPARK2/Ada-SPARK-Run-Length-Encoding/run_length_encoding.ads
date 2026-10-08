pragma Ada_2022;
package Run_Length_Encoding with SPARK_Mode => On is
   Max_Length : constant := 32;
   type Char_Array is array (Positive range <>) of Character;
   subtype Run_Count is Positive range 1 .. Max_Length;

   function Number_Of_Runs (Input : Char_Array) return Run_Count
     with
       Global => null,
       Pre => Input'First = 1 and then Input'Last <= Max_Length;
end Run_Length_Encoding;
