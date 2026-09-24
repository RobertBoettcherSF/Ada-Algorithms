--  Cone_Algorithm body — 3-D empty-cone surface particle identification.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Cone_Algorithm
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Points (N : Natural) is
   begin
      if N < 1 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
   end Require_Points;

   procedure Require_Cutoff (Cutoff : Real) is
   begin
      if Cutoff <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Require_Cutoff;

   procedure Require_Half_Angle (Half_Angle : Real) is
   begin
      --  Open on the left, closed on the right: (0, π/2].
      if Half_Angle <= 0.0 or else Half_Angle > Half_Pi then
         raise Invalid_Argument;
      end if;
   end Require_Half_Angle;

   procedure Require_Index (Points : Point_Array; Index : Positive) is
   begin
      if Index < Points'First or else Index > Points'Last then
         raise Invalid_Argument;
      end if;
   end Require_Index;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol)
        and then Near (A.Y, B.Y, Tol)
        and then Near (A.Z, B.Z, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      DX : constant Real := B.X - A.X;
      DY : constant Real := B.Y - A.Y;
      DZ : constant Real := B.Z - A.Z;
   begin
      return DX * DX + DY * DY + DZ * DZ;
   end Dist2;

   function Dist (A, B : Point) return Real is
      D2 : constant Real := Dist2 (A, B);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (D2)));
   end Dist;

   function Dot (A, B : Point) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   function Cross (A, B : Point) return Point is
   begin
      return
        (X => A.Y * B.Z - A.Z * B.Y,
         Y => A.Z * B.X - A.X * B.Z,
         Z => A.X * B.Y - A.Y * B.X);
   end Cross;

   function Norm2 (V : Point) return Real is
   begin
      return V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   end Norm2;

   function Norm (V : Point) return Real is
      N2 : constant Real := Norm2 (V);
   begin
      if N2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (N2)));
   end Norm;

   function Normalize (V : Point) return Point is
      N : constant Real := Norm (V);
   begin
      if N < Epsilon then
         return (X => 0.0, Y => 0.0, Z => 0.0);
      end if;
      return (X => V.X / N, Y => V.Y / N, Z => V.Z / N);
   end Normalize;

   function Sub (A, B : Point) return Point is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y, Z => A.Z - B.Z);
   end Sub;

   function Add (A, B : Point) return Point is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y, Z => A.Z + B.Z);
   end Add;

   function Scale (V : Point; S : Real) return Point is
   begin
      return (X => V.X * S, Y => V.Y * S, Z => V.Z * S);
   end Scale;

   ---------------------------------------------------------------------------
   -- Neighbor collection + empty-cone test
   ---------------------------------------------------------------------------

   --  Max neighbors = Max_Points - 1.
   subtype Neighbor_Count is Natural range 0 .. Max_Points - 1;
   type Unit_Array is array (Positive range <>) of Point;

   procedure Collect_Neighbor_Units
     (Points    : Point_Array;
      Index     : Positive;
      Cutoff    : Real;
      Units     : out Unit_Array;
      Count     : out Neighbor_Count)
   is
      Origin : constant Point := Points (Index);
      Cut2   : constant Real := Cutoff * Cutoff;
      D2     : Real;
      Diff   : Point;
      U      : Point;
   begin
      Count := 0;
      for J in Points'Range loop
         if J /= Index then
            D2 := Dist2 (Origin, Points (J));
            if D2 > Epsilon * Epsilon and then D2 <= Cut2 then
               Diff := Sub (Points (J), Origin);
               U := Normalize (Diff);
               if Norm2 (U) > 0.0 then
                  Count := Count + 1;
                  Units (Count) := U;
               end if;
            end if;
         end if;
      end loop;
   end Collect_Neighbor_Units;

   function Cone_Is_Empty
     (Axis     : Point;
      Units    : Unit_Array;
      Count    : Neighbor_Count;
      Cos_Lim  : Real) return Boolean
   is
      --  Axis must be approximately unit and nonzero.
   begin
      if Norm2 (Axis) < Epsilon * Epsilon then
         return False;
      end if;
      for K in 1 .. Count loop
         --  Neighbor inside or on the cone ⇒ not empty.
         if Dot (Axis, Units (K)) >= Cos_Lim then
            return False;
         end if;
      end loop;
      return True;
   end Cone_Is_Empty;

   --  Fixed classroom sample: 6 axes + 12 face-diagonals + 8 space-diagonals.
   Sample_Count : constant := 26;

   function Sample_Direction (K : Positive) return Point is
      --  Returns a nonzero (not necessarily unit) direction; caller normalizes.
      type Trip is array (1 .. 3) of Real;
      D : Trip;
   begin
      case K is
         --  ±e_x, ±e_y, ±e_z
         when 1 => D := [1.0, 0.0, 0.0];
         when 2 => D := [-1.0, 0.0, 0.0];
         when 3 => D := [0.0, 1.0, 0.0];
         when 4 => D := [0.0, -1.0, 0.0];
         when 5 => D := [0.0, 0.0, 1.0];
         when 6 => D := [0.0, 0.0, -1.0];
         --  Face diagonals (12)
         when 7  => D := [1.0, 1.0, 0.0];
         when 8  => D := [1.0, -1.0, 0.0];
         when 9  => D := [-1.0, 1.0, 0.0];
         when 10 => D := [-1.0, -1.0, 0.0];
         when 11 => D := [1.0, 0.0, 1.0];
         when 12 => D := [1.0, 0.0, -1.0];
         when 13 => D := [-1.0, 0.0, 1.0];
         when 14 => D := [-1.0, 0.0, -1.0];
         when 15 => D := [0.0, 1.0, 1.0];
         when 16 => D := [0.0, 1.0, -1.0];
         when 17 => D := [0.0, -1.0, 1.0];
         when 18 => D := [0.0, -1.0, -1.0];
         --  Space diagonals (8)
         when 19 => D := [1.0, 1.0, 1.0];
         when 20 => D := [1.0, 1.0, -1.0];
         when 21 => D := [1.0, -1.0, 1.0];
         when 22 => D := [1.0, -1.0, -1.0];
         when 23 => D := [-1.0, 1.0, 1.0];
         when 24 => D := [-1.0, 1.0, -1.0];
         when 25 => D := [-1.0, -1.0, 1.0];
         when others => D := [-1.0, -1.0, -1.0];
      end case;
      return (X => D (1), Y => D (2), Z => D (3));
   end Sample_Direction;

   function Has_Empty_Cone
     (Units   : Unit_Array;
      Count   : Neighbor_Count;
      Cos_Lim : Real) return Boolean
   is
      Sum      : Point := (0.0, 0.0, 0.0);
      Axis     : Point;
      Pair_Sum : Point;
   begin
      if Count = 0 then
         return True;
      end if;

      --  1. Outward mean: −normalize(∑ u_j).
      for K in 1 .. Count loop
         Sum := Add (Sum, Units (K));
      end loop;
      Axis := Normalize (Scale (Sum, -1.0));
      if Cone_Is_Empty (Axis, Units, Count, Cos_Lim) then
         return True;
      end if;

      --  2. Opposite each neighbor.
      for K in 1 .. Count loop
         Axis := Normalize (Scale (Units (K), -1.0));
         if Cone_Is_Empty (Axis, Units, Count, Cos_Lim) then
            return True;
         end if;
      end loop;

      --  3. Opposite pairwise averages (limited; educational).
      if Count >= 2 then
         for A in 1 .. Count - 1 loop
            for B in A + 1 .. Count loop
               Pair_Sum := Add (Units (A), Units (B));
               Axis := Normalize (Scale (Pair_Sum, -1.0));
               if Cone_Is_Empty (Axis, Units, Count, Cos_Lim) then
                  return True;
               end if;
            end loop;
         end loop;
      end if;

      --  4. Fixed cube-direction samples.
      for S in 1 .. Sample_Count loop
         Axis := Normalize (Sample_Direction (S));
         if Cone_Is_Empty (Axis, Units, Count, Cos_Lim) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Empty_Cone;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   function Is_Surface_Particle
     (Points     : Point_Array;
      Index      : Positive;
      Cutoff     : Real;
      Half_Angle : Real) return Boolean
   is
      Units   : Unit_Array (1 .. Max_Points - 1);
      Count   : Neighbor_Count;
      Cos_Lim : Real;
   begin
      Require_Points (Points'Length);
      Require_Index (Points, Index);
      Require_Cutoff (Cutoff);
      Require_Half_Angle (Half_Angle);

      Collect_Neighbor_Units (Points, Index, Cutoff, Units, Count);
      if Count = 0 then
         return True;
      end if;

      Cos_Lim := Real (Math.Cos (Long_Float (Half_Angle)));
      return Has_Empty_Cone (Units, Count, Cos_Lim);
   end Is_Surface_Particle;

   function Surface_Mask
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Boolean_Array
   is
      Mask : Boolean_Array (Points'Range);
   begin
      Require_Points (Points'Length);
      Require_Cutoff (Cutoff);
      Require_Half_Angle (Half_Angle);

      for I in Points'Range loop
         Mask (I) := Is_Surface_Particle (Points, I, Cutoff, Half_Angle);
      end loop;
      return Mask;
   end Surface_Mask;

   function Count_Surface
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Point_Count
   is
      Mask  : constant Boolean_Array :=
        Surface_Mask (Points, Cutoff, Half_Angle);
      Total : Point_Count := 0;
   begin
      for I in Mask'Range loop
         if Mask (I) then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Surface;

   function Extract_Surface
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Point_Array
   is
      Mask  : constant Boolean_Array :=
        Surface_Mask (Points, Cutoff, Half_Angle);
      N     : Point_Count := 0;
      K     : Natural := 0;
   begin
      for I in Mask'Range loop
         if Mask (I) then
            N := N + 1;
         end if;
      end loop;

      declare
         Result : Point_Array (1 .. N);
      begin
         for I in Mask'Range loop
            if Mask (I) then
               K := K + 1;
               Result (K) := Points (I);
            end if;
         end loop;
         return Result;
      end;
   end Extract_Surface;

   function Extract_Surface_Indices
     (Points     : Point_Array;
      Cutoff     : Real;
      Half_Angle : Real) return Index_Array
   is
      Mask  : constant Boolean_Array :=
        Surface_Mask (Points, Cutoff, Half_Angle);
      N     : Point_Count := 0;
      K     : Natural := 0;
   begin
      for I in Mask'Range loop
         if Mask (I) then
            N := N + 1;
         end if;
      end loop;

      declare
         Result : Index_Array (1 .. N);
      begin
         for I in Mask'Range loop
            if Mask (I) then
               K := K + 1;
               Result (K) := I;
            end if;
         end loop;
         return Result;
      end;
   end Extract_Surface_Indices;

   function Is_Surface_By_Asymmetry
     (Points              : Point_Array;
      Index               : Positive;
      Cutoff              : Real;
      Asymmetry_Threshold : Real) return Boolean
   is
      Units : Unit_Array (1 .. Max_Points - 1);
      Count : Neighbor_Count;
      Sum   : Point := (0.0, 0.0, 0.0);
   begin
      Require_Points (Points'Length);
      Require_Index (Points, Index);
      Require_Cutoff (Cutoff);
      if Asymmetry_Threshold < 0.0 then
         raise Invalid_Argument;
      end if;

      Collect_Neighbor_Units (Points, Index, Cutoff, Units, Count);
      if Count = 0 then
         return True;
      end if;

      for K in 1 .. Count loop
         Sum := Add (Sum, Units (K));
      end loop;
      return Norm (Sum) >= Asymmetry_Threshold;
   end Is_Surface_By_Asymmetry;

end Cone_Algorithm;
