pragma Ada_2022;
package House_Robber_III_Lite with SPARK_Mode => On is
   subtype House_Count is Natural range 0 .. 16;
   subtype Loot is Natural range 0 .. 8;
   function Max_Loot (Houses : House_Count) return Loot with Global => null;
end House_Robber_III_Lite;
