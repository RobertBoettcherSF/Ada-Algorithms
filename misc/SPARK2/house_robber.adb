pragma Ada_2022;
package body House_Robber with SPARK_Mode => On is
   function Maximum (A : Values) return Loot is
      R1 : constant Natural := A (1);
      R2 : constant Natural := Natural'Max (R1, A (2));
      R3 : constant Natural := Natural'Max (R2, A (3) + R1);
      R4 : constant Natural := Natural'Max (R3, A (4) + R2);
      R5 : constant Natural := Natural'Max (R4, A (5) + R3);
      R6 : constant Natural := Natural'Max (R5, A (6) + R4);
   begin
      return Loot (R6);
   end Maximum;
end House_Robber;
