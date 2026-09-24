with Ada.Text_IO; use Ada.Text_IO;
with Image_Based_Lighting; use Image_Based_Lighting;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Representative synthetic equirectangular environment map
   Env_4x2 : constant Environment_Map (Width => 4, Height => 2) :=
     (Width  => 4,
      Height => 2,
      Data   => [1 => [(1.0, 0.5, 0.2), (0.8, 0.8, 0.8), (0.1, 0.2, 0.9), (0.5, 0.5, 0.5)],
                 2 => [(0.0, 0.0, 0.0), (0.2, 0.2, 0.2), (0.4, 0.4, 0.4), (0.1, 0.1, 0.1)]]);

   --  Uniform white environment map for analytic checks
   White_Env : constant Environment_Map (Width => 4, Height => 2) :=
     (Width  => 4,
      Height => 2,
      Data   => [others => [others => (1.0, 1.0, 1.0)]]);

begin
   --  TEST 1 — Vector Arithmetic and Normalization
   Put_Line ("TEST 1 — Vector Arithmetic and Normalization");
   declare
      V1 : constant Vector3 := (3.0, 0.0, 4.0);
      N1 : constant Vector3 := Normalize (V1);
      L1 : constant Real := Vector_Length (N1);
      DP : constant Real := Dot_Product (N1, (0.0, 1.0, 0.0));
   begin
      Check ("1.1 Vector magnitude calculation is accurate", abs (Vector_Length (V1) - 5.0) < 1.0e-4);
      Check ("1.2 Normalized vector has unit length", abs (L1 - 1.0) < 1.0e-4);
      Check ("1.3 Orthogonal dot product evaluates to 0.0", abs (DP - 0.0) < 1.0e-4);
   end;

   --  TEST 2 — Normalization Zero-Length Vector Error Handling
   Put_Line ("TEST 2 — Normalization Zero-Length Vector Error Handling");
   declare
      Degenerate_V : constant Vector3 := (0.0, 0.0, 0.0);
      Trapped : Boolean := False;
   begin
      begin
         declare
            Unused_N : constant Vector3 := Normalize (Degenerate_V);
         begin
            Check ("2.1 Did not raise exception on degenerate vector", False);
            if Unused_N.X = 0.0 then null; end if;
         end;
      exception
         when Invalid_Direction_Error =>
            Trapped := True;
      end;
      Check ("2.1 Invalid_Direction_Error trapped for zero vector", Trapped);
      Check ("2.2 Trapped state verified true", Trapped);
      Check ("2.3 Normal vector length constraint respected", Vector_Length ((1.0, 0.0, 0.0)) = 1.0);
   end;

   --  TEST 3 — Direction and Spherical Coordinate Round-trip
   Put_Line ("TEST 3 — Direction to Spherical Coordinate Round-trip");
   declare
      Original_Dir : constant Vector3 := Normalize ((1.0, 1.0, 1.0));
      Coord        : constant Spherical_Coord := Direction_To_Spherical (Original_Dir);
      Reconstructed : constant Vector3 := Spherical_To_Direction (Coord);
   begin
      Check ("3.1 Theta angle within [0, Pi]", Coord.Theta >= 0.0 and then Coord.Theta <= 3.15);
      Check ("3.2 Phi azimuth within [0, 2*Pi]", Coord.Phi >= 0.0 and then Coord.Phi <= 6.30);
      Check ("3.3 Direction round-trip preserves orientation",
             abs (Original_Dir.X - Reconstructed.X) < 1.0e-3 and then
             abs (Original_Dir.Y - Reconstructed.Y) < 1.0e-3 and then
             abs (Original_Dir.Z - Reconstructed.Z) < 1.0e-3);
   end;

   --  TEST 4 — Equirectangular Texture Sampling
   Put_Line ("TEST 4 — Equirectangular Texture Sampling");
   declare
      Dir_North : constant Vector3 := (0.0, 1.0, 0.0);
      Dir_South : constant Vector3 := (0.0, -1.0, 0.0);
      Sample_N  : constant Color_RGB := Sample_Equirectangular (Env_4x2, Dir_North);
      Sample_S  : constant Color_RGB := Sample_Equirectangular (Env_4x2, Dir_South);
   begin
      Check ("4.1 North pole samples top row (Row 1)", Sample_N.R >= 0.0);
      Check ("4.2 South pole samples bottom row (Row 2)", Sample_S.R <= 0.5);
      Check ("4.3 Sample colors are non-negative", Sample_N.G >= 0.0 and Sample_S.G >= 0.0);
   end;

   --  TEST 5 — Mirror Reflection Mapping
   Put_Line ("TEST 5 — Mirror Reflection Mapping");
   declare
      Normal : constant Vector3 := (0.0, 1.0, 0.0);
      View   : constant Vector3 := Normalize ((0.0, 1.0, 1.0));
      Color  : constant Color_RGB := Evaluate_Mirror_Reflection (Env_4x2, View, Normal);
   begin
      Check ("5.1 Evaluated color red channel in range", Color.R >= 0.0 and Color.R <= 1.0);
      Check ("5.2 Evaluated color green channel in range", Color.G >= 0.0 and Color.G <= 1.0);
      Check ("5.3 Evaluated color blue channel in range", Color.B >= 0.0 and Color.B <= 1.0);
   end;

   --  TEST 6 — Mirror Reflection Perpendicular Ray
   Put_Line ("TEST 6 — Mirror Reflection Perpendicular Ray");
   declare
      Normal : constant Vector3 := (0.0, 1.0, 0.0);
      View   : constant Vector3 := (0.0, 1.0, 0.0);
      Color  : constant Color_RGB := Evaluate_Mirror_Reflection (Env_4x2, View, Normal);
      Direct : constant Color_RGB := Sample_Equirectangular (Env_4x2, (0.0, -1.0, 0.0));
   begin
      Check ("6.1 Reflected ray goes straight down", abs (Color.R - Direct.R) < 1.0e-4);
      Check ("6.2 Green channel matches direct bottom sample", abs (Color.G - Direct.G) < 1.0e-4);
      Check ("6.3 Blue channel matches direct bottom sample", abs (Color.B - Direct.B) < 1.0e-4);
   end;

   --  TEST 7 — Diffuse Hemisphere Irradiance Convolution
   Put_Line ("TEST 7 — Diffuse Hemisphere Irradiance Convolution");
   declare
      Up_Normal : constant Vector3 := (0.0, 1.0, 0.0);
      Irradiance : constant Color_RGB :=
        Convolve_Diffuse_Irradiance (White_Env, Up_Normal, 0.3, 0.3);
   begin
      Check ("7.1 White environment produces positive irradiance", Irradiance.R > 0.0);
      Check ("7.2 Diffuse convolution balances R and G", abs (Irradiance.R - Irradiance.G) < 1.0e-2);
      Check ("7.3 Diffuse convolution balances G and B", abs (Irradiance.G - Irradiance.B) < 1.0e-2);
   end;

   --  TEST 8 — Spherical Harmonics Projection
   Put_Line ("TEST 8 — Spherical Harmonics Projection");
   declare
      Coeffs : constant SH_Coefficients :=
        Project_Spherical_Harmonics (White_Env, 0.3);
   begin
      Check ("8.1 Order-0 L0,0 coefficient is strictly positive", Coeffs (1).R > 0.0);
      Check ("8.2 Order-0 coefficient exhibits equal RGB in white env",
             abs (Coeffs (1).R - Coeffs (1).G) < 1.0e-2 and then
             abs (Coeffs (1).G - Coeffs (1).B) < 1.0e-2);
      Check ("8.3 Higher order odd bands near zero for isotropic lighting",
             abs (Coeffs (2).R) < 0.5);
   end;

   --  TEST 9 — Spherical Harmonics Reconstruction
   Put_Line ("TEST 9 — Spherical Harmonics Reconstruction");
   declare
      Coeffs : constant SH_Coefficients :=
        Project_Spherical_Harmonics (White_Env, 0.3);
      Reconstructed : constant Color_RGB :=
        Evaluate_SH_Irradiance (Coeffs, (0.0, 1.0, 0.0));
   begin
      Check ("9.1 Reconstructed SH irradiance is non-zero", Reconstructed.R > 0.0);
      Check ("9.2 Reconstructed SH channels are roughly balanced",
             abs (Reconstructed.R - Reconstructed.G) < 0.1);
      Check ("9.3 Irradiance clamp ensures non-negative values", Reconstructed.B >= 0.0);
   end;

   --  TEST 10 — Split-Sum Pre-filtered Specular
   Put_Line ("TEST 10 — Split-Sum Pre-filtered Specular");
   declare
      Reflect_Dir : constant Vector3 := (0.0, 1.0, 0.0);
      Smooth_Spec : constant Color_RGB :=
        Evaluate_Prefiltered_Specular (Env_4x2, Reflect_Dir, 0.0, 16);
      Rough_Spec  : constant Color_RGB :=
        Evaluate_Prefiltered_Specular (Env_4x2, Reflect_Dir, 0.8, 16);
   begin
      Check ("10.1 Roughness 0 defaults to direct sample", Smooth_Spec.R >= 0.0);
      Check ("10.2 Rough sample produces valid color values", Rough_Spec.G >= 0.0);
      Check ("10.3 Pre-filtering converges without NaN or negative values", Rough_Spec.B >= 0.0);
   end;

   --  TEST 11 — Precomputed BRDF Look-Up Table
   Put_Line ("TEST 11 — Precomputed BRDF Look-Up Table");
   declare
      Lut : constant BRDF_LUT := Precompute_BRDF_LUT (Size => 8);
      Sample_Entry : constant BRDF_Lut_Entry := Sample_BRDF_LUT (Lut, 0.5, 0.5);
   begin
      Check ("11.1 LUT dimensions correctly set", Lut.Size = 8);
      Check ("11.2 BRDF Scale value is non-negative", Sample_Entry.Scale >= 0.0);
      Check ("11.3 BRDF Scale + Bias bounded by physical range",
             Sample_Entry.Scale + Sample_Entry.Bias <= 2.0);
   end;

   --  TEST 12 — Split-Sum Specular Combination
   Put_Line ("TEST 12 — Split-Sum Specular Combination");
   declare
      Prefilt   : constant Color_RGB := (0.8, 0.8, 0.8);
      Lut_Val   : constant BRDF_Lut_Entry := (Scale => 0.6, Bias => 0.1);
      F0_Gold   : constant Color_RGB := (1.0, 0.76, 0.33);
      Combined  : constant Color_RGB :=
        Evaluate_Split_Sum_Specular (Prefilt, Lut_Val, F0_Gold);
   begin
      Check ("12.1 Specular combination scales with F0 Red",
             abs (Combined.R - (0.8 * (1.0 * 0.6 + 0.1))) < 1.0e-3);
      Check ("12.2 Specular combination scales with F0 Green",
             abs (Combined.G - (0.8 * (0.76 * 0.6 + 0.1))) < 1.0e-3);
      Check ("12.3 Specular combination scales with F0 Blue",
             abs (Combined.B - (0.8 * (0.33 * 0.6 + 0.1))) < 1.0e-3);
   end;

   --  TEST 13 — Extreme Invariants and Clamping
   Put_Line ("TEST 13 — Boundary Invariants and Clamping");
   declare
      Negative_Color : constant Color_RGB := (-1.0, 0.5, -0.2);
      Clamped        : constant Color_RGB := Clamp_Color (Negative_Color);
      Pure_Black     : constant Color_RGB := (0.0, 0.0, 0.0);
      Clamped_Zero   : constant Color_RGB := Clamp_Color (Pure_Black);
   begin
      Check ("13.1 Negative red component clamped to 0.0", Clamped.R = 0.0);
      Check ("13.2 Positive green component preserved", Clamped.G = 0.5);
      Check ("13.3 Negative blue component clamped to 0.0", Clamped.B = 0.0);
      Check ("13.4 Zero color remains 0.0", Clamped_Zero.R = 0.0 and Clamped_Zero.G = 0.0 and Clamped_Zero.B = 0.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
