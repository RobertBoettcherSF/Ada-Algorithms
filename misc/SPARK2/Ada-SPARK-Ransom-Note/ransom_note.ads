pragma Ada_2022;
package Ransom_Note with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   type Text is array (Index) of Character;
   function Can_Construct (Note : Text; Magazine : Text) return Boolean with Global => null;
end Ransom_Note;
