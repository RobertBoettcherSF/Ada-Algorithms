pragma Ada_2022;
package Word_Pattern with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   type Pattern is array (Index) of Character;
   type Words is array (Index) of Pattern;
   function Matches (P : Pattern; W : Words) return Boolean with Global => null;
end Word_Pattern;
