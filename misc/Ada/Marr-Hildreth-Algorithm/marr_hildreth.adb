-- marr_hildreth.adb
-- Implementation of Marr-Hildreth edge detection variants and utilities.

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Marr_Hildreth is

   Pi : constant Float := 3.14159_26535_89793;

   --------------------------
   -- Validate_Parameters --
   --------------------------
   function Validate_Parameters (Params : Parameters) return Boolean is
   begin
      if Params.Sigma <= 0.0 or Params.Sigma_Ratio <= 1.0 then
         return False;
      end if;

      -- Kernel dimension must be odd and within valid range
      if Params.Kernel_Dim mod 2 = 0 then
         return False;
      end if;

      return True;
   end Validate_Parameters;

   -----------------------
   -- Create_LoG_Kernel --
   -----------------------
   function Create_LoG_Kernel (Params : Parameters) return Image_Grid is
      Dim    : constant Integer := Integer (Params.Kernel_Dim);
      Half   : constant Integer := Dim / 2;
      Sig2   : constant Float := Params.Sigma * Params.Sigma;
      Kernel : Image_Grid (1 .. Dim, 1 .. Dim);
      X, Y   : Float;
      Val    : Float;
   begin
      if not Validate_Parameters (Params) then
         raise Invalid_Parameters;
      end if;

      for I in 1 .. Dim loop
         for J in 1 .. Dim loop
            X := Float (I - 1 - Half);
            Y := Float (J - 1 - Half);

            -- LoG formula: -1 / (pi * sigma^4) * (1 - (x^2 + y^2)/(2*sigma^2)) * exp(-(x^2 + y^2)/(2*sigma^2))
            Val := -1.0 / (Pi * Sig2 * Sig2) *
                   (1.0 - (X * X + Y * Y) / (2.0 * Sig2)) *
                   Exp (-(X * X + Y * Y) / (2.0 * Sig2));

            Kernel (I, J) := Intensity (Val);
         end loop;
      end loop;

      return Kernel;
   end Create_LoG_Kernel;

   -----------------------
   -- Create_DoG_Kernel --
   -----------------------
   function Create_DoG_Kernel (Params : Parameters) return Image_Grid is
      Dim    : constant Integer := Integer (Params.Kernel_Dim);
      Half   : constant Integer := Dim / 2;
      Sig1   : constant Float := Params.Sigma;
      Sig2   : constant Float := Params.Sigma * Params.Sigma_Ratio;
      Sig1_2 : constant Float := Sig1 * Sig1;
      Sig2_2 : constant Float := Sig2 * Sig2;
      Kernel : Image_Grid (1 .. Dim, 1 .. Dim);
      X, Y   : Float;
      G1, G2 : Float;
   begin
      if not Validate_Parameters (Params) then
         raise Invalid_Parameters;
      end if;

      for I in 1 .. Dim loop
         for J in 1 .. Dim loop
            X := Float (I - 1 - Half);
            Y := Float (J - 1 - Half);

            G1 := (1.0 / (2.0 * Pi * Sig1_2)) * Exp (-(X * X + Y * Y) / (2.0 * Sig1_2));
            G2 := (1.0 / (2.0 * Pi * Sig2_2)) * Exp (-(X * X + Y * Y) / (2.0 * Sig2_2));

            Kernel (I, J) := Intensity (G1 - G2);
         end loop;
      end loop;

      return Kernel;
   end Create_DoG_Kernel;

   ------------------
   -- Convolve_2D --
   ------------------
   procedure Convolve_2D
     (Input_Image    : in  Image_Grid;
      Kernel         : in  Image_Grid;
      Filtered_Image : out Image_Grid)
   is
      Rows     : constant Integer := Input_Image'Length (1);
      Cols     : constant Integer := Input_Image'Length (2);
      K_Dim    : constant Integer := Kernel'Length (1);
      K_Half   : constant Integer := K_Dim / 2;
      Sum      : Float;
      Img_X    : Integer;
      Img_Y    : Integer;
   begin
      for I in Input_Image'Range (1) loop
         for J in Input_Image'Range (2) loop
            Sum := 0.0;
            for KI in 1 .. K_Dim loop
               for KJ in 1 .. K_Dim loop
                  Img_X := I + (KI - 1 - K_Half);
                  Img_Y := J + (KJ - 1 - K_Half);

                  -- Zero-padding edge handling
                  if Img_X in Input_Image'Range (1) and then Img_Y in Input_Image'Range (2) then
                     Sum := Sum + Float (Input_Image (Img_X, Img_Y)) * Float (Kernel (KI, KJ));
                  end if;
               end loop;
            end loop;
            Filtered_Image (I, J) := Intensity (Sum);
         end loop;
      end loop;
   end Convolve_2D;

   ---------------------------
   -- Detect_Zero_Crossings --
   ---------------------------
   procedure Detect_Zero_Crossings
     (Filtered_Image : in  Image_Grid;
      Output_Edges   : out Edge_Grid;
      Threshold      : in  Intensity)
   is
      Rows : constant Integer := Filtered_Image'Length (1);
      Cols : constant Integer := Filtered_Image'Length (2);
      Val  : Float;
      N    : Float;
      Is_Edge : Boolean;
   begin
      -- Default to Background
      for I in Output_Edges'Range (1) loop
         for J in Output_Edges'Range (2) loop
            Output_Edges (I, J) := Background;
         end loop;
      end loop;

      -- Check neighbors (4-neighborhood) for opposite sign and threshold difference
      for I in Filtered_Image'First (1) + 1 .. Filtered_Image'Last (1) - 1 loop
         for J in Filtered_Image'First (2) + 1 .. Filtered_Image'Last (2) - 1 loop
            Val := Float (Filtered_Image (I, J));
            Is_Edge := False;

            -- Check 4-connected neighbors
            declare
               Neighbors : constant array (1 .. 4) of Float :=
                 (Float (Filtered_Image (I - 1, J)),
                  Float (Filtered_Image (I + 1, J)),
                  Float (Filtered_Image (I, J - 1)),
                  Float (Filtered_Image (I, J + 1)));
            begin
               for K in Neighbors'Range loop
                  N := Neighbors (K);
                  if (Val * N < 0.0) and then (abs (Val - N) >= Float (Threshold)) then
                     Is_Edge := True;
                     exit;
                  end if;
               end loop;
            end;

            if Is_Edge then
               Output_Edges (I, J) := Edge;
            end if;
         end loop;
      end loop;
   end Detect_Zero_Crossings;

   ----------------------
   -- Detect_Edges_LoG --
   ----------------------
   procedure Detect_Edges_LoG
     (Input_Image  : in  Image_Grid;
      Output_Edges : out Edge_Grid;
      Params       : in  Parameters)
   is
      Filtered : Image_Grid (Input_Image'Range (1), Input_Image'Range (2));
   begin
      if Input_Image'Length (1) /= Output_Edges'Length (1) or else
         Input_Image'Length (2) /= Output_Edges'Length (2) then
         raise Invalid_Image_Bounds;
      end if;

      if not Validate_Parameters (Params) then
         raise Invalid_Parameters;
      end if;

      declare
         Kernel : constant Image_Grid := Create_LoG_Kernel (Params);
      begin
         Convolve_2D (Input_Image, Kernel, Filtered);
         Detect_Zero_Crossings (Filtered, Output_Edges, Params.Threshold);
      end;
   end Detect_Edges_LoG;

   ----------------------
   -- Detect_Edges_DoG --
   ----------------------
   procedure Detect_Edges_DoG
     (Input_Image  : in  Image_Grid;
      Output_Edges : out Edge_Grid;
      Params       : in  Parameters)
   is
      Filtered : Image_Grid (Input_Image'Range (1), Input_Image'Range (2));
   begin
      if Input_Image'Length (1) /= Output_Edges'Length (1) or else
         Input_Image'Length (2) /= Output_Edges'Length (2) then
         raise Invalid_Image_Bounds;
      end if;

      if not Validate_Parameters (Params) then
         raise Invalid_Parameters;
      end if;

      declare
         Kernel : constant Image_Grid := Create_DoG_Kernel (Params);
      begin
         Convolve_2D (Input_Image, Kernel, Filtered);
         Detect_Zero_Crossings (Filtered, Output_Edges, Params.Threshold);
      end;
   end Detect_Edges_DoG;

end Marr_Hildreth;
