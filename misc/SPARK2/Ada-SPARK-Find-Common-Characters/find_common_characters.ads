pragma Ada_2022;

package Find_Common_Characters with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Character_Code is Integer range 0 .. 25;
   type Character_Array is array (Index) of Character_Code;

   function Has_Common (Left, Right : Character_Array) return Boolean
     with Global => null;
end Find_Common_Characters;
