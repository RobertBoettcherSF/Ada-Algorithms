--  Closest_Pair_Problem body — brute force + Shamos divide-and-conquer.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Closest_Pair_Problem
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Internal indexed point (dense 1 .. n + original 1-based encounter index)
   ---------------------------------------------------------------------------

   type Indexed_Point is record
      P   : Point       := (0.0, 0.0);
      Idx : Point_Index := 1;
   end record;

   type Indexed_Array is array (Point_Index range <>) of Indexed_Point;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Pairable (N : Natural) is
   begin
      if N < 2 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
   end Require_Pairable;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      DX : constant Real := B.X - A.X;
      DY : constant Real := B.Y - A.Y;
   begin
      return DX * DX + DY * DY;
   end Dist2;

   function Dist (A, B : Point) return Real is
      D2 : constant Real := Dist2 (A, B);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (D2)));
   end Dist;

   ---------------------------------------------------------------------------
   -- Pair helpers (canonical Index_A < Index_B)
   ---------------------------------------------------------------------------

   function Make_Result
     (IA, IB : Point_Index; D : Real) return Pair_Result
   is
      R : Pair_Result;
   begin
      if IA < IB then
         R := (Index_A => IA, Index_B => IB, Distance => D);
      else
         R := (Index_A => IB, Index_B => IA, Distance => D);
      end if;
      return R;
   end Make_Result;

   function Better (Cand, Cur : Pair_Result) return Pair_Result is
   begin
      if Cand.Distance < Cur.Distance then
         return Cand;
      elsif Near (Cand.Distance, Cur.Distance) then
         --  Prefer lexicographically smaller (Index_A, Index_B) for stability.
         if Cand.Index_A < Cur.Index_A
           or else (Cand.Index_A = Cur.Index_A
                    and then Cand.Index_B < Cur.Index_B)
         then
            return Cand;
         end if;
      end if;
      return Cur;
   end Better;

   ---------------------------------------------------------------------------
   -- Copy input into dense 1 .. n indexed buffer
   ---------------------------------------------------------------------------

   function To_Indexed (Points : Point_Array) return Indexed_Array is
      N   : constant Point_Count := Points'Length;
      Buf : Indexed_Array (1 .. N);
      K   : Point_Index := 1;
   begin
      for I in Points'Range loop
         Buf (K) := (P => Points (I), Idx => K);
         if K < N then
            K := K + 1;
         end if;
      end loop;
      return Buf;
   end To_Indexed;

   ---------------------------------------------------------------------------
   -- Sorting (insertion sort — educational; n ≤ Max_Points)
   ---------------------------------------------------------------------------

   function X_Less (A, B : Indexed_Point) return Boolean is
   begin
      if abs (A.P.X - B.P.X) > Epsilon then
         return A.P.X < B.P.X;
      end if;
      if abs (A.P.Y - B.P.Y) > Epsilon then
         return A.P.Y < B.P.Y;
      end if;
      return A.Idx < B.Idx;
   end X_Less;

   function Y_Less (A, B : Indexed_Point) return Boolean is
   begin
      if abs (A.P.Y - B.P.Y) > Epsilon then
         return A.P.Y < B.P.Y;
      end if;
      if abs (A.P.X - B.P.X) > Epsilon then
         return A.P.X < B.P.X;
      end if;
      return A.Idx < B.Idx;
   end Y_Less;

   procedure Sort_By_X (A : in out Indexed_Array) is
      Key : Indexed_Point;
      J   : Integer;
   begin
      for I in A'First + 1 .. A'Last loop
         Key := A (I);
         J   := Integer (I) - 1;
         while J >= Integer (A'First)
           and then X_Less (Key, A (Point_Index (J)))
         loop
            A (Point_Index (J + 1)) := A (Point_Index (J));
            J := J - 1;
         end loop;
         A (Point_Index (J + 1)) := Key;
      end loop;
   end Sort_By_X;

   procedure Sort_By_Y (A : in out Indexed_Array) is
      Key : Indexed_Point;
      J   : Integer;
   begin
      for I in A'First + 1 .. A'Last loop
         Key := A (I);
         J   := Integer (I) - 1;
         while J >= Integer (A'First)
           and then Y_Less (Key, A (Point_Index (J)))
         loop
            A (Point_Index (J + 1)) := A (Point_Index (J));
            J := J - 1;
         end loop;
         A (Point_Index (J + 1)) := Key;
      end loop;
   end Sort_By_Y;

   ---------------------------------------------------------------------------
   -- Brute force on an indexed slice (also base case of D&C)
   ---------------------------------------------------------------------------

   function Brute_Indexed (A : Indexed_Array) return Pair_Result is
      Best  : Pair_Result;
      First : Boolean := True;
      D     : Real;
      Cand  : Pair_Result;
   begin
      for I in A'Range loop
         for J in I + 1 .. A'Last loop
            D    := Dist (A (I).P, A (J).P);
            Cand := Make_Result (A (I).Idx, A (J).Idx, D);
            if First then
               Best  := Cand;
               First := False;
            else
               Best := Better (Cand, Best);
            end if;
         end loop;
      end loop;
      return Best;
   end Brute_Indexed;

   ---------------------------------------------------------------------------
   -- Strip refinement: Y-sorted strip, check ≤7 higher-Y neighbors
   ---------------------------------------------------------------------------

   procedure Refine_Strip
     (Strip : Indexed_Array;
      Best  : in out Pair_Result)
   is
      D2_Best : Real := Best.Distance * Best.Distance;
      D2      : Real;
      Cand    : Pair_Result;
      Last_J  : Point_Index;
      Limit   : Natural;
   begin
      for I in Strip'Range loop
         Limit := Natural (I) + 7;
         if Limit > Natural (Strip'Last) then
            Last_J := Strip'Last;
         else
            Last_J := Point_Index (Limit);
         end if;
         for J in I + 1 .. Last_J loop
            --  Early exit: Y-gap already ≥ δ ⇒ later points are farther.
            if Strip (J).P.Y - Strip (I).P.Y >= Best.Distance then
               exit;
            end if;
            D2 := Dist2 (Strip (I).P, Strip (J).P);
            if D2 < D2_Best then
               D2_Best := D2;
               Cand    := Make_Result
                 (Strip (I).Idx, Strip (J).Idx, Dist (Strip (I).P, Strip (J).P));
               Best    := Better (Cand, Best);
            elsif Near (D2, D2_Best) then
               Cand := Make_Result
                 (Strip (I).Idx, Strip (J).Idx, Dist (Strip (I).P, Strip (J).P));
               Best := Better (Cand, Best);
            end if;
         end loop;
      end loop;
   end Refine_Strip;

   ---------------------------------------------------------------------------
   -- Recursive D&C on X-sorted Px; Py is Y-sorted subset of the same points
   ---------------------------------------------------------------------------

   function Closest_Rec
     (Px, Py : Indexed_Array) return Pair_Result
   is
      N : constant Natural := Px'Length;
   begin
      if N <= 3 then
         return Brute_Indexed (Px);
      end if;

      declare
         Mid      : constant Point_Index :=
                      Point_Index (Natural (Px'First) + (N / 2) - 1);
         Mid_X    : constant Real := Px (Mid).P.X;
         Left_N   : constant Natural := Natural (Mid) - Natural (Px'First) + 1;
         Right_N  : constant Natural := N - Left_N;
         Qx       : Indexed_Array (1 .. Left_N);
         Rx       : Indexed_Array (1 .. Right_N);
         Qy       : Indexed_Array (1 .. Left_N);
         Ry       : Indexed_Array (1 .. Right_N);
         --  Membership: point belongs to left half iff its Idx appears in Qx.
         In_Left  : array (Point_Index) of Boolean := [others => False];
         QI, RI   : Natural := 0;
         Left_Res : Pair_Result;
         Right_Res : Pair_Result;
         Best     : Pair_Result;
         Delta_D  : Real;
         Strip    : Indexed_Array (1 .. N);
         Strip_N  : Natural := 0;
      begin
         for I in Px'First .. Mid loop
            Qx (Point_Index (Natural (I) - Natural (Px'First) + 1)) := Px (I);
            In_Left (Px (I).Idx) := True;
         end loop;
         for I in Mid + 1 .. Px'Last loop
            Rx (Point_Index (Natural (I) - Natural (Mid))) := Px (I);
         end loop;

         --  Partition Py into Qy / Ry preserving Y order.
         for I in Py'Range loop
            if In_Left (Py (I).Idx) then
               QI := QI + 1;
               Qy (Point_Index (QI)) := Py (I);
            else
               RI := RI + 1;
               Ry (Point_Index (RI)) := Py (I);
            end if;
         end loop;

         Left_Res  := Closest_Rec (Qx, Qy);
         Right_Res := Closest_Rec (Rx, Ry);
         Best      := Better (Left_Res, Right_Res);
         Delta_D   := Best.Distance;

         --  Build midline strip of width 2δ from Y-sorted Py.
         for I in Py'Range loop
            if abs (Py (I).P.X - Mid_X) < Delta_D then
               Strip_N := Strip_N + 1;
               Strip (Point_Index (Strip_N)) := Py (I);
            end if;
         end loop;

         if Strip_N >= 2 then
            declare
               S : Indexed_Array renames
                     Strip (1 .. Point_Index (Strip_N));
            begin
               Refine_Strip (S, Best);
            end;
         end if;

         return Best;
      end;
   end Closest_Rec;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

   function Brute_Force (Points : Point_Array) return Pair_Result is
      N : constant Natural := Points'Length;
   begin
      Require_Pairable (N);
      return Brute_Indexed (To_Indexed (Points));
   end Brute_Force;

   function Divide_And_Conquer (Points : Point_Array) return Pair_Result is
      N : constant Natural := Points'Length;
   begin
      Require_Pairable (N);
      declare
         Px : Indexed_Array (1 .. N);
         Py : Indexed_Array (1 .. N);
      begin
         Px := To_Indexed (Points);
         Py := Px;
         Sort_By_X (Px);
         Sort_By_Y (Py);
         return Closest_Rec (Px, Py);
      end;
   end Divide_And_Conquer;

   function Closest_Pair (Points : Point_Array) return Pair_Result is
   begin
      return Divide_And_Conquer (Points);
   end Closest_Pair;

   function Closest_Pair
     (Points : Point_Array; Method : Method_Kind) return Pair_Result
   is
   begin
      case Method is
         when Brute =>
            return Brute_Force (Points);
         when Divide_Conquer =>
            return Divide_And_Conquer (Points);
      end case;
   end Closest_Pair;

end Closest_Pair_Problem;
