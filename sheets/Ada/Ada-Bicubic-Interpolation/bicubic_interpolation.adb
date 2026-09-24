--  Bicubic_Interpolation body — tensor-product Catmull–Rom / Keys + bilinear.

pragma Ada_2022;

package body Bicubic_Interpolation
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

   --  Uniform Catmull–Rom cubic Hermite ≡ Keys cubic convolution with a=−1/2.
   --  t ∈ [0,1] between P1 and P2 (indices −1,0,1,2 → P0..P3 in CR naming).
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

   function Is_Valid_Grid (G : Grid_2D) return Boolean is
   begin
      return G.Valid and then G.Nx >= 1 and then G.Ny >= 1;
   end Is_Valid_Grid;

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (G.Ny - 1);
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

   function Get (G : Grid_2D; I, J : Axis_Index) return Float is
   begin
      return G.Values (I, J);
   end Get;

   procedure Set
     (G     : in out Grid_2D;
      I, J  : Axis_Index;
      Value : Float)
   is
   begin
      G.Values (I, J) := Value;
   end Set;

   --  Odd (value) reflection outside the lattice so affine fields
   --  f = a + bx + cy stay exact: Sample(-1,*) = 2 V(0,*) − V(1,*),
   --  Sample(N,*) = 2 V(N−1,*) − V(N−2,*), and likewise for y.
   function Sample
     (G : Grid_2D; I, J : Integer) return Float
     with Pre => Is_Valid_Grid (G)
   is
      Last_X : constant Integer := Integer (G.Nx) - 1;
      Last_Y : constant Integer := Integer (G.Ny) - 1;
   begin
      if I < 0 then
         return 2.0 * Sample (G, 0, J) - Sample (G, -I, J);
      elsif I > Last_X then
         return 2.0 * Sample (G, Last_X, J)
           - Sample (G, 2 * Last_X - I, J);
      elsif J < 0 then
         return 2.0 * Sample (G, I, 0) - Sample (G, I, -J);
      elsif J > Last_Y then
         return 2.0 * Sample (G, I, Last_Y)
           - Sample (G, I, 2 * Last_Y - J);
      else
         return G.Values (Axis_Index (I), Axis_Index (J));
      end if;
   end Sample;

   --  Cell origin (floor) with right-endpoint clamping so X = N−1 uses
   --  the last cell [N−2, N−1].
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

   function Evaluate_Bilinear
     (G : Grid_2D; X, Y : Float) return Eval_Result
   is
      R              : Eval_Result;
      Ix, Iy         : Integer;
      Tx, Ty         : Float;
      F00, F10, F01, F11 : Float;
      C0, C1         : Float;
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

      F00 := Sample (G, Ix,     Iy);
      F10 := Sample (G, Ix + 1, Iy);
      F01 := Sample (G, Ix,     Iy + 1);
      F11 := Sample (G, Ix + 1, Iy + 1);

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
      --  After x-pass: Inter_X (DJ) for DJ in -1..2
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

      --  1-D Catmull–Rom / Keys along x for each j in the 4-neighbourhood.
      for DJ in -1 .. 2 loop
         Inter_X (DJ) :=
           Cubic_1D
             (Sample (G, Ix - 1, Iy + DJ),
              Sample (G, Ix,     Iy + DJ),
              Sample (G, Ix + 1, Iy + DJ),
              Sample (G, Ix + 2, Iy + DJ),
              Tx);
      end loop;

      --  Along y.
      for DJ in -1 .. 2 loop
         Col (DJ) := Inter_X (DJ);
      end loop;
      R.Value   := Cubic_1D (Col (-1), Col (0), Col (1), Col (2), Ty);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Bicubic;

   ---------------------------------------------------------------------------
   -- Resize
   ---------------------------------------------------------------------------

   function Source_Coord
     (Out_Index : Natural; Out_N : Natural; Src_N : Axis_Size) return Float
     with Pre => Out_N >= 1 and then Src_N >= 1
   is
   begin
      if Out_N = 1 then
         return 0.0;
      end if;
      return Float (Out_Index) * Float (Src_N - 1) / Float (Out_N - 1);
   end Source_Coord;

   function Resize_2D
     (G      : Grid_2D;
      New_Nx : Natural;
      New_Ny : Natural) return Resize_2D_Result
   is
      R  : Resize_2D_Result;
      ER : Eval_Result;
      X, Y : Float;
   begin
      if not G.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if G.Nx < 4 or else G.Ny < 4 then
         R.Stat := Too_Small_Grid;
         return R;
      end if;
      if New_Nx = 0 or else New_Ny = 0 then
         R.Stat := Too_Small_Grid;
         return R;
      end if;
      if New_Nx > Max_N or else New_Ny > Max_N then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      R.Grid := Make_Empty (Axis_Size (New_Nx), Axis_Size (New_Ny));
      for J in 0 .. Integer (New_Ny) - 1 loop
         Y := Source_Coord (Natural (J), New_Ny, G.Ny);
         for I in 0 .. Integer (New_Nx) - 1 loop
            X := Source_Coord (Natural (I), New_Nx, G.Nx);
            ER := Evaluate_Bicubic (G, X, Y);
            if not ER.Success then
               R.Stat := ER.Stat;
               R.Grid.Valid := False;
               return R;
            end if;
            R.Grid.Values (Axis_Index (I), Axis_Index (J)) := ER.Value;
         end loop;
      end loop;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Resize_2D;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty (Nx, Ny : Axis_Size) return Grid_2D is
      G : Grid_2D;
   begin
      G.Nx     := Nx;
      G.Ny     := Ny;
      G.Valid  := True;
      G.Values := [others => [others => 0.0]];
      return G;
   end Make_Empty;

   function Make_Constant_Field
     (Nx, Ny : Axis_Size; C : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            G.Values (I, J) := C;
         end loop;
      end loop;
      return G;
   end Make_Constant_Field;

   function Make_Affine_Field
     (Nx, Ny : Axis_Size; A, B, C : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            G.Values (I, J) := A * Float (I) + B * Float (J) + C;
         end loop;
      end loop;
      return G;
   end Make_Affine_Field;

   function Make_Checkerboard
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            if (I + J) mod 2 = 0 then
               G.Values (I, J) := Hi;
            else
               G.Values (I, J) := Lo;
            end if;
         end loop;
      end loop;
      return G;
   end Make_Checkerboard;

   function Make_Separable_Quadratic
     (Nx, Ny : Axis_Size) return Grid_2D
   is
      G : Grid_2D := Make_Empty (Nx, Ny);
      FI, FJ : Float;
   begin
      for I in 0 .. Nx - 1 loop
         FI := Float (I);
         for J in 0 .. Ny - 1 loop
            FJ := Float (J);
            G.Values (I, J) := FI * FI + FJ * FJ;
         end loop;
      end loop;
      return G;
   end Make_Separable_Quadratic;

   function Make_Separable_Cubic
     (Nx, Ny : Axis_Size) return Grid_2D
   is
      G : Grid_2D := Make_Empty (Nx, Ny);
      FI, FJ : Float;
   begin
      for I in 0 .. Nx - 1 loop
         FI := Float (I);
         for J in 0 .. Ny - 1 loop
            FJ := Float (J);
            G.Values (I, J) := FI * FI * FI + FJ * FJ * FJ;
         end loop;
      end loop;
      return G;
   end Make_Separable_Cubic;

   function Make_Example (Kind : Example_Kind) return Grid_2D is
   begin
      case Kind is
         when Constant_Field =>
            return Make_Constant_Field (5, 5, 7.0);
         when Affine_Field =>
            return Make_Affine_Field (6, 6, 1.0, 2.0, 1.0);
         when Checkerboard =>
            return Make_Checkerboard (4, 4, 0.0, 1.0);
         when Separable_Cubic =>
            return Make_Separable_Cubic (5, 5);
      end case;
   end Make_Example;

end Bicubic_Interpolation;
