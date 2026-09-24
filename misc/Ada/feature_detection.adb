-- feature_detection.adb
with Ada.Numerics.Elementary_Functions; 
use Ada.Numerics.Elementary_Functions;

package body Feature_Detection is

   -- Helper function to validate image size (requires at least 3x3 for kernels)
   procedure Validate_Image (Img : in Image) is
   begin
      if Img'Length(1) < 3 or Img'Length(2) < 3 then
         raise Invalid_Image_Error with "Image must be at least 3x3 pixels for kernel operations.";
      end if;
   end Validate_Image;

   -- 1. Edge Detection: Sobel Operator Implementation
   procedure Detect_Edges
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural)
   is
      Gx, Gy    : Float;
      Magnitude : Float;
      Idx       : Natural := 0;
   begin
      Validate_Image(Img);
      Count := 0;

      -- Iterate over image, ignoring 1-pixel border to apply 3x3 kernel
      for Y in Img'First(2) + 1 .. Img'Last(2) - 1 loop
         for X in Img'First(1) + 1 .. Img'Last(1) - 1 loop
            -- Sobel X
            Gx := Float(Img(X+1, Y-1)) + 2.0 * Float(Img(X+1, Y)) + Float(Img(X+1, Y+1))
                - Float(Img(X-1, Y-1)) - 2.0 * Float(Img(X-1, Y)) - Float(Img(X-1, Y+1));
            
            -- Sobel Y
            Gy := Float(Img(X-1, Y+1)) + 2.0 * Float(Img(X, Y+1)) + Float(Img(X+1, Y+1))
                - Float(Img(X-1, Y-1)) - 2.0 * Float(Img(X, Y-1)) - Float(Img(X+1, Y-1));

            Magnitude := Sqrt (Gx * Gx + Gy * Gy);

            if Magnitude >= Threshold then
               if Idx < Features'Length then
                  Idx := Idx + 1;
                  Features(Idx) := (Location => (X, Y), Kind => Edge, Magnitude => Magnitude);
               end if;
            end if;
         end loop;
      end loop;
      Count := Idx;
   end Detect_Edges;

   -- 2. Corner Detection: Simplified Moravec Operator
   procedure Detect_Corners
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural)
   is
      Min_SSD : Float;
      SSD     : Float;
      Idx     : Natural := 0;
   begin
      Validate_Image(Img);
      Count := 0;

      for Y in Img'First(2) + 1 .. Img'Last(2) - 1 loop
         for X in Img'First(1) + 1 .. Img'Last(1) - 1 loop
            Min_SSD := Float'Last;
            
            -- Check shifting windows in 4 primary directions (simplified)
            for DX in -1 .. 1 loop
               for DY in -1 .. 1 loop
                  if DX /= 0 or DY /= 0 then
                     SSD := (Float(Img(X, Y)) - Float(Img(X+DX, Y+DY))) ** 2;
                     if SSD < Min_SSD then
                        Min_SSD := SSD;
                     end if;
                  end if;
               end loop;
            end loop;

            if Min_SSD >= Threshold then
               if Idx < Features'Length then
                  Idx := Idx + 1;
                  Features(Idx) := (Location => (X, Y), Kind => Corner, Magnitude => Min_SSD);
               end if;
            end if;
         end loop;
      end loop;
      Count := Idx;
   end Detect_Corners;

   -- 3. Blob Detection: Laplacian Operator (2nd Derivative)
   procedure Detect_Blobs
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural)
   is
      Laplacian : Float;
      Idx       : Natural := 0;
   begin
      Validate_Image(Img);
      Count := 0;

      for Y in Img'First(2) + 1 .. Img'Last(2) - 1 loop
         for X in Img'First(1) + 1 .. Img'Last(1) - 1 loop
            -- Simple 3x3 Laplacian Kernel: 
            -- [ 0  1  0 ]
            -- [ 1 -4  1 ]
            -- [ 0  1  0 ]
            Laplacian := Float(Img(X, Y-1)) + Float(Img(X-1, Y)) + 
                         Float(Img(X+1, Y)) + Float(Img(X, Y+1)) - 
                         4.0 * Float(Img(X, Y));
            
            if abs(Laplacian) >= Threshold then
               if Idx < Features'Length then
                  Idx := Idx + 1;
                  Features(Idx) := (Location => (X, Y), Kind => Blob, Magnitude => abs(Laplacian));
               end if;
            end if;
         end loop;
      end loop;
      Count := Idx;
   end Detect_Blobs;

   -- 4. Ridge Detection: Simple Principal Curvature (Hessian proxy)
   procedure Detect_Ridges
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural)
   is
      Dxx, Dyy : Float;
      Ridge_Response : Float;
      Idx : Natural := 0;
   begin
      Validate_Image(Img);
      Count := 0;

      for Y in Img'First(2) + 1 .. Img'Last(2) - 1 loop
         for X in Img'First(1) + 1 .. Img'Last(1) - 1 loop
            -- 2nd derivatives
            Dxx := Float(Img(X+1, Y)) - 2.0 * Float(Img(X, Y)) + Float(Img(X-1, Y));
            Dyy := Float(Img(X, Y+1)) - 2.0 * Float(Img(X, Y)) + Float(Img(X, Y-1));

            -- If signs are the same, it indicates a peak/valley (blob), if opposite, a saddle.
            -- A ridge typically has one high principal curvature and one low.
            Ridge_Response := abs(abs(Dxx) - abs(Dyy)); 

            if Ridge_Response >= Threshold then
               if Idx < Features'Length then
                  Idx := Idx + 1;
                  Features(Idx) := (Location => (X, Y), Kind => Ridge, Magnitude => Ridge_Response);
               end if;
            end if;
         end loop;
      end loop;
      Count := Idx;
   end Detect_Ridges;

end Feature_Detection;
