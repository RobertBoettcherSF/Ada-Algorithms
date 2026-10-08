pragma Ada_2022;
package body Reshape_The_Matrix with SPARK_Mode => On is
   procedure Reshape (Input : in Source; Output : out Matrix) is
   begin
      Output := (others => (others => 0));
      Output (1, 1) := Input (1, 1);
      Output (1, 2) := Input (1, 2);
      Output (2, 1) := Input (1, 3);
      Output (2, 2) := Input (1, 4);
      Output (3, 1) := Input (2, 1);
      Output (3, 2) := Input (2, 2);
      Output (4, 1) := Input (2, 3);
      Output (4, 2) := Input (2, 4);
   end Reshape;
end Reshape_The_Matrix;
