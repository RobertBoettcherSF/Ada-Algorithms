pragma Ada_2022;
package body House_Robber_II with SPARK_Mode => On is
   function Maximum (A : Values) return Loot is
      -- The two linear cases exclude the last and first house respectively.
      E1 : constant Natural := A (2);
      E2 : constant Natural := Natural'Max (E1, A (3));
      E3 : constant Natural := Natural'Max (E2, A (4) + E1);
      E4 : constant Natural := Natural'Max (E3, A (5) + E2);
      E5 : constant Natural := Natural'Max (E4, A (6) + E3);
      F1 : constant Natural := A (1);
      F2 : constant Natural := Natural'Max (F1, A (2));
      F3 : constant Natural := Natural'Max (F2, A (3) + F1);
      F4 : constant Natural := Natural'Max (F3, A (4) + F2);
      F5 : constant Natural := Natural'Max (F4, A (5) + F3);
   begin
      return Loot (Natural'Max (E5, F5));
   end Maximum;
end House_Robber_II;
