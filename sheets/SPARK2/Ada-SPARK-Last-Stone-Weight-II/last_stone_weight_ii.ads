pragma Ada_2022;
package Last_Stone_Weight_II with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 6;
   subtype Weight is Natural range 0 .. 10;
   type Stones is array (Position) of Weight;
   subtype Remaining is Natural range 0 .. 120;
   function Min_Remaining_Weight (A : Stones) return Long_Long_Integer with Global => null;
end Last_Stone_Weight_II;
