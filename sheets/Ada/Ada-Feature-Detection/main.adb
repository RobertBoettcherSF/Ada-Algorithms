-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Feature_Detection; use Feature_Detection;

procedure Main is
   Img : Image(1..5, 1..5) := (others => (others => 0));
   Results : Feature_Array(1..10);
   Count   : Natural;
begin
   -- Draw a small cross
   Img(3, 2) := 255; Img(3, 3) := 255; Img(3, 4) := 255;
   Img(2, 3) := 255; Img(4, 3) := 255;

   Put_Line("Running Feature Detection App...");
   Detect_Edges(Img, 50.0, Results, Count);
   Put_Line("Detected" & Natural'Image(Count) & " edges on cross image.");
   Put_Line("Run 'make test' to execute full V&V suite.");
end Main;
