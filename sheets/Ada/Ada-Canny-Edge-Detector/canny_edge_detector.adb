-- canny_edge_detector.adb
-- Implementation body for Canny Edge Detector
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Canny_Edge_Detector is

   procedure Gaussian_Blur (Input : in Image; Output : out Image) is
      -- Standard 5x5 Gaussian Kernel (sigma = 1.4) approximation
      type Kernel_Array is array (-2 .. 2, -2 .. 2) of Float;
      Kernel : constant Kernel_Array :=
        ( (2.0,  4.0,  5.0,  4.0,  2.0),
          (4.0,  9.0,  12.0, 9.0,  4.0),
          (5.0,  12.0, 15.0, 12.0, 5.0),
          (4.0,  9.0,  12.0, 9.0,  4.0),
          (2.0,  4.0,  5.0,  4.0,  2.0) );
      Kernel_Sum : constant Float := 159.0;
      Sum : Float;
   begin
      Output := Input; -- Default to input (handles edges)
      for I in Input'First(1) + 2 .. Input'Last(1) - 2 loop
         for J in Input'First(2) + 2 .. Input'Last(2) - 2 loop
            Sum := 0.0;
            for KI in -2 .. 2 loop
               for KJ in -2 .. 2 loop
                  Sum := Sum + Float(Input (I + KI, J + KJ)) * Kernel (KI, KJ);
               end loop;
            end loop;
            Output (I, J) := Intensity (Sum / Kernel_Sum);
         end loop;
      end loop;
   end Gaussian_Blur;

   procedure Compute_Gradients (
      Input     : in  Image;
      Magnitude : out Image;
      Direction : out Image;
      Method    : in  Gradient_Magnitude_Method
   ) is
      Gx, Gy : Float;
      Angle  : Float;
      -- Sobel Operators
      type Sobel_Matrix is array (-1 .. 1, -1 .. 1) of Float;
      Kx : constant Sobel_Matrix := ((-1.0, 0.0, 1.0), (-2.0, 0.0, 2.0), (-1.0, 0.0, 1.0));
      Ky : constant Sobel_Matrix := ((1.0, 2.0, 1.0), (0.0, 0.0, 0.0), (-1.0, -2.0, -1.0));
   begin
      Magnitude := (others => (others => 0.0));
      Direction := (others => (others => 0.0));

      for I in Input'First(1) + 1 .. Input'Last(1) - 1 loop
         for J in Input'First(2) + 1 .. Input'Last(2) - 1 loop
            Gx := 0.0; Gy := 0.0;
            for KI in -1 .. 1 loop
               for KJ in -1 .. 1 loop
                  Gx := Gx + Float(Input (I + KI, J + KJ)) * Kx (KI, KJ);
                  Gy := Gy + Float(Input (I + KI, J + KJ)) * Ky (KI, KJ);
               end loop;
            end loop;

            -- Variant calculation
            if Method = Exact then
               Magnitude (I, J) := Intensity(Float'Min(255.0, Sqrt (Gx**2 + Gy**2)));
            else
               Magnitude (I, J) := Intensity(Float'Min(255.0, abs Gx + abs Gy));
            end if;

            -- Direction Mapping to 0, 45, 90, 135
            -- Avoid ADA.NUMERICS.ARGUMENT_ERROR when both Gx and Gy are 0 (e.g. uniform image)
            if Gx = 0.0 and Gy = 0.0 then
               Angle := 0.0;
            else
               Angle := Arctan (Y => Gy, X => Gx) * 180.0 / Ada.Numerics.Pi;
               if Angle < 0.0 then 
                  Angle := Angle + 180.0; 
               end if;
            end if;

            if (Angle >= 0.0 and Angle < 22.5) or (Angle >= 157.5 and Angle <= 180.0) then
               Direction (I, J) := 0.0;
            elsif Angle >= 22.5 and Angle < 67.5 then
               Direction (I, J) := 45.0;
            elsif Angle >= 67.5 and Angle < 112.5 then
               Direction (I, J) := 90.0;
            else
               Direction (I, J) := 135.0;
            end if;
         end loop;
      end loop;
   end Compute_Gradients;

   procedure Non_Maximum_Suppression (
      Magnitude : in  Image;
      Direction : in  Image;
      Output    : out Image
   ) is
      Q, R : Intensity;
      Dir  : Float;
   begin
      Output := (others => (others => 0.0));
      for I in Magnitude'First(1) + 1 .. Magnitude'Last(1) - 1 loop
         for J in Magnitude'First(2) + 1 .. Magnitude'Last(2) - 1 loop
            Dir := Float(Direction (I, J));
            Q := 255.0; R := 255.0;

            if Dir = 0.0 then
               Q := Magnitude (I, J + 1); R := Magnitude (I, J - 1);
            elsif Dir = 45.0 then
               Q := Magnitude (I - 1, J + 1); R := Magnitude (I + 1, J - 1);
            elsif Dir = 90.0 then
               Q := Magnitude (I + 1, J); R := Magnitude (I - 1, J);
            elsif Dir = 135.0 then
               Q := Magnitude (I - 1, J - 1); R := Magnitude (I + 1, J + 1);
            end if;

            if Magnitude(I, J) >= Q and Magnitude(I, J) >= R then
               Output (I, J) := Magnitude (I, J);
            else
               Output (I, J) := 0.0;
            end if;
         end loop;
      end loop;
   end Non_Maximum_Suppression;

   procedure Double_Threshold_And_Hysteresis (
      Input     : in  Image;
      Output    : out Image;
      Low_Thresh, High_Thresh : Intensity
   ) is
      Weak   : constant Intensity := 50.0;
      Strong : constant Intensity := 255.0;
      Changed : Boolean := True;
   begin
      Output := (others => (others => 0.0));
      -- Double Threshold
      for I in Input'Range(1) loop
         for J in Input'Range(2) loop
            if Input (I, J) >= High_Thresh then
               Output (I, J) := Strong;
            elsif Input (I, J) >= Low_Thresh then
               Output (I, J) := Weak;
            end if;
         end loop;
      end loop;

      -- Edge Tracking by Hysteresis (Iterative propagation)
      while Changed loop
         Changed := False;
         for I in Output'First(1) + 1 .. Output'Last(1) - 1 loop
            for J in Output'First(2) + 1 .. Output'Last(2) - 1 loop
               if Output (I, J) = Weak then
                  -- Check 8-connected neighbors
                  if Output(I-1, J-1) = Strong or Output(I-1, J) = Strong or
                     Output(I-1, J+1) = Strong or Output(I, J-1) = Strong or
                     Output(I, J+1) = Strong or Output(I+1, J-1) = Strong or
                     Output(I+1, J) = Strong or Output(I+1, J+1) = Strong
                  then
                     Output (I, J) := Strong;
                     Changed := True;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;

      -- Remove remaining weak edges
      for I in Output'Range(1) loop
         for J in Output'Range(2) loop
            if Output (I, J) = Weak then
               Output (I, J) := 0.0;
            end if;
         end loop;
      end loop;
   end Double_Threshold_And_Hysteresis;

   procedure Apply_Canny (
      Input          : in  Image;
      Output         : out Image;
      Low_Threshold  : in  Intensity;
      High_Threshold : in  Intensity;
      Method         : in  Gradient_Magnitude_Method := Exact
   ) is
      Blurred    : Image(Input'Range(1), Input'Range(2));
      Magnitude  : Image(Input'Range(1), Input'Range(2));
      Direction  : Image(Input'Range(1), Input'Range(2));
      Suppressed : Image(Input'Range(1), Input'Range(2));
   begin
      if Input'Length(1) < 5 or Input'Length(2) < 5 then
         raise Invalid_Image_Size;
      end if;
      if Low_Threshold >= High_Threshold then
         raise Invalid_Thresholds;
      end if;

      Gaussian_Blur (Input, Blurred);
      Compute_Gradients (Blurred, Magnitude, Direction, Method);
      Non_Maximum_Suppression (Magnitude, Direction, Suppressed);
      Double_Threshold_And_Hysteresis (Suppressed, Output, Low_Threshold, High_Threshold);
   end Apply_Canny;

end Canny_Edge_Detector;
