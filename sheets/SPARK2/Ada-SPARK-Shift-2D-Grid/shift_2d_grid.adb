pragma Ada_2022;
package body Shift_2D_Grid with SPARK_Mode => On is
   procedure Shift (Input : in Matrix; Output : out Matrix) is
   begin
      Output := (others => (others => 0));
      Output (1, 1) := Input (4, 4);
      Output (1, 2) := Input (1, 1);
      Output (1, 3) := Input (1, 2);
      Output (1, 4) := Input (1, 3);
      Output (2, 1) := Input (1, 4);
      Output (2, 2) := Input (2, 1);
      Output (2, 3) := Input (2, 2);
      Output (2, 4) := Input (2, 3);
      Output (3, 1) := Input (2, 4);
      Output (3, 2) := Input (3, 1);
      Output (3, 3) := Input (3, 2);
      Output (3, 4) := Input (3, 3);
      Output (4, 1) := Input (3, 4);
      Output (4, 2) := Input (4, 1);
      Output (4, 3) := Input (4, 2);
      Output (4, 4) := Input (4, 3);
   end Shift;
end Shift_2D_Grid;
