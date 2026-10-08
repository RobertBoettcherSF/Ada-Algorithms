pragma Ada_2022;
package Target_Sum_Stub with SPARK_Mode => On is
   subtype Position is Positive range 1 .. 5;
   subtype Value is Natural range 0 .. 10;
   type Values is array (Position) of Value;
   subtype Target is Integer range -50 .. 50;
   function Exists (A : Values; Goal : Target) return Boolean with Global => null;
end Target_Sum_Stub;
