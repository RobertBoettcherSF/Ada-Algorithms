--  Tricubic_Interpolation body — tensor-product Catmull–Rom + trilinear.

pragma Ada_2022;

package body Tricubic_Interpolation
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

   function Is_Valid_Grid (G : Grid_3D) return Boolean is
   begin
      --  Axis_Size already caps at Max_N; require a non-empty lattice.
      return G.Valid
        and then G.Nx >= 1
        and then G.Ny >= 1
        and then G.Nz >= 1;
   end Is_Valid_Grid;

   function In_Domain (G : Grid_3D; X, Y, Z : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (G.Ny - 1)
        and then Z >= 0.0 and then Z <= Float (G.Nz - 1);
   end In_Domain;

   function Large_Enough_Trilinear (G : Grid_3D) return Boolean is
   begin
      return Is_Valid_Grid (G)
        and then G.Nx >= 2
        and then G.Ny >= 2
        and then G.Nz >= 2;
   end Large_Enough_Trilinear;

   function Large_Enough_Tricubic (G : Grid_3D) return Boolean is
   begin
      return Is_Valid_Grid (G)
        and then G.Nx >= 4
        and then G.Ny >= 4
        and then G.Nz >= 4;
   end Large_Enough_Tricubic;

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

   --  Odd (value) reflection outside the lattice so affine fields
   --  f = a + bx + cy + dz stay exact: Sample(-1,*) = 2 V(0,*) − V(1,*),
   --  Sample(N,*) = 2 V(N−1,*) − V(N−2,*), and likewise for y,z.
   function Sample
     (G : Grid_3D; I, J, K : Integer) return Float
     with Pre => Is_Valid_Grid (G)
   is
      Last_X : constant Integer := Integer (G.Nx) - 1;
      Last_Y : constant Integer := Integer (G.Ny) - 1;
      Last_Z : constant Integer := Integer (G.Nz) - 1;
   begin
      if I < 0 then
         return 2.0 * Sample (G, 0, J, K) - Sample (G, -I, J, K);
      elsif I > Last_X then
         return 2.0 * Sample (G, Last_X, J, K)
           - Sample (G, 2 * Last_X - I, J, K);
      elsif J < 0 then
         return 2.0 * Sample (G, I, 0, K) - Sample (G, I, -J, K);
      elsif J > Last_Y then
         return 2.0 * Sample (G, I, Last_Y, K)
           - Sample (G, I, 2 * Last_Y - J, K);
      elsif K < 0 then
         return 2.0 * Sample (G, I, J, 0) - Sample (G, I, J, -K);
      elsif K > Last_Z then
         return 2.0 * Sample (G, I, J, Last_Z)
           - Sample (G, I, J, 2 * Last_Z - K);
      else
         return G.Values
           (Axis_Index (I), Axis_Index (J), Axis_Index (K));
      end if;
   end Sample;

   --  Uniform Catmull–Rom cubic Hermite on four consecutive samples.
   --  t ∈ [0,1] between P1 and P2 (indices −1,0,1,2 → P0..P3 in CR naming).
   function Catmull_Rom
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
   end Catmull_Rom;

   --  Cell origin (floor) with right-endpoint clamping so X = Nx−1 uses
   --  the last cell [Nx−2, Nx−1].
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
   -- Evaluation
   ---------------------------------------------------------------------------

   function Evaluate_Trilinear
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result
   is
      R              : Eval_Result;
      Ix, Iy, Iz     : Integer;
      Tx, Ty, Tz     : Float;
      C000, C100, C010, C110 : Float;
      C001, C101, C011, C111 : Float;
      C00, C10, C01, C11     : Float;
      C0, C1                 : Float;
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

      C000 := Sample (G, Ix,     Iy,     Iz);
      C100 := Sample (G, Ix + 1, Iy,     Iz);
      C010 := Sample (G, Ix,     Iy + 1, Iz);
      C110 := Sample (G, Ix + 1, Iy + 1, Iz);
      C001 := Sample (G, Ix,     Iy,     Iz + 1);
      C101 := Sample (G, Ix + 1, Iy,     Iz + 1);
      C011 := Sample (G, Ix,     Iy + 1, Iz + 1);
      C111 := Sample (G, Ix + 1, Iy + 1, Iz + 1);

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

   function Evaluate_Tricubic
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result
   is
      R          : Eval_Result;
      Ix, Iy, Iz : Integer;
      Tx, Ty, Tz : Float;
      --  After x-pass: Inter_X (DJ, DK) for DJ,DK in -1..2
      type Face is array (-1 .. 2, -1 .. 2) of Float;
      Inter_X : Face;
      --  After y-pass: Inter_Y (DK) for DK in -1..2
      type Line is array (-1 .. 2) of Float;
      Inter_Y : Line;
      Col     : Line;
   begin
      if not Is_Valid_Grid (G) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not Large_Enough_Tricubic (G) then
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

      --  1-D Catmull–Rom along x for each (j,k) in the 4×4 neighbourhood.
      for DJ in -1 .. 2 loop
         for DK in -1 .. 2 loop
            Inter_X (DJ, DK) :=
              Catmull_Rom
                (Sample (G, Ix - 1, Iy + DJ, Iz + DK),
                 Sample (G, Ix,     Iy + DJ, Iz + DK),
                 Sample (G, Ix + 1, Iy + DJ, Iz + DK),
                 Sample (G, Ix + 2, Iy + DJ, Iz + DK),
                 Tx);
         end loop;
      end loop;

      --  Along y for each k.
      for DK in -1 .. 2 loop
         Inter_Y (DK) :=
           Catmull_Rom
             (Inter_X (-1, DK),
              Inter_X (0,  DK),
              Inter_X (1,  DK),
              Inter_X (2,  DK),
              Ty);
      end loop;

      --  Along z.
      for DK in -1 .. 2 loop
         Col (DK) := Inter_Y (DK);
      end loop;
      R.Value   := Catmull_Rom (Col (-1), Col (0), Col (1), Col (2), Tz);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Tricubic;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty (Nx, Ny, Nz : Axis_Size) return Grid_3D is
      G : Grid_3D;
   begin
      G.Nx    := Nx;
      G.Ny    := Ny;
      G.Nz    := Nz;
      G.Valid := True;
      G.Values := [others => [others => [others => 0.0]]];
      return G;
   end Make_Empty;

   function Make_Constant_Field
     (Nx, Ny, Nz : Axis_Size; C : Float) return Grid_3D
   is
      G : Grid_3D := Make_Empty (Nx, Ny, Nz);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            for K in 0 .. Nz - 1 loop
               G.Values (I, J, K) := C;
            end loop;
         end loop;
      end loop;
      return G;
   end Make_Constant_Field;

   function Make_Linear_Field
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
   is
      G : Grid_3D := Make_Empty (Nx, Ny, Nz);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            for K in 0 .. Nz - 1 loop
               G.Values (I, J, K) :=
                 Float (I) + 2.0 * Float (J) + 3.0 * Float (K);
            end loop;
         end loop;
      end loop;
      return G;
   end Make_Linear_Field;

   function Make_Separable_Quadratic
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
   is
      G : Grid_3D := Make_Empty (Nx, Ny, Nz);
      FI, FJ, FK : Float;
   begin
      for I in 0 .. Nx - 1 loop
         FI := Float (I);
         for J in 0 .. Ny - 1 loop
            FJ := Float (J);
            for K in 0 .. Nz - 1 loop
               FK := Float (K);
               G.Values (I, J, K) := FI * FI + FJ * FJ + FK * FK;
            end loop;
         end loop;
      end loop;
      return G;
   end Make_Separable_Quadratic;

   function Make_Separable_Cubic
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
   is
      G : Grid_3D := Make_Empty (Nx, Ny, Nz);
      FI, FJ, FK : Float;
   begin
      for I in 0 .. Nx - 1 loop
         FI := Float (I);
         for J in 0 .. Ny - 1 loop
            FJ := Float (J);
            for K in 0 .. Nz - 1 loop
               FK := Float (K);
               G.Values (I, J, K) :=
                 FI * FI * FI + FJ * FJ * FJ + FK * FK * FK;
            end loop;
         end loop;
      end loop;
      return G;
   end Make_Separable_Cubic;

   function Make_Example (Kind : Example_Kind) return Grid_3D is
   begin
      case Kind is
         when Constant_Field =>
            return Make_Constant_Field (5, 5, 5, 7.0);
         when Linear_Field =>
            return Make_Linear_Field (6, 6, 6);
         when Separable_Quadratic =>
            return Make_Separable_Quadratic (5, 5, 5);
         when Separable_Cubic =>
            return Make_Separable_Cubic (5, 5, 5);
      end case;
   end Make_Example;

end Tricubic_Interpolation;
