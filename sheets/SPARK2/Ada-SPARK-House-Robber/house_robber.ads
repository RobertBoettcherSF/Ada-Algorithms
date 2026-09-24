pragma Ada_2022;
package House_Robber with SPARK_Mode => On is
   House_Count : constant := 6;
   subtype House is Positive range 1 .. House_Count;
   subtype Money is Natural range 0 .. 100;
   type Values is array (House) of Money;
   subtype Loot is Natural range 0 .. 300;
   function Maximum (A : Values) return Loot with Global => null;
end House_Robber;
