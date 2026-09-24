with Ada.Text_IO; use Ada.Text_IO;
with Image_Segmentation; use Image_Segmentation;

procedure Main is
   Img    : Image_Grid(1 .. 5, 1 .. 5) := (others => (others => 10));
   Out_Img: Image_Grid(1 .. 5, 1 .. 5);
   Opt_T  : Pixel_Intensity;
begin
   Put_Line("Running Image Segmentation Demo Application...");

   -- Setup artificial gradient object
   Img(2, 2) := 200;
   Img(2, 3) := 210;
   Img(3, 2) := 205;

   Otsu_Threshold(Img, Out_Img, Opt_T);
   Put_Line("Otsu Optimal Threshold computed: " & Pixel_Intensity'Image(Opt_T));
   Put_Line("Demo finished successfully.");
end Main;
