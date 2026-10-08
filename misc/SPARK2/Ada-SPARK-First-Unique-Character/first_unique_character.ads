pragma Ada_2022;

package First_Unique_Character with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Index_Or_Zero is Natural range 0 .. Length;
   type Text_Array is array (Index) of Character;

   function First_Unique (Input : Text_Array) return Index_Or_Zero
     with Global => null;
end First_Unique_Character;
