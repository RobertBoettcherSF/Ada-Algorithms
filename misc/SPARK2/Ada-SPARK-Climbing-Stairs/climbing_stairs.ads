pragma Ada_2022;
--  Scaffold for the failing test: the new API, still answering from the
--  old table (n <= 10); Climb returns nothing yet.
package Climbing_Stairs with SPARK_Mode => On is
   subtype Steps is Natural range 0 .. 45;
   type Step_List is array (Positive range <>) of Positive;
   function Count (N : Steps) return Positive with Global => null;
   function Climb (N : Steps; K : Natural) return Step_List
   with Global => null, Pre => K < Count (N);
end Climbing_Stairs;
