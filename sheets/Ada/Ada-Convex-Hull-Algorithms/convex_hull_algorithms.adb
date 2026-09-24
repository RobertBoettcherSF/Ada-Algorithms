--  Convex_Hull_Algorithms body — survey of Gift wrapping, Graham scan,
--  Andrew monotone chain, and Quickhull (self-contained classroom sketch).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Convex_Hull_Algorithms
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

   function Polar_Less (Pivot, A, B : Point) return Boolean is
      O : constant Real := Orient2D (Pivot, A, B);
   begin
      if abs (O) > Epsilon then
         return O > 0.0;
      end if;
      return Dist2 (Pivot, A) < Dist2 (Pivot, B) - Epsilon * Epsilon;
   end Polar_Less;

   function Distance_To_Line (P, A, B : Point) return Real is
      Len2  : constant Real := Dist2 (A, B);
      Area2 : Real;
   begin
      if Len2 <= Epsilon * Epsilon then
         return 0.0;
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
   -- Dense copy / lex helpers (shared)
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
   -- 1. Gift wrapping / Jarvis march
   ---------------------------------------------------------------------------

   function Leftmost_Then_Lowest (Pts : Point_Array) return Positive is
      Best : Positive := Pts'First;
   begin
      for I in Pts'First + 1 .. Pts'Last loop
         if Pts (I).X < Pts (Best).X - Epsilon then
            Best := I;
         elsif Near (Pts (I).X, Pts (Best).X)
           and then Pts (I).Y < Pts (Best).Y - Epsilon
         then
            Best := I;
         end if;
      end loop;
      return Best;
   end Leftmost_Then_Lowest;

   function Better_Next
     (Current, Endpoint, Q : Point) return Boolean
   is
      O : constant Real := Orient2D (Current, Endpoint, Q);
   begin
      if Near_Point (Endpoint, Current) then
         return not Near_Point (Q, Current);
      end if;
      if O < -Epsilon then
         return True;
      end if;
      if abs (O) <= Epsilon then
         return Dist2 (Current, Q) > Dist2 (Current, Endpoint) + Epsilon * Epsilon;
      end if;
      return False;
   end Better_Next;

   function Gift_Wrapping (Points : Point_Set) return Point_Array is
      N : constant Natural := Points'Length;
   begin
      Require_Nonempty (N);

      declare
         Raw : Point_Array := Dense_Copy (Points);
      begin
         Sort_Lex (Raw);
         declare
            Uniq : constant Point_Array := Dedup_Sorted (Raw);
            U    : constant Natural := Uniq'Length;
         begin
            if U = 1 or else U = 2 then
               return Uniq;
            end if;

            declare
               Hull          : Point_Array (1 .. U);
               H             : Natural := 0;
               Start_I       : constant Positive := Leftmost_Then_Lowest (Uniq);
               Point_On_Hull : Point := Uniq (Start_I);
               Endpoint      : Point;
               Guard         : Natural := 0;
            begin
               loop
                  H := H + 1;
                  Hull (H) := Point_On_Hull;

                  Endpoint := Uniq (Uniq'First);
                  if Near_Point (Endpoint, Point_On_Hull) then
                     Endpoint := Uniq (Uniq'First + 1);
                  end if;

                  for J in Uniq'Range loop
                     if Better_Next (Point_On_Hull, Endpoint, Uniq (J)) then
                        Endpoint := Uniq (J);
                     end if;
                  end loop;

                  Point_On_Hull := Endpoint;
                  Guard := Guard + 1;
                  exit when Near_Point (Endpoint, Hull (1));
                  exit when Guard >= U;
               end loop;

               if H < 1 then
                  return Uniq (Uniq'First .. Uniq'First);
               end if;
               return Hull (1 .. H);
            end;
         end;
      end;
   end Gift_Wrapping;

   function Jarvis_March (Points : Point_Set) return Point_Array is
   begin
      return Gift_Wrapping (Points);
   end Jarvis_March;

   ---------------------------------------------------------------------------
   -- 2. Graham scan
   ---------------------------------------------------------------------------

   function Lowest_Then_Leftmost (Pts : Point_Array) return Positive is
      Best : Positive := Pts'First;
   begin
      for I in Pts'First + 1 .. Pts'Last loop
         if Pts (I).Y < Pts (Best).Y - Epsilon then
            Best := I;
         elsif Near (Pts (I).Y, Pts (Best).Y)
           and then Pts (I).X < Pts (Best).X - Epsilon
         then
            Best := I;
         end if;
      end loop;
      return Best;
   end Lowest_Then_Leftmost;

   procedure Sort_Polar (A : in out Point_Array; Pivot : Point) is
      J   : Natural;
      Key : Point;
   begin
      if A'Length <= 2 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         Key := A (I);
         J := I - 1;
         while J >= A'First + 1 and then Polar_Less (Pivot, Key, A (J)) loop
            A (J + 1) := A (J);
            J := J - 1;
            exit when J < A'First + 1;
         end loop;
         A (J + 1) := Key;
      end loop;
   end Sort_Polar;

   function Keep_Farthest_On_Rays
     (Sorted : Point_Array; Pivot : Point) return Point_Array
   is
      N   : constant Natural := Sorted'Length;
      Tmp : Point_Array (1 .. N);
      M   : Natural := 0;
      O   : Real;
   begin
      if N = 0 then
         return Sorted (1 .. 0);
      end if;
      Tmp (1) := Pivot;
      M := 1;
      for I in Sorted'First + 1 .. Sorted'Last loop
         if M = 1 then
            M := 2;
            Tmp (2) := Sorted (I);
         else
            O := Orient2D (Pivot, Tmp (M), Sorted (I));
            if abs (O) <= Epsilon then
               if Dist2 (Pivot, Sorted (I)) >= Dist2 (Pivot, Tmp (M)) then
                  Tmp (M) := Sorted (I);
               end if;
            else
               M := M + 1;
               Tmp (M) := Sorted (I);
            end if;
         end if;
      end loop;
      return Tmp (1 .. M);
   end Keep_Farthest_On_Rays;

   function Graham_Scan (Points : Point_Set) return Point_Array is
      N : constant Natural := Points'Length;
   begin
      Require_Nonempty (N);

      declare
         Raw : Point_Array := Dense_Copy (Points);
      begin
         Sort_Lex (Raw);
         declare
            Uniq : constant Point_Array := Dedup_Sorted (Raw);
            U    : constant Natural := Uniq'Length;
         begin
            if U = 1 or else U = 2 then
               return Uniq;
            end if;

            declare
               Work  : Point_Array (1 .. U);
               Pivot : Point;
               Piv_I : Positive;
               Stack : Point_Array (1 .. U);
               Top   : Natural := 0;
               O     : Real;
            begin
               Piv_I := Lowest_Then_Leftmost (Uniq);
               Pivot := Uniq (Piv_I);

               Work (1) := Pivot;
               declare
                  K : Positive := 2;
               begin
                  for I in Uniq'Range loop
                     if I /= Piv_I then
                        Work (K) := Uniq (I);
                        K := K + 1;
                     end if;
                  end loop;
               end;

               Sort_Polar (Work, Pivot);
               declare
                  Rays : constant Point_Array :=
                    Keep_Farthest_On_Rays (Work, Pivot);
                  R    : constant Natural := Rays'Length;
               begin
                  if R = 1 or else R = 2 then
                     return Rays;
                  end if;

                  for I in Rays'Range loop
                     while Top >= 2 loop
                        O := Orient2D
                          (Stack (Top - 1), Stack (Top), Rays (I));
                        exit when O > Epsilon;
                        Top := Top - 1;
                     end loop;
                     Top := Top + 1;
                     Stack (Top) := Rays (I);
                  end loop;

                  if Top < 1 then
                     return Uniq (Uniq'First .. Uniq'First);
                  end if;
                  return Stack (1 .. Top);
               end;
            end;
         end;
      end;
   end Graham_Scan;

   ---------------------------------------------------------------------------
   -- 3. Andrew monotone chain (classroom oracle)
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
            Uniq    : constant Point_Array := Dedup_Sorted (Sort);
            U       : constant Natural := Uniq'Length;
            Lower   : Point_Array (1 .. N);
            Upper   : Point_Array (1 .. N);
            L, Up   : Natural := 0;
            Out_Buf : Point_Array (1 .. N);
            Out_N   : Natural := 0;
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

   ---------------------------------------------------------------------------
   -- 4. Quickhull
   ---------------------------------------------------------------------------

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

   function Quickhull (Points : Point_Set) return Point_Array is
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
            if U = 1 or else U = 2 then
               return Uniq;
            end if;

            declare
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
                        Lo_N := Lo_N + 1;
                        Lower_In (Lo_N) := Uniq (I);
                     elsif O > Epsilon then
                        Up_N := Up_N + 1;
                        Upper_In (Up_N) := Uniq (I);
                     end if;
                  end if;
               end loop;

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
   end Quickhull;

   ---------------------------------------------------------------------------
   -- Unified dispatcher + counts
   ---------------------------------------------------------------------------

   function Convex_Hull
     (Points : Point_Set;
      Method : Hull_Method := Andrew_Method) return Point_Array
   is
   begin
      case Method is
         when Gift_Wrapping_Method =>
            return Gift_Wrapping (Points);
         when Graham_Scan_Method =>
            return Graham_Scan (Points);
         when Andrew_Method =>
            return Andrew_Monotone_Chain (Points);
         when Quickhull_Method =>
            return Quickhull (Points);
      end case;
   end Convex_Hull;

   function Hull_Vertex_Count
     (Points : Point_Set;
      Method : Hull_Method := Andrew_Method) return Point_Count
   is
      H : constant Point_Array := Convex_Hull (Points, Method);
   begin
      return H'Length;
   end Hull_Vertex_Count;

end Convex_Hull_Algorithms;
