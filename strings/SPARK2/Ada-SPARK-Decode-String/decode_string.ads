pragma Ada_2022;

package Decode_String with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 8;
   subtype Repeat_Count is Natural range 0 .. 8;
   type Text is array (Position) of Character;

   function Repeat_Symbol (Symbol : Character; Count : Repeat_Count) return Text
     with Global => null;
end Decode_String;
