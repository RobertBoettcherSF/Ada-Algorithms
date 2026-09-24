--  Chans_Algorithm body — 2D Chan's algorithm + Graham / Andrew oracles.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Chans_Algorithm
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
   -- Dense copy / lex helpers
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
   -- Andrew monotone chain (oracle + mini-hull primitive)
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

   ---------------------------------------------------------------------------
   -- Graham scan (teaching oracle; also usable as mini-hull)
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

   function Graham_Scan_Hull (Points : Point_Set) return Point_Array is
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
   end Graham_Scan_Hull;

   ---------------------------------------------------------------------------
   -- Jarvis / tangent helpers for Chan wrap
   ---------------------------------------------------------------------------

   --  True if candidate Q should replace Endpoint as the next hull vertex
   --  from Current for a CCW wrap (same predicate as gift wrapping).
   function Better_Next
     (Current, Endpoint, Q : Point) return Boolean
   is
      O : constant Real := Orient2D (Current, Endpoint, Q);
   begin
      if Near_Point (Q, Current) then
         return False;
      end if;
      if Near_Point (Endpoint, Current) then
         return True;
      end if;
      if O < -Epsilon then
         return True;
      end if;
      if abs (O) <= Epsilon then
         return Dist2 (Current, Q) >
                Dist2 (Current, Endpoint) + Epsilon * Epsilon;
      end if;
      return False;
   end Better_Next;

   --  Classroom tangent query on a CCW mini-hull.
   --  Ideal Chan: O(log m) binary search for the supporting vertex.
   --  Here: binary-search-style unimodal walk with a linear fallback for
   --  tiny hulls (m ≤ 8) — correct on classroom sets, simpler to audit.
   function Tangent_On_Hull
     (Current : Point; Hull : Point_Array) return Point
   is
      N : constant Natural := Hull'Length;
   begin
      if N = 0 then
         return Current;
      end if;
      if N = 1 then
         return Hull (Hull'First);
      end if;

      --  Dense 1 .. N view for modular indexing.
      declare
         H : Point_Array (1 .. N);
         K : Positive := 1;
         Best_I : Positive := 1;
      begin
         for V of Hull loop
            H (K) := V;
            K := K + 1;
         end loop;

         if N <= 8 then
            for I in 2 .. N loop
               if Better_Next (Current, H (Best_I), H (I)) then
                  Best_I := I;
               end if;
            end loop;
            return H (Best_I);
         end if;

         --  Binary search for a local maximum of Better_Next on the
         --  circular convex chain (unimodal polar comparison from Current).
         declare
            Lo, Hi, Mid : Natural;
            Prev_I, Next_I : Positive;
            Improved_Left, Improved_Right : Boolean;
         begin
            Lo := 1;
            Hi := N;
            while Lo < Hi loop
               Mid := (Lo + Hi) / 2;
               if Mid < 1 then
                  Mid := 1;
               end if;
               Prev_I := (if Mid = 1 then N else Mid - 1);
               Next_I := (if Mid = N then 1 else Mid + 1);

               Improved_Left :=
                 Better_Next (Current, H (Mid), H (Prev_I));
               Improved_Right :=
                 Better_Next (Current, H (Mid), H (Next_I));

               if not Improved_Left and then not Improved_Right then
                  Best_I := Mid;
                  exit;
               elsif Improved_Right and then not Improved_Left then
                  Lo := Mid + 1;
                  Best_I := Next_I;
               elsif Improved_Left and then not Improved_Right then
                  Hi := Mid;
                  Best_I := Prev_I;
               else
                  --  Ambiguous bitonic region: fall back to linear scan.
                  Best_I := 1;
                  for I in 2 .. N loop
                     if Better_Next (Current, H (Best_I), H (I)) then
                        Best_I := I;
                     end if;
                  end loop;
                  exit;
               end if;
            end loop;

            if Lo = Hi then
               Best_I := Positive'Max (1, Positive'Min (N, Lo));
            end if;

            --  Verify / polish with a short linear pass (classroom safety).
            for I in 1 .. N loop
               if Better_Next (Current, H (Best_I), H (I)) then
                  Best_I := I;
               end if;
            end loop;

            return H (Best_I);
         end;
      end;
   end Tangent_On_Hull;

   --  Squaring guess: H = min(n, 2^(2^t)) for t ≥ 1.
   function Guess_H (T : Positive; N : Positive) return Positive is
      Exp2 : Natural;
      Pow  : Natural;
   begin
      --  Cap early: 2^(2^t) grows double-exponentially past Max_Points.
      if T >= 5 then
         return N;
      end if;
      --  Exp2 := 2^t  (t=1→2, t=2→4, t=3→8, t=4→16).
      Exp2 := 2 ** T;
      if Exp2 >= 10 then
         --  2^10 = 1024 > Max_Points.
         return N;
      end if;
      Pow := 2 ** Exp2;
      if Pow >= Natural (N) then
         return N;
      end if;
      return Positive (Pow);
   end Guess_H;

   --  Mini-hull of a contiguous slice (Andrew embedded; no sibling with).
   function Mini_Hull (Pts : Point_Array) return Point_Array is
   begin
      if Pts'Length = 0 then
         return Pts (1 .. 0);
      end if;
      return Andrew_Monotone_Chain (Pts);
   end Mini_Hull;

   ---------------------------------------------------------------------------
   -- Chan's algorithm core
   ---------------------------------------------------------------------------

   function Convex_Hull (Points : Point_Set) return Point_Array is
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
               Start_I : constant Positive := Lowest_Then_Leftmost (Uniq);
               Start   : constant Point := Uniq (Start_I);
               T       : Positive := 1;
               H_Guess : Positive;
               Success : Boolean;
               Out_Hull : Point_Array (1 .. U);
               Out_N    : Natural;
            begin
               --  Squaring passes until wrap succeeds (H_Guess ≥ h).
               loop
                  H_Guess := Guess_H (T, U);
                  Success := False;
                  Out_N := 0;

                  declare
                     --  Number of groups K = ceil(U / H_Guess).
                     K : constant Positive :=
                       (U + H_Guess - 1) / H_Guess;
                     --  Mini-hull storage: each hull ≤ H_Guess verts.
                     type Hull_Store is
                       array (1 .. K) of Point_Array (1 .. H_Guess);
                     type Hull_Len is array (1 .. K) of Natural;
                     Store : Hull_Store;
                     Lens  : Hull_Len := [others => 0];
                     Lo, Hi : Positive;
                     Slice_N : Natural;
                     Point_On_Hull : Point := Start;
                     Candidate     : Point;
                     Best          : Point;
                     First_Cand    : Boolean;
                  begin
                     --  Phase 1: partition + mini-hulls (Andrew).
                     for G_Idx in 1 .. K loop
                        Lo := (G_Idx - 1) * H_Guess + 1;
                        Hi := Positive'Min (G_Idx * H_Guess, U);
                        Slice_N := Hi - Lo + 1;
                        declare
                           Slice : Point_Array (1 .. Slice_N);
                        begin
                           for I in 0 .. Slice_N - 1 loop
                              Slice (I + 1) := Uniq (Lo + I);
                           end loop;
                           declare
                              MH : constant Point_Array := Mini_Hull (Slice);
                           begin
                              Lens (G_Idx) := MH'Length;
                              for I in MH'Range loop
                                 Store (G_Idx)(I) := MH (I);
                              end loop;
                           end;
                        end;
                     end loop;

                     --  Phase 2: Jarvis wrap with tangent queries, ≤ H steps.
                     Out_N := 1;
                     Out_Hull (1) := Start;
                     Point_On_Hull := Start;

                     for Step in 1 .. H_Guess loop
                        First_Cand := True;
                        Best := Point_On_Hull;

                        for G_Idx in 1 .. K loop
                           if Lens (G_Idx) > 0 then
                              Candidate := Tangent_On_Hull
                                (Point_On_Hull,
                                 Store (G_Idx)(1 .. Lens (G_Idx)));
                              if First_Cand then
                                 Best := Candidate;
                                 First_Cand := False;
                              elsif Better_Next
                                (Point_On_Hull, Best, Candidate)
                              then
                                 Best := Candidate;
                              end if;
                           end if;
                        end loop;

                        if Near_Point (Best, Start) then
                           Success := True;
                           exit;
                        end if;

                        if Near_Point (Best, Point_On_Hull) then
                           --  Degenerate: no progress — treat as failure.
                           exit;
                        end if;

                        Out_N := Out_N + 1;
                        Out_Hull (Out_N) := Best;
                        Point_On_Hull := Best;
                     end loop;
                  end;

                  if Success and then Out_N >= 1 then
                     return Out_Hull (1 .. Out_N);
                  end if;

                  --  H too small (or degenerate): increase guess.
                  exit when H_Guess >= U;
                  T := T + 1;
                  --  Safety bound: double-exp reaches n quickly.
                  exit when T > 8;
               end loop;

               --  Fallback: full Andrew on the unique set (always succeeds).
               return Andrew_Monotone_Chain (Uniq);
            end;
         end;
      end;
   end Convex_Hull;

   function Hull_Vertex_Count (Points : Point_Set) return Point_Count is
      H : constant Point_Array := Convex_Hull (Points);
   begin
      return H'Length;
   end Hull_Vertex_Count;

end Chans_Algorithm;
