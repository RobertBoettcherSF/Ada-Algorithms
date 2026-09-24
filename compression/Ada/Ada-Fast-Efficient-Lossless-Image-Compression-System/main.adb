-- main.adb
-- Demonstration application for FELICS image compression in Ada.

with Ada.Text_IO; use Ada.Text_IO;
with Felics;     use Felics;

procedure Main is
   Sample_Image : constant Pixel_Matrix(1 .. 3, 1 .. 3) := 
     ((100, 102, 105),
      (101, 104, 108),
      (103, 107, 110));
      
   -- The stream must be constrained because the array type is unconstrained. 
   -- A 3x3 image results in 9 compressed symbols.
   Stream : Encoded_Stream (1 .. 9);
   
   Reconstructed : Pixel_Matrix(1 .. 3, 1 .. 3);
   Match : Boolean := True;
begin
   Put_Line("=== FELICS Image Compression Demo ===");
   Put_Line("Original 3x3 Image Matrix:");
   for R in Sample_Image'Range(1) loop
      for C in Sample_Image'Range(2) loop
         Put(Pixel_Value'Image(Sample_Image(R, C)) & " ");
      end loop;
      New_Line;
   end loop;

   Stream := Compress_Image(Sample_Image);
   Put_Line("Image compressed successfully. Total symbols: " & Integer'Image(Stream'Length));

   Reconstructed := Decompress_Image(Stream, 3, 3);
   Put_Line("Reconstructed 3x3 Image Matrix:");
   for R in Reconstructed'Range(1) loop
      for C in Reconstructed'Range(2) loop
         Put(Pixel_Value'Image(Reconstructed(R, C)) & " ");
         if Reconstructed(R, C) /= Sample_Image(R, C) then
            Match := False;
         end if;
      end loop;
      New_Line;
   end loop;

   if Match then
      Put_Line("SUCCESS: Lossless compression and decompression match perfectly!");
   else
      Put_Line("FAILURE: Reconstructed image differs from original.");
   end if;
end Main;
