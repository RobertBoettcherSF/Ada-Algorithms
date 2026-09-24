pragma Ada_2022;

package Dutch_National_Flag with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Color is Integer range 0 .. 2;
   type Color_Array is array (Index) of Color;

   function Sort (Input : Color_Array) return Color_Array with Global => null;
end Dutch_National_Flag;
