--  Nearest_Neighbor_Interpolation body — scattered NN + grid round-to-nearest.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

package body Nearest_Neighbor_Interpolation
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near (A, B : Site_1D; Tol : Float := Near_Tol) return Boolean is
   begin
      return Near (A.X, B.X, Tol);
   end Near;

   function Near (A, B : Site_2D; Tol : Float := Near_Tol) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near;

   function Dist
     (A, B : Site_1D; Kind : Distance_Kind := Euclidean) return Float
   is
      D : constant Float := abs (A.X - B.X);
   begin
      --  1-D Euclidean and Manhattan coincide; Kind kept for API symmetry.
      case Kind is
         when Euclidean | Manhattan =>
            return D;
      end case;
   end Dist;

   function Dist
     (A, B : Site_2D; Kind : Distance_Kind := Euclidean) return Float
   is
      DX : constant Float := abs (A.X - B.X);
      DY : constant Float := abs (A.Y - B.Y);
   begin
      case Kind is
         when Euclidean =>
            return Math.Sqrt (DX * DX + DY * DY);
         when Manhattan =>
            return DX + DY;
      end case;
   end Dist;

   function Dist
     (A, B : Site_3D; Kind : Distance_Kind := Euclidean) return Float
   is
      DX : constant Float := abs (A.X - B.X);
      DY : constant Float := abs (A.Y - B.Y);
      DZ : constant Float := abs (A.Z - B.Z);
   begin
      case Kind is
         when Euclidean =>
            return Math.Sqrt (DX * DX + DY * DY + DZ * DZ);
         when Manhattan =>
            return DX + DY + DZ;
      end case;
   end Dist;

   function Make_Site_1D (X : Float) return Site_1D is
   begin
      return (X => X);
   end Make_Site_1D;

   function Make_Site_2D (X, Y : Float) return Site_2D is
   begin
      return (X => X, Y => Y);
   end Make_Site_2D;

   function Make_Site_3D (X, Y, Z : Float) return Site_3D is
   begin
      return (X => X, Y => Y, Z => Z);
   end Make_Site_3D;

   ---------------------------------------------------------------------------
   -- Round_Index: ties (exact *.5) → lower index
   ---------------------------------------------------------------------------

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
         --  Frac < 0.5 → floor; Frac = 0.5 → lower index (tie-break)
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
   -- Validation / domain
   ---------------------------------------------------------------------------

   function Is_Valid_Scattered (S : Scattered_1D) return Boolean is
   begin
      --  Site_Count already caps at Max_Sites; require a non-empty cloud.
      return S.Valid and then S.Count >= 1;
   end Is_Valid_Scattered;

   function Is_Valid_Scattered (S : Scattered_2D) return Boolean is
   begin
      return S.Valid and then S.Count >= 1;
   end Is_Valid_Scattered;

   function Is_Valid_Grid (G : Grid_1D) return Boolean is
   begin
      --  Axis_Size already caps at Max_N; require a non-empty lattice.
      return G.Valid and then G.N >= 1;
   end Is_Valid_Grid;

   function Is_Valid_Grid (G : Grid_2D) return Boolean is
   begin
      return G.Valid and then G.Nx >= 1 and then G.Ny >= 1;
   end Is_Valid_Grid;

   function Is_Valid_Grid (G : Grid_3D) return Boolean is
   begin
      return G.Valid
        and then G.Nx >= 1 and then G.Ny >= 1 and then G.Nz >= 1;
   end Is_Valid_Grid;

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

   function In_Domain (G : Grid_3D; X, Y, Z : Float) return Boolean is
   begin
      if not Is_Valid_Grid (G) then
         return False;
      end if;
      return X >= 0.0 and then X <= Float (G.Nx - 1)
        and then Y >= 0.0 and then Y <= Float (G.Ny - 1)
        and then Z >= 0.0 and then Z <= Float (G.Nz - 1);
   end In_Domain;

   ---------------------------------------------------------------------------
   -- Nearest_Index (brute-force; ties → lowest index)
   ---------------------------------------------------------------------------

   function Nearest_Index
     (S    : Scattered_1D;
      Q    : Site_1D;
      Kind : Distance_Kind := Euclidean) return Nearest_Result
   is
      R        : Nearest_Result;
      Best_D   : Float;
      Candidate : Float;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if S.Count = 0 then
         R.Stat := Empty;
         return R;
      end if;
      Best_D := Dist (Q, S.Sites (0), Kind);
      R.Index := 0;
      R.Dist  := Best_D;
      for I in 1 .. S.Count - 1 loop
         Candidate := Dist (Q, S.Sites (I), Kind);
         --  Strict < keeps earlier (lower) index on ties.
         if Candidate < Best_D then
            Best_D  := Candidate;
            R.Index := I;
            R.Dist  := Best_D;
         end if;
      end loop;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Nearest_Index;

   function Nearest_Index
     (S    : Scattered_2D;
      Q    : Site_2D;
      Kind : Distance_Kind := Euclidean) return Nearest_Result
   is
      R         : Nearest_Result;
      Best_D    : Float;
      Candidate : Float;
   begin
      if not S.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if S.Count = 0 then
         R.Stat := Empty;
         return R;
      end if;
      Best_D := Dist (Q, S.Sites (0), Kind);
      R.Index := 0;
      R.Dist  := Best_D;
      for I in 1 .. S.Count - 1 loop
         Candidate := Dist (Q, S.Sites (I), Kind);
         if Candidate < Best_D then
            Best_D  := Candidate;
            R.Index := I;
            R.Dist  := Best_D;
         end if;
      end loop;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Nearest_Index;

   ---------------------------------------------------------------------------
   -- Evaluate_Scattered
   ---------------------------------------------------------------------------

   function Evaluate_Scattered
     (S    : Scattered_1D;
      X    : Float;
      Kind : Distance_Kind := Euclidean) return Eval_Result
   is
      N : constant Nearest_Result :=
        Nearest_Index (S, Make_Site_1D (X), Kind);
      R : Eval_Result;
   begin
      R.Stat := N.Stat;
      if not N.Success then
         return R;
      end if;
      R.Value   := S.Values (N.Index);
      R.Index   := N.Index;
      R.I       := N.Index;
      R.Dist    := N.Dist;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Scattered;

   function Evaluate_Scattered
     (S    : Scattered_2D;
      X, Y : Float;
      Kind : Distance_Kind := Euclidean) return Eval_Result
   is
      N : constant Nearest_Result :=
        Nearest_Index (S, Make_Site_2D (X, Y), Kind);
      R : Eval_Result;
   begin
      R.Stat := N.Stat;
      if not N.Success then
         return R;
      end if;
      R.Value   := S.Values (N.Index);
      R.Index   := N.Index;
      R.I       := N.Index;
      R.Dist    := N.Dist;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Scattered;

   ---------------------------------------------------------------------------
   -- Evaluate_Grid_*
   ---------------------------------------------------------------------------

   function Evaluate_Grid_1D (G : Grid_1D; X : Float) return Eval_Result is
      R   : Eval_Result;
      Idx : Natural;
   begin
      if not G.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if G.N = 0 then
         R.Stat := Empty;
         return R;
      end if;
      if not In_Domain (G, X) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;
      Idx := Round_Index (X, G.N - 1);
      R.Value   := G.Values (Idx);
      R.Index   := Idx;
      R.I       := Idx;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Grid_1D;

   function Evaluate_Grid_2D
     (G : Grid_2D; X, Y : Float) return Eval_Result
   is
      R      : Eval_Result;
      Ix, Iy : Natural;
   begin
      if not G.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if G.Nx = 0 or else G.Ny = 0 then
         R.Stat := Empty;
         return R;
      end if;
      if not In_Domain (G, X, Y) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;
      Ix := Round_Index (X, G.Nx - 1);
      Iy := Round_Index (Y, G.Ny - 1);
      R.Value   := G.Values (Ix, Iy);
      R.Index   := Ix * G.Ny + Iy;  -- row-major flatten
      R.I       := Ix;
      R.J       := Iy;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Grid_2D;

   function Evaluate_Grid_3D
     (G : Grid_3D; X, Y, Z : Float) return Eval_Result
   is
      R          : Eval_Result;
      Ix, Iy, Iz : Natural;
   begin
      if not G.Valid then
         R.Stat := Ill_Started;
         return R;
      end if;
      if G.Nx = 0 or else G.Ny = 0 or else G.Nz = 0 then
         R.Stat := Empty;
         return R;
      end if;
      if not In_Domain (G, X, Y, Z) then
         R.Stat := Out_Of_Domain;
         return R;
      end if;
      Ix := Round_Index (X, G.Nx - 1);
      Iy := Round_Index (Y, G.Ny - 1);
      Iz := Round_Index (Z, G.Nz - 1);
      R.Value   := G.Values (Ix, Iy, Iz);
      R.Index   := (Ix * G.Ny + Iy) * G.Nz + Iz;
      R.I       := Ix;
      R.J       := Iy;
      R.K       := Iz;
      R.Stat    := Ok;
      R.Success := True;
      return R;
   end Evaluate_Grid_3D;

   ---------------------------------------------------------------------------
   -- Get / Set
   ---------------------------------------------------------------------------

   function Get (G : Grid_1D; I : Axis_Index) return Float is
   begin
      return G.Values (I);
   end Get;

   function Get (G : Grid_2D; I, J : Axis_Index) return Float is
   begin
      return G.Values (I, J);
   end Get;

   function Get (G : Grid_3D; I, J, K : Axis_Index) return Float is
   begin
      return G.Values (I, J, K);
   end Get;

   procedure Set
     (G : in out Grid_1D; I : Axis_Index; Value : Float)
   is
   begin
      G.Values (I) := Value;
   end Set;

   procedure Set
     (G : in out Grid_2D; I, J : Axis_Index; Value : Float)
   is
   begin
      G.Values (I, J) := Value;
   end Set;

   procedure Set
     (G : in out Grid_3D; I, J, K : Axis_Index; Value : Float)
   is
   begin
      G.Values (I, J, K) := Value;
   end Set;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Empty_Scattered_1D return Scattered_1D is
      S : Scattered_1D;
   begin
      S.Count := 0;
      S.Valid := False;
      return S;
   end Make_Empty_Scattered_1D;

   function Make_Empty_Scattered_2D return Scattered_2D is
      S : Scattered_2D;
   begin
      S.Count := 0;
      S.Valid := False;
      return S;
   end Make_Empty_Scattered_2D;

   function Make_Empty_Grid_1D (N : Axis_Size) return Grid_1D is
      G : Grid_1D;
   begin
      G.N     := N;
      G.Valid := True;
      return G;
   end Make_Empty_Grid_1D;

   function Make_Empty_Grid_2D (Nx, Ny : Axis_Size) return Grid_2D is
      G : Grid_2D;
   begin
      G.Nx    := Nx;
      G.Ny    := Ny;
      G.Valid := True;
      return G;
   end Make_Empty_Grid_2D;

   function Make_Empty_Grid_3D (Nx, Ny, Nz : Axis_Size) return Grid_3D is
      G : Grid_3D;
   begin
      G.Nx    := Nx;
      G.Ny    := Ny;
      G.Nz    := Nz;
      G.Valid := True;
      return G;
   end Make_Empty_Grid_3D;

   function Make_Linear_1D
     (N : Axis_Size; Y0, Y1 : Float) return Grid_1D
   is
      G : Grid_1D := Make_Empty_Grid_1D (N);
      T : Float;
   begin
      if N = 1 then
         G.Values (0) := Y0;
         return G;
      end if;
      for I in 0 .. N - 1 loop
         T := Float (I) / Float (N - 1);
         G.Values (I) := (1.0 - T) * Y0 + T * Y1;
      end loop;
      return G;
   end Make_Linear_1D;

   function Make_Checkerboard_2D
     (Nx, Ny : Axis_Size; Lo, Hi : Float) return Grid_2D
   is
      G : Grid_2D := Make_Empty_Grid_2D (Nx, Ny);
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

   function Make_Ramp_3D
     (Nx, Ny, Nz : Axis_Size) return Grid_3D
   is
      G : Grid_3D := Make_Empty_Grid_3D (Nx, Ny, Nz);
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
   end Make_Ramp_3D;

   function Make_Scattered_1D_Linear
     (Count : Site_Count; X0, X1, Y0, Y1 : Float) return Scattered_1D
   is
      S : Scattered_1D;
      T : Float;
   begin
      S.Count := Count;
      S.Valid := True;
      if Count = 1 then
         S.Sites (0)  := Make_Site_1D (X0);
         S.Values (0) := Y0;
         return S;
      end if;
      for I in 0 .. Count - 1 loop
         T := Float (I) / Float (Count - 1);
         S.Sites (I)  := Make_Site_1D ((1.0 - T) * X0 + T * X1);
         S.Values (I) := (1.0 - T) * Y0 + T * Y1;
      end loop;
      return S;
   end Make_Scattered_1D_Linear;

   function Make_Scattered_Cloud_2D
     (Count : Site_Count) return Scattered_2D
   is
      S     : Scattered_2D;
      Angle : Float;
      Two_Pi : constant Float := 2.0 * Ada.Numerics.Pi;
   begin
      S.Count := Count;
      S.Valid := True;
      for I in 0 .. Count - 1 loop
         Angle := Two_Pi * Float (I) / Float (Count);
         S.Sites (I)  :=
           Make_Site_2D (Math.Cos (Angle), Math.Sin (Angle));
         S.Values (I) := Float (I);
      end loop;
      return S;
   end Make_Scattered_Cloud_2D;

   function Make_Example_Grid_1D return Grid_1D is
   begin
      return Make_Linear_1D (5, 0.0, 8.0);
   end Make_Example_Grid_1D;

   function Make_Example_Grid_2D return Grid_2D is
   begin
      return Make_Checkerboard_2D (4, 4, 0.0, 1.0);
   end Make_Example_Grid_2D;

   function Make_Example_Scattered_2D return Scattered_2D is
   begin
      return Make_Scattered_Cloud_2D (8);
   end Make_Example_Scattered_2D;

   function Make_Example_Grid_3D return Grid_3D is
   begin
      return Make_Ramp_3D (4, 4, 4);
   end Make_Example_Grid_3D;

end Nearest_Neighbor_Interpolation;
