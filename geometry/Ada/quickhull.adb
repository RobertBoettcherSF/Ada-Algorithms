--  Quickhull body — 2D Quickhull + Andrew monotone-chain teaching oracle.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Quickhull
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

   function Distance_To_Line (P, A, B : Point) return Real is
      Len2  : constant Real := Dist2 (A, B);
      Area2 : Real;
   begin
      if Len2 <= Epsilon * Epsilon then
         return Dist (A, P);
      end if;
      Area2 := abs (Orient2D (A, B, P));
      return Area2 / Real (Math.Sqrt (Long_Float (Len2)));
   end Distance_To_Line;

   function Signed_Area (Poly : Point_Array) return Real is
      N     : constant Natural := Poly'Length;
      Sum   : Real := 0.0;
      J     : Positive;
      Dense : Point_Array (1 .. N);
      K     : Positive := 1;
   begin
      if N < 3 or else N > Max_Points then
         raise Invalid_Argument;
      end if;
      for Pt of Poly loop
         Dense (K) := Pt;
         K := K + 1;
      end loop;
      for I in 1 .. N loop
         J := (if I = N then 1 else I + 1);
         Sum := Sum + Dense (I).X * Dense (J).Y - Dense (J).X * Dense (I).Y;
      end loop;
      return Sum / 2.0;
   end Signed_Area;

   function Is_CCW (Poly : Point_Array) return Boolean is
   begin
      return Signed_Area (Poly) > Epsilon;
   end Is_CCW;

   ---------------------------------------------------------------------------
   -- Dense copy / lex helpers (shared by Quickhull extremes + Andrew)
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
      J   : Natural;
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
      N   : constant Natural := A'Length;
      Tmp : Point_Array (1 .. N);
      M   : Natural := 0;
   begin
      if N = 0 then
         return A (1 .. 0);
      end if;
      for I in A'Range loop
         if M = 0 or else not Near_Point (Tmp (M), A (I)) then
            M := M + 1;
            Tmp (M) := A (I);
         end if;
      end loop;
      return Tmp (1 .. M);
   end Dedup_Sorted;

   ---------------------------------------------------------------------------
   -- Quickhull core (Wikipedia right-of-line convention → CCW hull)
   ---------------------------------------------------------------------------
   --  Find_Hull appends interior chain vertices strictly between P and Q
   --  (exclusive) into Out_Buf, along the hull arc from P to Q.  Points
   --  considered are those strictly to the RIGHT of directed PQ
   --  (Orient2D < −Epsilon), matching the classical Quickhull pseudocode.
   --  Assembling A → (right of A→B) → B → (right of B→A) yields CCW order.

   procedure Find_Hull
     (Pts     : Point_Array;
      P, Q    : Point;
      Out_Buf : in out Point_Array;
      Out_N   : in out Natural)
   is
      N      : constant Natural := Pts'Length;
      Side   : Point_Array (1 .. N);
      Side_N : Natural := 0;
      Best   : Point;
      Best_D : Real := -1.0;
      D      : Real;
      Found  : Boolean := False;
      Right1 : Point_Array (1 .. N);
      Right2 : Point_Array (1 .. N);
      R1, R2 : Natural := 0;
      O1, O2 : Real;
   begin
      if N = 0 then
         return;
      end if;

      --  Collect points strictly right of directed PQ; track farthest.
      for I in Pts'Range loop
         if Orient2D (P, Q, Pts (I)) < -Epsilon then
            Side_N := Side_N + 1;
            Side (Side_N) := Pts (I);
            D := Distance_To_Line (Pts (I), P, Q);
            if (not Found) or else D > Best_D + Epsilon
              or else (Near (D, Best_D) and then Lex_Less (Pts (I), Best))
            then
               Best_D := D;
               Best := Pts (I);
               Found := True;
            end if;
         end if;
      end loop;

      if not Found then
         return;
      end if;

      --  Partition: S1 right of P→C, S2 right of C→Q; discard inside PCQ.
      for I in 1 .. Side_N loop
         if not Near_Point (Side (I), Best) then
            O1 := Orient2D (P, Best, Side (I));
            O2 := Orient2D (Best, Q, Side (I));
            if O1 < -Epsilon then
               R1 := R1 + 1;
               Right1 (R1) := Side (I);
            elsif O2 < -Epsilon then
               R2 := R2 + 1;
               Right2 (R2) := Side (I);
            end if;
         end if;
      end loop;

      Find_Hull (Right1 (1 .. R1), P, Best, Out_Buf, Out_N);
      Out_N := Out_N + 1;
      Out_Buf (Out_N) := Best;
      Find_Hull (Right2 (1 .. R2), Best, Q, Out_Buf, Out_N);
   end Find_Hull;

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
         begin
            if U = 1 then
               return Uniq;
            end if;
            if U = 2 then
               return Uniq;
            end if;

            declare
               --  Leftmost / rightmost (lex extremes after sort).
               A : constant Point := Uniq (Uniq'First);
               B : constant Point := Uniq (Uniq'Last);
               Lower_In : Point_Array (1 .. U);
               Upper_In : Point_Array (1 .. U);
               Lo_N, Up_N : Natural := 0;
               Out_Buf : Point_Array (1 .. U);
               Out_N   : Natural := 0;
               O       : Real;
            begin
               if Near_Point (A, B) then
                  return Uniq (Uniq'First .. Uniq'First);
               end if;

               for I in Uniq'Range loop
                  if not Near_Point (Uniq (I), A)
                    and then not Near_Point (Uniq (I), B)
                  then
                     O := Orient2D (A, B, Uniq (I));
                     if O < -Epsilon then
                        --  Right of A→B: lower side (A left, B right).
                        Lo_N := Lo_N + 1;
                        Lower_In (Lo_N) := Uniq (I);
                     elsif O > Epsilon then
                        --  Right of B→A: upper side.
                        Up_N := Up_N + 1;
                        Upper_In (Up_N) := Uniq (I);
                     end if;
                     --  collinear with AB: interior of segment — drop
                  end if;
               end loop;

               --  CCW: A → lower arc → B → upper arc.
               Out_N := 1;
               Out_Buf (1) := A;
               Find_Hull (Lower_In (1 .. Lo_N), A, B, Out_Buf, Out_N);
               Out_N := Out_N + 1;
               Out_Buf (Out_N) := B;
               Find_Hull (Upper_In (1 .. Up_N), B, A, Out_Buf, Out_N);

               if Out_N < 1 then
                  return Uniq (Uniq'First .. Uniq'First);
               end if;
               return Out_Buf (1 .. Out_N);
            end;
         end;
      end;
   end Convex_Hull;

   function Hull_Vertex_Count (Points : Point_Set) return Point_Count is
      H : constant Point_Array := Convex_Hull (Points);
   begin
      return H'Length;
   end Hull_Vertex_Count;

   ---------------------------------------------------------------------------
   -- Andrew monotone chain (teaching oracle)
   ---------------------------------------------------------------------------

   function Andrew_Monotone_Chain (Points : Point_Set) return Point_Array is
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
            if U = 1 or else U = 2 then
               return Uniq;
            end if;

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

            for I in 1 .. L - 1 loop
               Out_N := Out_N + 1;
               Out_Buf (Out_N) := Lower (I);
            end loop;
            for I in 1 .. Up - 1 loop
               Out_N := Out_N + 1;
               Out_Buf (Out_N) := Upper (I);
            end loop;

            if Out_N = 0 then
               Out_N := 1;
               Out_Buf (1) := Uniq (Uniq'First);
            end if;

            return Out_Buf (1 .. Out_N);
         end;
      end;
   end Andrew_Monotone_Chain;

end Quickhull;
