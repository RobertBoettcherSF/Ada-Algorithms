pragma Ada_2022;
package body Image_Smoother with SPARK_Mode => On is
   procedure Smooth (Input : in Image; Output : out Image) is
   begin
      Output := (others => (others => 0));
      Output (1, 1) := Pixel ((Input (1, 1) + Input (1, 2) + Input (2, 1) + Input (2, 2)) / 4);
      Output (1, 2) := Pixel ((Input (1, 1) + Input (1, 2) + Input (1, 3) + Input (2, 1) + Input (2, 2) + Input (2, 3)) / 6);
      Output (1, 3) := Pixel ((Input (1, 2) + Input (1, 3) + Input (1, 4) + Input (2, 2) + Input (2, 3) + Input (2, 4)) / 6);
      Output (1, 4) := Pixel ((Input (1, 3) + Input (1, 4) + Input (2, 3) + Input (2, 4)) / 4);
      Output (2, 1) := Pixel ((Input (1, 1) + Input (1, 2) + Input (2, 1) + Input (2, 2) + Input (3, 1) + Input (3, 2)) / 6);
      Output (2, 2) := Pixel ((Input (1, 1) + Input (1, 2) + Input (1, 3) + Input (2, 1) + Input (2, 2) + Input (2, 3) + Input (3, 1) + Input (3, 2) + Input (3, 3)) / 9);
      Output (2, 3) := Pixel ((Input (1, 2) + Input (1, 3) + Input (1, 4) + Input (2, 2) + Input (2, 3) + Input (2, 4) + Input (3, 2) + Input (3, 3) + Input (3, 4)) / 9);
      Output (2, 4) := Pixel ((Input (1, 3) + Input (1, 4) + Input (2, 3) + Input (2, 4) + Input (3, 3) + Input (3, 4)) / 6);
      Output (3, 1) := Pixel ((Input (2, 1) + Input (2, 2) + Input (3, 1) + Input (3, 2) + Input (4, 1) + Input (4, 2)) / 6);
      Output (3, 2) := Pixel ((Input (2, 1) + Input (2, 2) + Input (2, 3) + Input (3, 1) + Input (3, 2) + Input (3, 3) + Input (4, 1) + Input (4, 2) + Input (4, 3)) / 9);
      Output (3, 3) := Pixel ((Input (2, 2) + Input (2, 3) + Input (2, 4) + Input (3, 2) + Input (3, 3) + Input (3, 4) + Input (4, 2) + Input (4, 3) + Input (4, 4)) / 9);
      Output (3, 4) := Pixel ((Input (2, 3) + Input (2, 4) + Input (3, 3) + Input (3, 4) + Input (4, 3) + Input (4, 4)) / 6);
      Output (4, 1) := Pixel ((Input (3, 1) + Input (3, 2) + Input (4, 1) + Input (4, 2)) / 4);
      Output (4, 2) := Pixel ((Input (3, 1) + Input (3, 2) + Input (3, 3) + Input (4, 1) + Input (4, 2) + Input (4, 3)) / 6);
      Output (4, 3) := Pixel ((Input (3, 2) + Input (3, 3) + Input (3, 4) + Input (4, 2) + Input (4, 3) + Input (4, 4)) / 6);
      Output (4, 4) := Pixel ((Input (3, 3) + Input (3, 4) + Input (4, 3) + Input (4, 4)) / 4);
   end Smooth;
end Image_Smoother;
