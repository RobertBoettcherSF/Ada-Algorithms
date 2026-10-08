pragma Ada_2022;
package House_Robber_II with SPARK_Mode => On is
   House_Count : constant := 6;
   subtype House is Positive range 1 .. House_Count;
   subtype Money is Natural range 0 .. 20;
   type Values is array (House) of Money;
   subtype Loot is Natural range 0 .. 60;
   function Maximum (A : Values) return Loot with Global => null;
end House_Robber_II;
