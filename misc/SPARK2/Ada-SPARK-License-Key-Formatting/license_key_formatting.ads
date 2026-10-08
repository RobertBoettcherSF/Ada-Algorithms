pragma Ada_2022;

package License_Key_Formatting with SPARK_Mode => On is
   Key_Length : constant := 6;
   Formatted_Length : constant := 8;
   subtype Key_Index is Positive range 1 .. Key_Length;
   subtype Formatted_Index is Positive range 1 .. Formatted_Length;
   type Key_Array is array (Key_Index) of Character;
   type Formatted_Array is array (Formatted_Index) of Character;

   function Format (Input : Key_Array) return Formatted_Array
     with Global => null;
end License_Key_Formatting;
