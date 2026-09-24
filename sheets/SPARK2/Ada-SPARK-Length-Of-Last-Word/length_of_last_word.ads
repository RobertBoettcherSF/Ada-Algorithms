pragma Ada_2022;
package Length_Of_Last_Word with SPARK_Mode => On is
   Length : constant := 24;
   subtype Index is Positive range 1 .. Length;
   type Text is array (Index) of Character;
   function Last_Length (Input : Text) return Natural with Global => null;
end Length_Of_Last_Word;
