--  Filtered_Back_Projection — Ada 2023 educational package for discrete
--  Radon inversion via parallel-beam filtered back-projection (FBP).
--  Pipeline: phantom → forward project (sinogram) → Ram-Lak ramp filter
--  (spatial convolution) → back-project → reconstruct. Cap N ≤ 32;
--  educational Float. Pure Ada — no external FFT libraries.
--  Primary source:
--  https://en.wikipedia.org/wiki/Radon_transform
--  (inversion / filtered back-projection)
--  Sibling next (README): Ada-Kahan-Summation (Elementary / Unrestricted skipped).

pragma Ada_2022;

package Filtered_Back_Projection
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_N samples per image axis (indices 0 .. N-1 with N ≤ Max_N).
   Max_N      : constant := 32;
   Max_Angles : constant := 64;
   Max_Bins   : constant := 48;

   subtype Axis_Size   is Natural range 0 .. Max_N;
   subtype Axis_Index  is Natural range 0 .. Max_N - 1;
   subtype Angle_Size  is Natural range 0 .. Max_Angles;
   subtype Angle_Index is Natural range 0 .. Max_Angles - 1;
   subtype Bin_Size    is Natural range 0 .. Max_Bins;
   subtype Bin_Index   is Natural range 0 .. Max_Bins - 1;

   type Image_Values is
     array (Axis_Index range <>, Axis_Index range <>) of Float;

   --  Square packed image V(i,j) on the integer lattice; i = row, j = col.
   type Image_2D is record
      N      : Axis_Size := 0;
      Values : Image_Values (0 .. Max_N - 1, 0 .. Max_N - 1) :=
                 [others => [others => 0.0]];
      Valid  : Boolean := False;
   end record;

   type Sinogram_Values is
     array (Angle_Index range <>, Bin_Index range <>) of Float;

   --  Parallel-beam sinogram S(a,b): angle index a, detector bin b.
   type Sinogram is record
      N_Angles : Angle_Size := 0;
      N_Bins   : Bin_Size   := 0;
      Values   : Sinogram_Values
                   (0 .. Max_Angles - 1, 0 .. Max_Bins - 1) :=
                     [others => [others => 0.0]];
      Valid    : Boolean := False;
   end record;

   --  Ok              : operation succeeded
   --  Ill_Started     : unset / invalid container or empty args
   --  Dimension_Error : size mismatch (e.g. bins vs image for back-project)
   --  Too_Small       : N / N_Angles / N_Bins below educational minimum
   type Status is
     (Ok,
      Ill_Started,
      Dimension_Error,
      Too_Small);

   type Image_Result is record
      Image   : Image_2D;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Sinogram_Result is record
      Sino    : Sinogram;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Correlation_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   --  Educational minimums for meaningful discrete FBP demos.
   Min_N       : constant := 4;
   Min_Angles  : constant := 4;
   Min_Bins    : constant := 4;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Image_Sum (Img : Image_2D) return Float
     with Global => null;
   --  Sum of all valid pixels (0 if invalid).

   function Sinogram_Angle_Sum (S : Sinogram; A : Angle_Index) return Float
     with Global => null;
   --  Sum over bins of row A (0 if invalid / out of range).

   function Correlation (A, B : Image_2D) return Correlation_Result;
   --  Pearson correlation of equal-size valid images.

   ---------------------------------------------------------------------------
   -- Validation / accessors
   ---------------------------------------------------------------------------

   function Is_Valid_Image (Img : Image_2D) return Boolean
     with Global => null;
   --  Valid flag and 1 ≤ N ≤ Max_N.

   function Is_Valid_Sinogram (S : Sinogram) return Boolean
     with Global => null;
   --  Valid flag and 1 ≤ N_Angles ≤ Max_Angles, 1 ≤ N_Bins ≤ Max_Bins.

   function Large_Enough_Image (Img : Image_2D) return Boolean
     with Global => null;
   --  Valid and N ≥ Min_N.

   function Large_Enough_Sinogram (S : Sinogram) return Boolean
     with Global => null;
   --  Valid and N_Angles ≥ Min_Angles and N_Bins ≥ Min_Bins.

   function Get (Img : Image_2D; I, J : Axis_Index) return Float
     with Pre =>
       Img.Valid and then I < Img.N and then J < Img.N,
          Global => null;

   procedure Set
     (Img   : in out Image_2D;
      I, J  : Axis_Index;
      Value : Float)
     with Pre =>
       Img.Valid and then I < Img.N and then J < Img.N;

   function Get (S : Sinogram; A : Angle_Index; B : Bin_Index) return Float
     with Pre =>
       S.Valid
       and then A < S.N_Angles
       and then B < S.N_Bins,
          Global => null;

   procedure Set
     (S     : in out Sinogram;
      A     : Angle_Index;
      B     : Bin_Index;
      Value : Float)
     with Pre =>
       S.Valid
       and then A < S.N_Angles
       and then B < S.N_Bins;

   ---------------------------------------------------------------------------
   -- Builders / phantoms
   ---------------------------------------------------------------------------

   function Make_Empty_Image (N : Axis_Size) return Image_2D
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Valid N×N image filled with zeros.

   function Make_Empty_Sinogram
     (N_Angles : Angle_Size; N_Bins : Bin_Size) return Sinogram
     with Pre =>
       N_Angles >= 1 and then N_Angles <= Max_Angles
       and then N_Bins >= 1 and then N_Bins <= Max_Bins,
          Global => null;
   --  Valid zero sinogram.

   function Make_Disk_Phantom
     (N : Axis_Size; Radius : Float) return Image_Result;
   --  Unit disk of given radius centered at ((N−1)/2,(N−1)/2).
   --  Too_Small if N < Min_N; Ill_Started if N = 0 or Radius ≤ 0.

   function Make_Shepp_Lite (N : Axis_Size) return Image_Result;
   --  Tiny teaching phantom: bright outer disk + two darker interior disks
   --  (not a clinical Shepp–Logan; educational only).

   ---------------------------------------------------------------------------
   -- FBP pipeline
   ---------------------------------------------------------------------------

   function Forward_Project
     (Img      : Image_2D;
      N_Angles : Angle_Size;
      N_Bins   : Bin_Size) return Sinogram_Result;
   --  Discrete parallel-beam Radon: for θ_a = a·π/N_Angles and detector
   --  offsets t_b = b − (N_Bins−1)/2, sum nearest-neighbour samples along
   --  each ray (step 1/2). Mass ≈ Σ image for each angle when sampling is
   --  adequate.

   function Filter_Ram_Lak (S : Sinogram) return Sinogram_Result;
   --  1-D spatial convolution of each projection with the discrete Ram-Lak
   --  ramp kernel h[0]=1/4, h[k]=0 (k even ≠0), h[k]=−1/(π²k²) (k odd).
   --  Pure Ada — no FFT.

   function Back_Project
     (S : Sinogram; N : Axis_Size) return Image_Result;
   --  Smear filtered projections onto an N×N grid with linear detector
   --  interpolation; scale by π/N_Angles. Prefer filtered sinograms.

   function Reconstruct_FBP
     (Img      : Image_2D;
      N_Angles : Angle_Size;
      N_Bins   : Bin_Size) return Image_Result;
   --  Forward_Project → Filter_Ram_Lak → Back_Project (image size = Img.N).

   ---------------------------------------------------------------------------
   -- Filter kernel helper (exposed for tests / teaching)
   ---------------------------------------------------------------------------

   function Ram_Lak_Kernel_Value (K : Integer) return Float
     with Global => null;
   --  Discrete Ram-Lak impulse response at lag K.

end Filtered_Back_Projection;
