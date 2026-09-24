--  Bilinear_Interpolation body — linear 1-D + bilinear 2-D + resize.

pragma Ada_2022;

package body Bilinear_Interpolation
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

   function Is_Valid_Grid (G : Grid_1D) return Boolean is
   begin
      return G.Valid and then G.N >= 1;
   end Is_Valid_Grid;

   function Is_Valid_Grid (G : Grid_2D) return Boolean is
   begin
      return G.Valid and then G.Nx >= 1 and then G.Ny >= 1;
   end Is_Valid_Grid;

   function Large_Enough_Linear (G : Grid_1D) return Boolean is
   begin
      return Is_Valid_Grid (G) and then G.N >= 2;
   end Large_Enough_Linear;

   function Large_Enough_Bilinear (G : Grid_2D) return Boolean is
   begin
      return Is_Valid_Grid (G)
        and then G.Nx >= 2
        and then G.Ny >= 2;
   end Large_Enough_Bilinear;

   function In_Domain (G : Grid_1D; X : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.N - 1);
   end In_Domain;

   function In_Domain (G : Grid_2D; X, Y : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (G.Ny - 1);
   end In_Domain;

   function Get (G : Grid_1D; I : Axis_Index) return Float is
   begin
      return G.Values (I);
   end Get;

   procedure Set
     (G : in out Grid_1D; I : Axis_Index; Value : Float)
   is
   begin
      G.Values (I) := Value;
   end Set;

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

   function Evaluate_Linear_1D (G : Grid_1D; X : Float) return Eval_Result is
      R  : Eval_Result;
      I0 : Integer;
      T  : Float;
   begin
      if not Is_Valid_Grid (G) then
         R.Stat := Ill_Started;
         return R;
      end if;
      if not Large_Enough_Linear (G) then
         R.Stat := Too_Small_Grid;
         return R;
      end if;
      if not In_Domain (G, X) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;

      Cell_Origin (X, G.N, I0, T);
      R.Value   := Lerp (G.Values (Axis_Index (I0)),
                         G.Values (Axis_Index (I0 + 1)),
                         T);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Linear_1D;

   function Evaluate_Unit_Square
     (F00, F10, F01, F11 : Float; T, U : Float) return Float
   is
   begin
      --  (1−t)(1−u) F00 + t(1−u) F10 + (1−t)u F01 + t u F11
      return (1.0 - T) * (1.0 - U) * F00
        + T * (1.0 - U) * F10
        + (1.0 - T) * U * F01
        + T * U * F11;
   end Evaluate_Unit_Square;

   function Evaluate (G : Grid_2D; X, Y : Float) return Eval_Result is
      R          : Eval_Result;
      Ix, Iy     : Integer;
      Tx, Ty     : Float;
      F00, F10, F01, F11 : Float;
      C0, C1     : Float;
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

      F00 := G.Values (Axis_Index (Ix),     Axis_Index (Iy));
      F10 := G.Values (Axis_Index (Ix + 1), Axis_Index (Iy));
      F01 := G.Values (Axis_Index (Ix),     Axis_Index (Iy + 1));
      F11 := G.Values (Axis_Index (Ix + 1), Axis_Index (Iy + 1));

      --  Lerp in x, then in y (equivalent to Evaluate_Unit_Square).
      C0 := Lerp (F00, F10, Tx);
      C1 := Lerp (F01, F11, Tx);
      R.Value   := Lerp (C0, C1, Ty);
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate;

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
      R : Resize_2D_Result;
      ER : Eval_Result;
      X, Y : Float;
   begin
      if not G.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if G.Nx < 2 or else G.Ny < 2 then
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

      R.Grid := Make_Empty_2D (Axis_Size (New_Nx), Axis_Size (New_Ny));
      for J in 0 .. Integer (New_Ny) - 1 loop
         Y := Source_Coord (Natural (J), New_Ny, G.Ny);
         for I in 0 .. Integer (New_Nx) - 1 loop
            X := Source_Coord (Natural (I), New_Nx, G.Nx);
            ER := Evaluate (G, X, Y);
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

   function Make_Empty_1D (N : Axis_Size) return Grid_1D is
      G : Grid_1D;
   begin
      G.N      := N;
      G.Valid  := True;
      G.Values := [others => 0.0];
      return G;
   end Make_Empty_1D;

   function Make_Empty_2D (Nx, Ny : Axis_Size) return Grid_2D is
      G : Grid_2D;
   begin
      G.Nx     := Nx;
      G.Ny     := Ny;
      G.Valid  := True;
      G.Values := [others => [others => 0.0]];
      return G;
   end Make_Empty_2D;

   function Make_Constant_1D
     (N : Axis_Size; C : Float) return Grid_1D
   is
      G : Grid_1D := Make_Empty_1D (N);
   begin
      for I in 0 .. N - 1 loop
         G.Values (I) := C;
      end loop;
      return G;
   end Make_Constant_1D;

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

   function Make_Linear_1D
     (N : Axis_Size; Y0, Y1 : Float) return Grid_1D
   is
      G : Grid_1D := Make_Empty_1D (N);
      T : Float;
   begin
      if N = 1 then
         G.Values (0) := Y0;
         return G;
      end if;
      for I in 0 .. N - 1 loop
         T := Float (I) / Float (N - 1);
         G.Values (I) := Lerp (Y0, Y1, T);
      end loop;
      return G;
   end Make_Linear_1D;

   function Make_Linear_2D
     (Nx, Ny : Axis_Size; A, B, C : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty_2D (Nx, Ny);
   begin
      for I in 0 .. Nx - 1 loop
         for J in 0 .. Ny - 1 loop
            G.Values (I, J) :=
              A * Float (I) + B * Float (J) + C;
         end loop;
      end loop;
      return G;
   end Make_Linear_2D;

   function Make_Checkerboard_2D
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty_2D (Nx, Ny);
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
   end Make_Checkerboard_2D;

   function Make_Ramp_2D
     (Nx, Ny : Axis_Size) return Grid_2D
   is
   begin
      return Make_Linear_2D (Nx, Ny, 1.0, 2.0, 0.0);
   end Make_Ramp_2D;

   function Make_Example (Kind : Example_Kind) return Grid_2D is
   begin
      case Kind is
         when Constant_Field =>
            return Make_Constant_2D (5, 5, 7.0);
         when Linear_Field =>
            return Make_Linear_2D (6, 6, 1.0, 2.0, 1.0);
         when Checkerboard =>
            return Make_Checkerboard_2D (4, 4, 0.0, 1.0);
         when Ramp =>
            return Make_Ramp_2D (5, 5);
      end case;
   end Make_Example;

end Bilinear_Interpolation;
