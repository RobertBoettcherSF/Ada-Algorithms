pragma Ada_2022;
package body Diagonal_Traverse with SPARK_Mode => On is
   procedure Traverse (Input : in Matrix; Output : out Sequence) is
   begin
      Output := (others => 0);
      Output (1) := Input (1, 1);
      Output (2) := Input (1, 2);
      Output (3) := Input (2, 1);
      Output (4) := Input (3, 1);
      Output (5) := Input (2, 2);
      Output (6) := Input (1, 3);
      Output (7) := Input (1, 4);
      Output (8) := Input (2, 3);
      Output (9) := Input (3, 2);
      Output (10) := Input (4, 1);
      Output (11) := Input (4, 2);
      Output (12) := Input (3, 3);
      Output (13) := Input (2, 4);
      Output (14) := Input (3, 4);
      Output (15) := Input (4, 3);
      Output (16) := Input (4, 4);
   end Traverse;
end Diagonal_Traverse;
