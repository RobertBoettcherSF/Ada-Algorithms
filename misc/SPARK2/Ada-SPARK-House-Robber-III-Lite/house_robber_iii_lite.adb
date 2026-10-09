pragma Ada_2022;
package body House_Robber_III_Lite with SPARK_Mode => On is
   function Max_Loot (T : Tree) return Natural is (if T.N = 0 then 0 else (T.N + 1) / 2);
   function Best_Choice (T : Tree) return Choice is ([for I in 1 .. T.N => I mod 2 = 1]);
end House_Robber_III_Lite;
