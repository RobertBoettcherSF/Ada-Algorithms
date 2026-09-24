pragma Ada_2022;

package First_Unique_Character_In_A_String with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Result_Index is Natural range 0 .. Length;
   type Text_Array is array (Index) of Character;

   function Find (Input : Text_Array) return Result_Index
     with Global => null;
end First_Unique_Character_In_A_String;
