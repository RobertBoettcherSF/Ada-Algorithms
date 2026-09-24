--  Multivariate_Interpolation body — survey taxonomy + runnable sketches.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Multivariate_Interpolation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Lerp (A, B : Float; T : Float) return Float is
   begin
      return (1.0 - T) * A + T * B;
   end Lerp;

   function Cubic_1D
     (P0, P1, P2, P3 : Float; T : Float) return Float
   is
      T2 : constant Float := T * T;
      T3 : constant Float := T2 * T;
   begin
      return 0.5 *
        ((2.0 * P1)
         + (-P0 + P2) * T
         + (2.0 * P0 - 5.0 * P1 + 4.0 * P2 - P3) * T2
         + (-P0 + 3.0 * P1 - 3.0 * P2 + P3) * T3);
   end Cubic_1D;

   function Round_Index (X : Float; Last : Natural) return Natural is
      Base : Float;
      Frac : Float;
      Idx  : Integer;
   begin
      if Last = 0 then
         return 0;
      end if;
      if X <= 0.0 then
         return 0;
      end if;
      if X >= Float (Last) then
         return Last;
      end if;
      Base := Float'Floor (X);
      Frac := X - Base;
      if Frac > 0.5 then
         Idx := Integer (Base) + 1;
      else
         Idx := Integer (Base);
      end if;
      if Idx < 0 then
         return 0;
      elsif Idx > Integer (Last) then
         return Last;
      else
         return Natural (Idx);
      end if;
   end Round_Index;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Grid (G : Grid_2D) return Boolean is
   begin
      return G.Valid and then G.Nx >= 1 and then G.Ny >= 1;
   end Is_Valid_Grid;

   function Is_Valid_Grid (G : Grid_3D) return Boolean is
   begin
      return G.Valid
        and then G.Nx >= 1
        and then G.Ny >= 1
        and then G.Nz >= 1;
   end Is_Valid_Grid;

   function Is_Valid_Scattered (S : Scattered_2D) return Boolean is
   begin
      return S.Valid and then S.Count >= 1;
   end Is_Valid_Scattered;

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (G.Ny - 1);
   end In_Domain;

   function In_Domain (G : Grid_3D; X, Y, Z : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (G.Ny - 1)
        and then Z >= 0.0 and then Z <= Float (G.Nz - 1);
   end In_Domain;

   function Large_Enough_Bilinear (G : Grid_2D) return Boolean is
   begin
      return Is_Valid_Grid (G)
        and then G.Nx >= 2
        and then G.Ny >= 2;
   end Large_Enough_Bilinear;

   function Large_Enough_Bicubic (G : Grid_2D) return Boolean is
   begin
      return Is_Valid_Grid (G)
        and then G.Nx >= 4
        and then G.Ny >= 4;
   end Large_Enough_Bicubic;

   function Large_Enough_Trilinear (G : Grid_3D) return Boolean is
   begin
      return Is_Valid_Grid (G)
        and then G.Nx >= 2
        and then G.Ny >= 2
        and then G.Nz >= 2;
   end Large_Enough_Trilinear;

   function Get (G : Grid_2D; I, J : Axis_Index) return Float is
   begin
      return G.Values (I, J);
   end Get;

   procedure Set
     (G : in out Grid_2D; I, J : Axis_Index; Value : Float)
   is
   begin
      G.Values (I, J) := Value;
   end Set;

   function Get (G : Grid_3D; I, J, K : Axis_Index) return Float is
   begin
      return G.Values (I, J, K);
   end Get;

   procedure Set
     (G       : in out Grid_3D;
      I, J, K : Axis_Index;
      Value   : Float)
   is
   begin
      G.Values (I, J, K) := Value;
   end Set;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Nearest_Neighbor  => return "Nearest-neighbor";
         when Bilinear          => return "Bilinear";
         when Bicubic           => return "Bicubic (Keys/Catmull-Rom)";
         when Trilinear         => return "Trilinear";
         when Tricubic          => return "Tricubic";
         when Lanczos           => return "Lanczos resampling";
         when Inverse_Distance  => return "Inverse distance weighting";
         when Kriging           => return "Kriging";
         when Natural_Neighbor  => return "Natural-neighbor";
         when Radial_Basis      => return "Radial basis function";
         when Spline_Tensor     => return "Tensor-product spline";
         when Barnes            => return "Barnes interpolation";
      end case;
   end Method_Name;

   function Supports_Runnable (M : Method_Kind) return Boolean is
   begin
      case M is
         when Nearest_Neighbor
            | Bilinear
            | Bicubic
            | Trilinear
            | Inverse_Distance =>
            return True;
         when others =>
            return False;
      end case;
   end Supports_Runnable;

   function Describe (M : Method_Kind) return String is
   begin
      case M is
         when Nearest_Neighbor =>
            return "Piecewise-constant; round to nearest sample / site.";
         when Bilinear =>
            return "Repeated linear lerp on a regular 2-D cell (C0).";
         when Bicubic =>
            return "Tensor Catmull-Rom / Keys cubic on a 4x4 stencil.";
         when Trilinear =>
            return "Repeated linear lerp on a regular 3-D cell (C0).";
         when Tricubic =>
            return "Tensor cubic on a 4x4x4 stencil (see Ada-Tricubic).";
         when Lanczos =>
            return "Sinc-windowed kernel resampling (see Ada-Lanczos).";
         when Inverse_Distance =>
            return "Scattered IDW: weight 1/d^P; exact on coinciding site.";
         when Kriging =>
            return "Catalogue: geostatistical BLUE (not sketched here).";
         when Natural_Neighbor =>
            return "Catalogue: Voronoi-area weights (not sketched here).";
         when Radial_Basis =>
            return "Catalogue: RBF / thin-plate (not sketched here).";
         when Spline_Tensor =>
            return "Catalogue: tensor-product spline (see Ada-Spline).";
         when Barnes =>
            return "Catalogue: successive Gaussian corrections (2-D).";
      end case;
   end Describe;

   function Classify_Method (M : Method_Kind) return Method_Info is
      Info : Method_Info;
   begin
      Info.Kind := M;
      case M is
         when Nearest_Neighbor =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 3;
            Info.For_Scattered := True;
            Info.For_Regular := True;
            Info.Runnable_Sketch := True;
            Info.Smooth := Piecewise_Constant;
         when Bilinear =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 2;
            Info.For_Scattered := False;
            Info.For_Regular := True;
            Info.Runnable_Sketch := True;
            Info.Smooth := C0_Continuous;
         when Bicubic =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 2;
            Info.For_Scattered := False;
            Info.For_Regular := True;
            Info.Runnable_Sketch := True;
            Info.Smooth := C1_Smooth;
         when Trilinear =>
            Info.Dim_Min := 3;
            Info.Dim_Max := 3;
            Info.For_Scattered := False;
            Info.For_Regular := True;
            Info.Runnable_Sketch := True;
            Info.Smooth := C0_Continuous;
         when Tricubic =>
            Info.Dim_Min := 3;
            Info.Dim_Max := 3;
            Info.For_Scattered := False;
            Info.For_Regular := True;
            Info.Runnable_Sketch := False;
            Info.Smooth := C1_Smooth;
         when Lanczos =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 2;
            Info.For_Scattered := False;
            Info.For_Regular := True;
            Info.Runnable_Sketch := False;
            Info.Smooth := C1_Smooth;
         when Inverse_Distance =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 3;
            Info.For_Scattered := True;
            Info.For_Regular := True;
            Info.Runnable_Sketch := True;
            Info.Smooth := C0_Continuous;
         when Kriging =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 3;
            Info.For_Scattered := True;
            Info.For_Regular := True;
            Info.Runnable_Sketch := False;
            Info.Smooth := C0_Continuous;
         when Natural_Neighbor =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 2;
            Info.For_Scattered := True;
            Info.For_Regular := False;
            Info.Runnable_Sketch := False;
            Info.Smooth := C0_Continuous;
         when Radial_Basis =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 3;
            Info.For_Scattered := True;
            Info.For_Regular := False;
            Info.Runnable_Sketch := False;
            Info.Smooth := C1_Smooth;
         when Spline_Tensor =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 3;
            Info.For_Scattered := False;
            Info.For_Regular := True;
            Info.Runnable_Sketch := False;
            Info.Smooth := C1_Smooth;
         when Barnes =>
            Info.Dim_Min := 2;
            Info.Dim_Max := 2;
            Info.For_Scattered := True;
            Info.For_Regular := True;
            Info.Runnable_Sketch := False;
            Info.Smooth := C0_Continuous;
      end case;
      return Info;
   end Classify_Method;

   function Recommend_Method
     (Layout : Data_Layout;
      Dim    : Space_Dim;
      Want   : Smoothness := C0_Continuous) return Method_Kind
   is
   begin
      if Layout = Scattered then
         if Want = Piecewise_Constant then
            return Nearest_Neighbor;
         else
            return Inverse_Distance;
         end if;
      end if;

      --  Regular grid
      if Dim = 2 then
         case Want is
            when Piecewise_Constant => return Nearest_Neighbor;
            when C0_Continuous      => return Bilinear;
            when C1_Smooth          => return Bicubic;
         end case;
      else
         case Want is
            when Piecewise_Constant => return Nearest_Neighbor;
            when C0_Continuous      => return Trilinear;
            when C1_Smooth          => return Tricubic;
         end case;
      end if;
   end Recommend_Method;

   ---------------------------------------------------------------------------
   -- Internal sampling / cell helpers (2-D)
   ---------------------------------------------------------------------------

   function Sample_2D
     (G : Grid_2D; I, J : Integer) return Float
     with Pre => Is_Valid_Grid (G)
   is
      Last_X : constant Integer := Integer (G.Nx) - 1;
      Last_Y : constant Integer := Integer (G.Ny) - 1;
   begin
      if I < 0 then
         return 2.0 * Sample_2D (G, 0, J) - Sample_2D (G, -I, J);
      elsif I > Last_X then
         return 2.0 * Sample_2D (G, Last_X, J)
           - Sample_2D (G, 2 * Last_X - I, J);
      elsif J < 0 then
         return 2.0 * Sample_2D (G, I, 0) - Sample_2D (G, I, -J);
      elsif J > Last_Y then
         return 2.0 * Sample_2D (G, I, Last_Y)
           - Sample_2D (G, I, 2 * Last_Y - J);
      else
         return G.Values (Axis_Index (I), Axis_Index (J));
      end if;
   end Sample_2D;

   function Sample_3D
     (G : Grid_3D; I, J, K : Integer) return Float
     with Pre => Is_Valid_Grid (G)
   is
      Last_X : constant Integer := Integer (G.Nx) - 1;
      Last_Y : constant Integer := Integer (G.Ny) - 1;
      Last_Z : constant Integer := Integer (G.Nz) - 1;
   begin
      if I < 0 then
         return 2.0 * Sample_3D (G, 0, J, K) - Sample_3D (G, -I, J, K);
      elsif I > Last_X then
         return 2.0 * Sample_3D (G, Last_X, J, K)
           - Sample_3D (G, 2 * Last_X - I, J, K);
      elsif J < 0 then
         return 2.0 * Sample_3D (G, I, 0, K) - Sample_3D (G, I, -J, K);
      elsif J > Last_Y then
         return 2.0 * Sample_3D (G, I, Last_Y, K)
           - Sample_3D (G, I, 2 * Last_Y - J, K);
      elsif K < 0 then
         return 2.0 * Sample_3D (G, I, J, 0) - Sample_3D (G, I, J, -K);
      elsif K > Last_Z then
         return 2.0 * Sample_3D (G, I, J, Last_Z)
           - Sample_3D (G, I, J, 2 * Last_Z - K);
      else
         return G.Values
           (Axis_Index (I), Axis_Index (J), Axis_Index (K));
      end if;
   end Sample_3D;

   procedure Cell_Origin
     (Coord : Float; N : Axis_Size; I0 : out Integer; T : out Float)
     with Pre => N >= 2
   is
      Last : constant Float := Float (N - 1);
   begin
      if Coord >= Last then
         I0 := Integer (N) - 2;
         T  := 1.0;
      elsif Coord <= 0.0 then
         I0 := 0;
         T  := 0.0;
      else
         I0 := Integer (Float'Floor (Coord));
         if I0 > Integer (N) - 2 then
            I0 := Integer (N) - 2;
         end if;
         T := Coord - Float (I0);
      end if;
   end Cell_Origin;

   ---------------------------------------------------------------------------
   -- Evaluation sketches
   ---------------------------------------------------------------------------

   function Evaluate_Nearest_2D
     (G : Grid_2D; X, Y : Float) return Eval_Result
   is
      R      : Eval_Result;
      Ix, Iy : Natural;
   begin
      if not Is_Valid_Grid (G) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not In_Domain (G, X, Y) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Ix := Round_Index (X, G.Nx - 1);
      Iy := Round_Index (Y, G.Ny - 1);
      R.Value   := G.Values (Axis_Index (Ix), Axis_Index (Iy));
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Nearest_2D;

   function Evaluate_Bilinear
     (G : Grid_2D; X, Y : Float) return Eval_Result
   is
      R                  : Eval_Result;
      Ix, Iy             : Integer;
      Tx, Ty             : Float;
      F00, F10, F01, F11 : Float;
      C0, C1             : Float;
   begin
      if not Is_Valid_Grid (G) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not Large_Enough_Bilinear (G) then
         R.Stat := Too_Small_Grid;
         return R;
      end if;
      if not In_Domain (G, X, Y) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Cell_Origin (X, G.Nx, Ix, Tx);
      Cell_Origin (Y, G.Ny, Iy, Ty);

      F00 := Sample_2D (G, Ix,     Iy);
      F10 := Sample_2D (G, Ix + 1, Iy);
      F01 := Sample_2D (G, Ix,     Iy + 1);
      F11 := Sample_2D (G, Ix + 1, Iy + 1);

      C0 := Lerp (F00, F10, Tx);
      C1 := Lerp (F01, F11, Tx);
      R.Value   := Lerp (C0, C1, Ty);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Bilinear;

   function Evaluate_Bicubic
     (G : Grid_2D; X, Y : Float) return Eval_Result
   is
      R      : Eval_Result;
      Ix, Iy : Integer;
      Tx, Ty : Float;
      type Line is array (-1 .. 2) of Float;
      Inter_X : Line;
      Col     : Line;
   begin
      if not Is_Valid_Grid (G) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not Large_Enough_Bicubic (G) then
         R.Stat := Too_Small_Grid;
         return R;
      end if;
      if not In_Domain (G, X, Y) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Cell_Origin (X, G.Nx, Ix, Tx);
      Cell_Origin (Y, G.Ny, Iy, Ty);

      for DJ in -1 .. 2 loop
         Inter_X (DJ) :=
           Cubic_1D
             (Sample_2D (G, Ix - 1, Iy + DJ),
              Sample_2D (G, Ix,     Iy + DJ),
              Sample_2D (G, Ix + 1, Iy + DJ),
              Sample_2D (G, Ix + 2, Iy + DJ),
              Tx);
      end loop;

      for DJ in -1 .. 2 loop
         Col (DJ) := Inter_X (DJ);
      end loop;
      R.Value   := Cubic_1D (Col (-1), Col (0), Col (1), Col (2), Ty);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Bicubic;

   function Evaluate_Trilinear
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result
   is
      R                          : Eval_Result;
      Ix, Iy, Iz                 : Integer;
      Tx, Ty, Tz                 : Float;
      C000, C100, C010, C110     : Float;
      C001, C101, C011, C111     : Float;
      C00, C10, C01, C11         : Float;
      C0, C1                     : Float;
   begin
      if not Is_Valid_Grid (G) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not Large_Enough_Trilinear (G) then
         R.Stat := Too_Small_Grid;
         return R;
      end if;
      if not In_Domain (G, X, Y, Z) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Cell_Origin (X, G.Nx, Ix, Tx);
      Cell_Origin (Y, G.Ny, Iy, Ty);
      Cell_Origin (Z, G.Nz, Iz, Tz);

      C000 := Sample_3D (G, Ix,     Iy,     Iz);
      C100 := Sample_3D (G, Ix + 1, Iy,     Iz);
      C010 := Sample_3D (G, Ix,     Iy + 1, Iz);
      C110 := Sample_3D (G, Ix + 1, Iy + 1, Iz);
      C001 := Sample_3D (G, Ix,     Iy,     Iz + 1);
      C101 := Sample_3D (G, Ix + 1, Iy,     Iz + 1);
      C011 := Sample_3D (G, Ix,     Iy + 1, Iz + 1);
      C111 := Sample_3D (G, Ix + 1, Iy + 1, Iz + 1);

      C00 := Lerp (C000, C100, Tx);
      C10 := Lerp (C010, C110, Tx);
      C01 := Lerp (C001, C101, Tx);
      C11 := Lerp (C011, C111, Tx);
      C0  := Lerp (C00, C10, Ty);
      C1  := Lerp (C01, C11, Ty);

      R.Value   := Lerp (C0, C1, Tz);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Trilinear;

   function Evaluate_IDW
     (S : Scattered_2D; X, Y : Float; Power : Float := Default_IDW_Power)
      return Eval_Result
   is
      R          : Eval_Result;
      Dx, Dy, D  : Float;
      W          : Float;
      Sum_W      : Float := 0.0;
      Sum_WV     : Float := 0.0;
      Hit_Tol    : constant Float := 1.0E-12;
   begin
      if not Is_Valid_Scattered (S) then
         if S.Valid and then S.Count = 0 then
            R.Stat := Empty;
         else
            R.Stat := Ill_Started;
         end if;
         return R;
      end if;

      for I in 0 .. S.Count - 1 loop
         Dx := X - S.Sites (I).X;
         Dy := Y - S.Sites (I).Y;
         D  := Dx * Dx + Dy * Dy;
         if D <= Hit_Tol then
            R.Value   := S.Values (I);
            R.Stat    := Ok;
            R.Success := True;
            return R;
         end if;
         --  w = 1 / d^P with d = sqrt(Dx²+Dy²) ⇒ w = exp((-P/2) ln D)
         W := Ada.Numerics.Elementary_Functions.Exp
                ((-0.5 * Power)
                 * Ada.Numerics.Elementary_Functions.Log (D));
         Sum_W  := Sum_W + W;
         Sum_WV := Sum_WV + W * S.Values (I);
      end loop;

      if Sum_W <= 0.0 then
         R.Stat := Ill_Started;
         return R;
      end if;

      R.Value   := Sum_WV / Sum_W;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_IDW;

   function Evaluate
     (Kind : Method_Kind;
      G    : Grid_2D;
      X, Y : Float) return Eval_Result
   is
      R : Eval_Result;
   begin
      case Kind is
         when Nearest_Neighbor =>
            return Evaluate_Nearest_2D (G, X, Y);
         when Bilinear =>
            return Evaluate_Bilinear (G, X, Y);
         when Bicubic =>
            return Evaluate_Bicubic (G, X, Y);
         when others =>
            R.Stat := Not_Implemented;
            return R;
      end case;
   end Evaluate;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty_2D (Nx, Ny : Axis_Size) return Grid_2D is
      G : Grid_2D;
   begin
      G.Nx    := Nx;
      G.Ny    := Ny;
      G.Valid := True;
      return G;
   end Make_Empty_2D;

   function Make_Empty_3D (Nx, Ny, Nz : Axis_Size) return Grid_3D is
      G : Grid_3D;
   begin
      G.Nx    := Nx;
      G.Ny    := Ny;
      G.Nz    := Nz;
      G.Valid := True;
      return G;
   end Make_Empty_3D;

   function Make_Constant_2D
     (Nx, Ny : Axis_Size; C : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty_2D (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            G.Values (I, J) := C;
         end loop;
      end loop;
      return G;
   end Make_Constant_2D;

   function Make_Constant_3D
     (Nx, Ny, Nz : Axis_Size; C : Float) return Grid_3D
   is
      G : Grid_3D := Make_Empty_3D (Nx, Ny, Nz);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            for K in 0 .. Nz - 1 loop
               G.Values (I, J, K) := C;
            end loop;
         end loop;
      end loop;
      return G;
   end Make_Constant_3D;

   function Make_Affine_2D
     (Nx, Ny : Axis_Size; A, B, C : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty_2D (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            G.Values (I, J) := A * Float (I) + B * Float (J) + C;
         end loop;
      end loop;
      return G;
   end Make_Affine_2D;

   function Make_Affine_3D
     (Nx, Ny, Nz : Axis_Size; A, B, C, D : Float) return Grid_3D
   is
      G : Grid_3D := Make_Empty_3D (Nx, Ny, Nz);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            for K in 0 .. Nz - 1 loop
               G.Values (I, J, K) :=
                 A * Float (I) + B * Float (J) + C * Float (K) + D;
            end loop;
         end loop;
      end loop;
      return G;
   end Make_Affine_3D;

   function Make_Checkerboard_2D
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty_2D (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            if (I + J) rem 2 = 0 then
               G.Values (I, J) := Hi;
            else
               G.Values (I, J) := Lo;
            end if;
         end loop;
      end loop;
      return G;
   end Make_Checkerboard_2D;

   function Make_Example (Kind : Example_Kind) return Grid_2D is
   begin
      case Kind is
         when Constant_Field =>
            return Make_Constant_2D (5, 5, 7.0);
         when Affine_Field =>
            return Make_Affine_2D (6, 6, 1.0, 2.0, 1.0);
         when Checkerboard =>
            return Make_Checkerboard_2D (4, 4, 0.0, 1.0);
      end case;
   end Make_Example;

   function Make_Empty_Scattered (Count : Site_Count) return Scattered_2D is
      S : Scattered_2D;
   begin
      S.Count := Count;
      S.Valid := True;
      return S;
   end Make_Empty_Scattered;

   function Make_Unit_Square_Cloud
     (F00, F10, F01, F11 : Float) return Scattered_2D
   is
      S : Scattered_2D := Make_Empty_Scattered (4);
   begin
      S.Sites (0) := (X => 0.0, Y => 0.0); S.Values (0) := F00;
      S.Sites (1) := (X => 1.0, Y => 0.0); S.Values (1) := F10;
      S.Sites (2) := (X => 0.0, Y => 1.0); S.Values (2) := F01;
      S.Sites (3) := (X => 1.0, Y => 1.0); S.Values (3) := F11;
      return S;
   end Make_Unit_Square_Cloud;

   function Make_Scattered_From_Grid (G : Grid_2D) return Scattered_2D is
      S : Scattered_2D;
      K : Natural := 0;
   begin
      S.Count := Site_Count (Natural (G.Nx) * Natural (G.Ny));
      S.Valid := True;
      for I in 0 .. G.Nx - 1 loop
         for J in 0 .. G.Ny - 1 loop
            S.Sites (Site_Index (K)) :=
              (X => Float (I), Y => Float (J));
            S.Values (Site_Index (K)) := G.Values (I, J);
            K := K + 1;
         end loop;
      end loop;
      return S;
   end Make_Scattered_From_Grid;

end Multivariate_Interpolation;
