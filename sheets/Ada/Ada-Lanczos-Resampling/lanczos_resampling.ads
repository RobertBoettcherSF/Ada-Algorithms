--  Lanczos_Resampling — Ada 2023 educational package for Wikipedia
--  "Lanczos resampling": sinc-window reconstruction kernel for 1-D
--  signal resampling and separable 2-D image resize. Distinct from the
--  Krylov / tridiagonal eigenvalue algorithm in Ada-Lanczos.
--     L(x) = sinc(x) sinc(x/a)   if |x| < a,   else 0
--  with sinc(x) = sin(πx)/(πx), sinc(0)=1. Cap n ≤ 256 (1-D) /
--  N ≤ 64 per axis (2-D); educational Float. Edge modes: clamp /
--  reflect / zero.
--  Primary source:
--  https://en.wikipedia.org/wiki/Lanczos_resampling
--  Siblings (README): Ada-Nearest-Neighbor-Interpolation,
--  Ada-Tricubic-Interpolation; upcoming Bilinear, Bicubic.

pragma Ada_2022;

package Lanczos_Resampling
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   --  At most Max_Signal samples in a 1-D signal (indices 0 .. N-1).
   Max_Signal : constant := 256;

   --  At most Max_Image samples per 2-D axis.
   Max_Image : constant := 64;

   --  Lanczos parameter a (typically 2 or 3); hard educational cap.
   Max_A : constant := 8;

   subtype Signal_Size  is Natural range 0 .. Max_Signal;
   subtype Signal_Index is Natural range 0 .. Max_Signal - 1;

   subtype Image_Size  is Natural range 0 .. Max_Image;
   subtype Image_Index is Natural range 0 .. Max_Image - 1;

   subtype A_Param is Positive range 1 .. Max_A;

   type Sample_Array is array (Signal_Index range <>) of Float;
   type Image_Array is
     array (Image_Index range <>, Image_Index range <>) of Float;

   --  Packed 1-D signal on the integer lattice (unit spacing).
   type Signal_1D is record
      N      : Signal_Size := 0;
      Values : Sample_Array (0 .. Max_Signal - 1) := [others => 0.0];
      Valid  : Boolean := False;
   end record;

   --  Packed 2-D image / scalar field V(i,j); i = column (x), j = row (y).
   type Image_2D is record
      Nx, Ny : Image_Size := 0;
      Values : Image_Array
                 (0 .. Max_Image - 1, 0 .. Max_Image - 1) :=
                   [others => [others => 0.0]];
      Valid  : Boolean := False;
   end record;

   --  Ok             : evaluation / resize succeeded
   --  Empty          : zero-length signal / image
   --  Out_Of_Domain  : requested size exceeds Max_* caps
   --  Bad_Parameter  : illegal destination size 0, etc.
   --  Ill_Started    : unset / invalid container
   type Status is
     (Ok,
      Empty,
      Out_Of_Domain,
      Bad_Parameter,
      Ill_Started);

   --  How to fetch s_i when i ∉ [0, N−1].
   type Edge_Mode is (Clamp, Reflect, Zero);

   type Eval_Result is record
      Value   : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Resize_1D_Result is record
      Signal  : Signal_1D;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   type Resize_2D_Result is record
      Image   : Image_2D;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-6;
   Near_Tol    : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric helpers / kernel
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  Normalized sinc: sin(πx)/(πx), with sinc(0)=1.
   function Sinc (X : Float) return Float
     with Global => null;

   --  Lanczos kernel L_a(x): sinc(x) sinc(x/a) for |x| < a, else 0.
   function Kernel (A : A_Param; X : Float) return Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Signal (S : Signal_1D) return Boolean
     with Global => null;
   --  Valid flag set and 1 ≤ N ≤ Max_Signal.

   function Is_Valid_Image (Img : Image_2D) return Boolean
     with Global => null;
   --  Valid flag set and 1 ≤ Nx,Ny ≤ Max_Image.

   function In_Domain (S : Signal_1D; X : Float) return Boolean
     with Global => null;
   --  Valid and X ∈ [0, N−1].

   function In_Domain (Img : Image_2D; X, Y : Float) return Boolean
     with Global => null;
   --  Valid and (X,Y) ∈ [0,Nx−1]×[0,Ny−1].

   function Get (S : Signal_1D; I : Signal_Index) return Float
     with Pre => S.Valid and then I < S.N, Global => null;

   procedure Set
     (S : in out Signal_1D; I : Signal_Index; Value : Float)
     with Pre => S.Valid and then I < S.N;

   function Get (Img : Image_2D; I, J : Image_Index) return Float
     with Pre =>
       Img.Valid and then I < Img.Nx and then J < Img.Ny,
          Global => null;

   procedure Set
     (Img : in out Image_2D; I, J : Image_Index; Value : Float)
     with Pre =>
       Img.Valid and then I < Img.Nx and then J < Img.Ny;

   ---------------------------------------------------------------------------
   -- Edge-aware sample fetch (integer lattice index, may be out of range)
   ---------------------------------------------------------------------------

   function Fetch
     (S : Signal_1D; I : Integer; Edge : Edge_Mode) return Float
     with Pre => Is_Valid_Signal (S), Global => null;
   --  Clamp / reflect / zero outside [0, N−1].

   function Fetch
     (Img  : Image_2D;
      I, J : Integer;
      Edge : Edge_Mode) return Float
     with Pre => Is_Valid_Image (Img), Global => null;

   ---------------------------------------------------------------------------
   -- Resampling
   ---------------------------------------------------------------------------

   --  S(x) = Σ_{i=⌊x⌋−a+1}^{⌊x⌋+a} s_i L(x−i)  with edge handling.
   function Resample_1D
     (S    : Signal_1D;
      X    : Float;
      A    : A_Param := 3;
      Edge : Edge_Mode := Clamp) return Eval_Result;
   --  Empty / Ill_Started on bad S; else Ok (any real X; edges for s_i).

   --  Separable 2-D: nested 1-D Lanczos along x then y (same a, edge).
   function Resample_2D
     (Img  : Image_2D;
      X, Y : Float;
      A    : A_Param := 3;
      Edge : Edge_Mode := Clamp) return Eval_Result;

   --  Resize onto New_N samples; output site j maps to source
   --  x = j·(N−1)/(New_N−1) (or 0 if New_N=1). Identity when New_N=N.
   --  New_N is unconstrained Natural so oversized requests can return
   --  Out_Of_Domain (New_N > Max_Signal) or Bad_Parameter (New_N = 0).
   function Resize_1D
     (S     : Signal_1D;
      New_N : Natural;
      A     : A_Param := 3;
      Edge  : Edge_Mode := Clamp) return Resize_1D_Result;

   --  Separable resize: horizontal pass per row, then vertical per column.
   function Resize_2D
     (Img    : Image_2D;
      New_Nx : Natural;
      New_Ny : Natural;
      A      : A_Param := 3;
      Edge   : Edge_Mode := Clamp) return Resize_2D_Result;

   ---------------------------------------------------------------------------
   -- Builders / sample data
   ---------------------------------------------------------------------------

   function Make_Empty_Signal (N : Signal_Size) return Signal_1D
     with Pre => N >= 1 and then N <= Max_Signal, Global => null;

   function Make_Empty_Image (Nx, Ny : Image_Size) return Image_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_Image and then Ny <= Max_Image,
          Global => null;

   function Make_Constant_1D
     (N : Signal_Size; C : Float) return Signal_1D
     with Pre => N >= 1 and then N <= Max_Signal, Global => null;

   function Make_Ramp_1D
     (N : Signal_Size; Y0, Y1 : Float) return Signal_1D
     with Pre => N >= 1 and then N <= Max_Signal, Global => null;
   --  Values(i) = lerp(Y0,Y1,i/(N−1)); N=1 → Y0.

   function Make_Impulse_1D
     (N : Signal_Size; Center : Signal_Index; Amplitude : Float := 1.0)
      return Signal_1D
     with Pre =>
       N >= 1 and then N <= Max_Signal and then Center < N,
          Global => null;
   --  Single spike at Center; zeros elsewhere.

   function Make_Constant_2D
     (Nx, Ny : Image_Size; C : Float) return Image_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_Image and then Ny <= Max_Image,
          Global => null;

   function Make_Ramp_2D
     (Nx, Ny : Image_Size) return Image_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_Image and then Ny <= Max_Image,
          Global => null;
   --  Values(i,j) = i + 2j

   function Make_Checkerboard_2D
     (Nx, Ny : Image_Size; Lo, Hi : Float) return Image_2D
     with Pre =>
       Nx >= 1 and then Ny >= 1
       and then Nx <= Max_Image and then Ny <= Max_Image,
          Global => null;
   --  Values(i,j) = Hi if (i+j) even else Lo.

   function Make_Example_Impulse return Signal_1D
     with Global => null;
   --  Length 9, impulse at index 4

   function Make_Example_Ramp return Signal_1D
     with Global => null;
   --  Length 8, ramp 0 → 7

   function Make_Example_Checker return Image_2D
     with Global => null;
   --  8×8 checkerboard Lo=0, Hi=1

end Lanczos_Resampling;
