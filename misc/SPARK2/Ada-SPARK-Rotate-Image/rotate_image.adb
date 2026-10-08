pragma Ada_2022;

package body Rotate_Image with SPARK_Mode => On is
   procedure Rotate (Input : in out Image) is
      Temp : Pixel;
   begin
      Temp := Input (1, 1);
      Input (1, 1) := Input (3, 1);
      Input (3, 1) := Input (3, 3);
      Input (3, 3) := Input (1, 3);
      Input (1, 3) := Temp;

      Temp := Input (1, 2);
      Input (1, 2) := Input (2, 1);
      Input (2, 1) := Input (3, 2);
      Input (3, 2) := Input (2, 3);
      Input (2, 3) := Temp;
   end Rotate;
end Rotate_Image;
