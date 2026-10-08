pragma Ada_2022;

package Int_To_Roman_Stub with SPARK_Mode => On is
   subtype Number_Type is Positive range 1 .. 20;
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   type Roman_Text is array (Index) of Character;

   function To_Roman (Number : Number_Type) return Roman_Text
     with Global => null;
end Int_To_Roman_Stub;
