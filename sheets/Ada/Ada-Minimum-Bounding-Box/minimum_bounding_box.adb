--  Minimum_Bounding_Box body — AABB, convex hull, min-area OBB.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Minimum_Bounding_Box
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Validation helpers
   ---------------------------------------------------------------------------

   procedure Require_Nonempty (N : Natural) is
   begin
      if N < 1 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
   end Require_Nonempty;

   function Next_Idx (I : Positive; N : Positive) return Positive is
     (if I = N then 1 else I + 1);

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

   function Cross (Ax, Ay, Bx, By : Real) return Real is
   begin
      return Ax * By - Ay * Bx;
   end Cross;

   function Cross (A, B : Point) return Real is
   begin
      return A.X * B.Y - A.Y * B.X;
   end Cross;

   function Dot (A, B : Point) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   function Orient2D (A, B, C : Point) return Real is
   begin
      return Cross (B.X - A.X, B.Y - A.Y, C.X - A.X, C.Y - A.Y);
   end Orient2D;

   ---------------------------------------------------------------------------
   -- Dense copy / lex sort helpers for monotone chain
   ---------------------------------------------------------------------------

   function Dense_Copy (Points : Point_Set) return Point_Array is
      N    : constant Positive := Points'Length;
      Copy : Point_Array (1 .. N);
      K    : Positive := 1;
   begin
      for I in Points'Range loop
         Copy (K) := Points (I);
         K := K + 1;
      end loop;
      return Copy;
   end Dense_Copy;

   function Lex_Less (A, B : Point) return Boolean is
   begin
      if abs (A.X - B.X) > Epsilon then
         return A.X < B.X;
      end if;
      return A.Y < B.Y - Epsilon;
   end Lex_Less;

   procedure Sort_Lex (A : in out Point_Array) is
      --  Simple insertion sort (n ≤ 64); educational, stable enough.
      J : Natural;
      Key : Point;
   begin
      for I in A'First + 1 .. A'Last loop
         Key := A (I);
         J := I - 1;
         while J >= A'First and then Lex_Less (Key, A (J)) loop
            A (J + 1) := A (J);
            J := J - 1;
            exit when J < A'First;
         end loop;
         A (J + 1) := Key;
      end loop;
   end Sort_Lex;

   function Dedup_Sorted (A : Point_Array) return Point_Array is
      N : constant Natural := A'Length;
      Tmp : Point_Array (1 .. N);
      M : Natural := 0;
   begin
      if N = 0 then
         return A (1 .. 0);
      end if;
      for I in A'Range loop
         if M = 0
           or else not Near_Point (Tmp (M), A (I))
         then
            M := M + 1;
            Tmp (M) := A (I);
         end if;
      end loop;
      return Tmp (1 .. M);
   end Dedup_Sorted;

   ---------------------------------------------------------------------------
   -- Convex hull — Andrew's monotone chain
   ---------------------------------------------------------------------------

   function Convex_Hull (Points : Point_Set) return Point_Array is
      N : constant Natural := Points'Length;
   begin
      Require_Nonempty (N);

      declare
         Sort : Point_Array := Dense_Copy (Points);
      begin
         Sort_Lex (Sort);
         declare
            Uniq : constant Point_Array := Dedup_Sorted (Sort);
            U    : constant Natural := Uniq'Length;
            Lower : Point_Array (1 .. N);
            Upper : Point_Array (1 .. N);
            L, Up : Natural := 0;
            Out_Buf : Point_Array (1 .. N);
            Out_N : Natural := 0;
            Cross_Val : Real;
         begin
            if U = 1 then
               return Uniq;
            end if;
            if U = 2 then
               return Uniq;
            end if;

            --  Lower hull (left → right).
            for I in 1 .. U loop
               while L >= 2 loop
                  Cross_Val := Orient2D
                    (Lower (L - 1), Lower (L), Uniq (I));
                  exit when Cross_Val > Epsilon;
                  L := L - 1;
               end loop;
               L := L + 1;
               Lower (L) := Uniq (I);
            end loop;

            --  Upper hull (right → left).
            for I in reverse 1 .. U loop
               while Up >= 2 loop
                  Cross_Val := Orient2D
                    (Upper (Up - 1), Upper (Up), Uniq (I));
                  exit when Cross_Val > Epsilon;
                  Up := Up - 1;
               end loop;
               Up := Up + 1;
               Upper (Up) := Uniq (I);
            end loop;

            --  Concatenate, dropping duplicated endpoints.
            for I in 1 .. L - 1 loop
               Out_N := Out_N + 1;
               Out_Buf (Out_N) := Lower (I);
            end loop;
            for I in 1 .. Up - 1 loop
               Out_N := Out_N + 1;
               Out_Buf (Out_N) := Upper (I);
            end loop;

            if Out_N = 0 then
               --  Degenerate: all points coincide after dedup edge cases.
               Out_N := 1;
               Out_Buf (1) := Uniq (Uniq'First);
            end if;

            return Out_Buf (1 .. Out_N);
         end;
      end;
   end Convex_Hull;

   function Hull_Vertex_Count (Points : Point_Set) return Point_Count is
      H : constant Point_Array := Convex_Hull (Points);
   begin
      return H'Length;
   end Hull_Vertex_Count;

   ---------------------------------------------------------------------------
   -- Axis-aligned bounding box
   ---------------------------------------------------------------------------

   function Axis_Aligned_Bounding_Box
     (Points : Point_Set) return Axis_Aligned_Box
   is
      N : constant Natural := Points'Length;
      Box : Axis_Aligned_Box;
      First_Pt : Boolean := True;
   begin
      Require_Nonempty (N);
      for P of Points loop
         if First_Pt then
            Box.Min_X := P.X;
            Box.Max_X := P.X;
            Box.Min_Y := P.Y;
            Box.Max_Y := P.Y;
            First_Pt := False;
         else
            if P.X < Box.Min_X then
               Box.Min_X := P.X;
            end if;
            if P.X > Box.Max_X then
               Box.Max_X := P.X;
            end if;
            if P.Y < Box.Min_Y then
               Box.Min_Y := P.Y;
            end if;
            if P.Y > Box.Max_Y then
               Box.Max_Y := P.Y;
            end if;
         end if;
      end loop;
      Box.Area := (Box.Max_X - Box.Min_X) * (Box.Max_Y - Box.Min_Y);
      if Box.Area < 0.0 then
         Box.Area := 0.0;
      end if;
      return Box;
   end Axis_Aligned_Bounding_Box;

   function AABB_Area (Box : Axis_Aligned_Box) return Real is
   begin
      return Box.Area;
   end AABB_Area;

   function AABB_Width (Box : Axis_Aligned_Box) return Real is
   begin
      return Box.Max_X - Box.Min_X;
   end AABB_Width;

   function AABB_Height (Box : Axis_Aligned_Box) return Real is
   begin
      return Box.Max_Y - Box.Min_Y;
   end AABB_Height;

   ---------------------------------------------------------------------------
   -- Oriented box from a flush edge (shared by OBB + brute alias)
   ---------------------------------------------------------------------------

   function Box_From_Edge
     (Hull : Point_Array;
      Edge_I : Positive) return Oriented_Box
   is
      N : constant Positive := Hull'Length;
      A : constant Point := Hull (Edge_I);
      B : constant Point := Hull (Next_Idx (Edge_I, N));
      EX : constant Real := B.X - A.X;
      EY : constant Real := B.Y - A.Y;
      ELen : constant Real := Dist (A, B);
      UX, UY, NX, NY : Real;
      Min_U, Max_U, Min_V, Max_V : Real;
      U, V : Real;
      Wd, Ht, Ar, Ang : Real;
      R : Oriented_Box;
   begin
      if ELen <= Epsilon then
         --  Degenerate edge: return zero-area box at A.
         R.Corner := [others => A];
         R.Width  := 0.0;
         R.Height := 0.0;
         R.Angle  := 0.0;
         R.Area   := 0.0;
         return R;
      end if;

      UX := EX / ELen;
      UY := EY / ELen;
      NX := -UY;
      NY := UX;

      Min_U := Real'Last;
      Max_U := Real'First;
      Min_V := Real'Last;
      Max_V := Real'First;

      for J in Hull'Range loop
         U := (Hull (J).X - A.X) * UX + (Hull (J).Y - A.Y) * UY;
         V := (Hull (J).X - A.X) * NX + (Hull (J).Y - A.Y) * NY;
         if U < Min_U then
            Min_U := U;
         end if;
         if U > Max_U then
            Max_U := U;
         end if;
         if V < Min_V then
            Min_V := V;
         end if;
         if V > Max_V then
            Max_V := V;
         end if;
      end loop;

      Wd := Max_U - Min_U;
      Ht := Max_V - Min_V;
      if Wd < 0.0 then
         Wd := 0.0;
      end if;
      if Ht < 0.0 then
         Ht := 0.0;
      end if;
      Ar := Wd * Ht;
      Ang := Real (Math.Arctan (Long_Float (EY), Long_Float (EX)));

      R.Corner (1) :=
        (X => A.X + Min_U * UX + Min_V * NX,
         Y => A.Y + Min_U * UY + Min_V * NY);
      R.Corner (2) :=
        (X => A.X + Max_U * UX + Min_V * NX,
         Y => A.Y + Max_U * UY + Min_V * NY);
      R.Corner (3) :=
        (X => A.X + Max_U * UX + Max_V * NX,
         Y => A.Y + Max_U * UY + Max_V * NY);
      R.Corner (4) :=
        (X => A.X + Min_U * UX + Max_V * NX,
         Y => A.Y + Min_U * UY + Max_V * NY);
      R.Area   := Ar;
      R.Width  := Wd;
      R.Height := Ht;
      R.Angle  := Ang;
      return R;
   end Box_From_Edge;

   function Oriented_Box_From_Hull
     (Hull : Point_Array) return Oriented_Box
   is
      N : constant Natural := Hull'Length;
      Best : Oriented_Box;
      Cand : Oriented_Box;
      First : Boolean := True;
      Single : Point;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;

      if N = 1 then
         Single := Hull (Hull'First);
         Best.Corner := [others => Single];
         Best.Width  := 0.0;
         Best.Height := 0.0;
         Best.Angle  := 0.0;
         Best.Area   := 0.0;
         return Best;
      end if;

      if N = 2 then
         --  Degenerate segment: zero-height box along the segment.
         Cand := Box_From_Edge (Hull, Hull'First);
         return Cand;
      end if;

      Best.Area := Real'Last;
      for I in Hull'Range loop
         Cand := Box_From_Edge (Hull, I);
         if First or else Cand.Area < Best.Area - Epsilon
           or else (Near (Cand.Area, Best.Area)
                    and then Cand.Width + Cand.Height
                             < Best.Width + Best.Height)
         then
            Best := Cand;
            First := False;
         end if;
      end loop;

      if First then
         raise Invalid_Argument;
      end if;
      return Best;
   end Oriented_Box_From_Hull;

   function Min_Area_Oriented_Box
     (Points : Point_Set) return Oriented_Box
   is
      Hull : constant Point_Array := Convex_Hull (Points);
   begin
      return Oriented_Box_From_Hull (Hull);
   end Min_Area_Oriented_Box;

   function OBB_Area (Box : Oriented_Box) return Real is
   begin
      return Box.Area;
   end OBB_Area;

   function OBB_Width (Box : Oriented_Box) return Real is
   begin
      return Box.Width;
   end OBB_Width;

   function OBB_Height (Box : Oriented_Box) return Real is
   begin
      return Box.Height;
   end OBB_Height;

   function OBB_Angle (Box : Oriented_Box) return Real is
   begin
      return Box.Angle;
   end OBB_Angle;

   function OBB_Corner
     (Box : Oriented_Box; Index : Point_Index) return Point
   is
   begin
      return Box.Corner (Index);
   end OBB_Corner;

   function Brute_Min_Area_OBB
     (Points : Point_Set) return Oriented_Box
   is
   begin
      --  Same algorithm; alias for teaching / cross-check naming.
      return Min_Area_Oriented_Box (Points);
   end Brute_Min_Area_OBB;

end Minimum_Bounding_Box;
