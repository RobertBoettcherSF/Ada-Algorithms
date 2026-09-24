--  Kirkpatrick–Seidel body — 2D marriage-before-conquest hull + Andrew oracle.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Kirkpatrick_Seidel
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

   procedure Require_Bridge_Sets (Ln, Rn : Natural) is
   begin
      if Ln < 1 or else Rn < 1
        or else Ln > Max_Points or else Rn > Max_Points
      then
         raise Invalid_Argument;
      end if;
   end Require_Bridge_Sets;

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

   function X_Less (A, B : Point) return Boolean is
   begin
      if abs (A.X - B.X) > Epsilon then
         return A.X < B.X;
      end if;
      return A.Y < B.Y - Epsilon;
   end X_Less;

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

   procedure Sort_By_X (A : in out Point_Array) is
      J   : Natural;
      Key : Point;
   begin
      for I in A'First + 1 .. A'Last loop
         Key := A (I);
         J := I - 1;
         while J >= A'First and then X_Less (Key, A (J)) loop
            A (J + 1) := A (J);
            J := J - 1;
            exit when J < A'First;
         end loop;
         A (J + 1) := Key;
      end loop;
   end Sort_By_X;

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

   --  Drop intermediate collinear / reflex vertices on an L→R upper chain
   --  (keep strict right turns: Orient2D < −ε).
   function Clean_Upper_Chain (Chain : Point_Array) return Point_Array is
      N : constant Natural := Chain'Length;
      Tmp : Point_Array (1 .. N);
      M : Natural := 0;
   begin
      if N <= 2 then
         return Chain;
      end if;
      for I in Chain'Range loop
         Tmp (M + 1) := Chain (I);
         M := M + 1;
         while M >= 3 and then
           Orient2D (Tmp (M - 2), Tmp (M - 1), Tmp (M)) >= -Epsilon
         loop
            Tmp (M - 1) := Tmp (M);
            M := M - 1;
         end loop;
      end loop;
      return Tmp (1 .. M);
   end Clean_Upper_Chain;

   --  Drop intermediate collinear on an L→R lower chain (keep strict left
   --  turns: Orient2D > ε).
   function Clean_Lower_Chain (Chain : Point_Array) return Point_Array is
      N : constant Natural := Chain'Length;
      Tmp : Point_Array (1 .. N);
      M : Natural := 0;
   begin
      if N <= 2 then
         return Chain;
      end if;
      for I in Chain'Range loop
         Tmp (M + 1) := Chain (I);
         M := M + 1;
         while M >= 3 and then
           Orient2D (Tmp (M - 2), Tmp (M - 1), Tmp (M)) <= Epsilon
         loop
            Tmp (M - 1) := Tmp (M);
            M := M - 1;
         end loop;
      end loop;
      return Tmp (1 .. M);
   end Clean_Lower_Chain;

   ---------------------------------------------------------------------------
   -- Bridge finding (educational brute-force supporting line)
   ---------------------------------------------------------------------------

   function Upper_Bridge
     (Left_Set, Right_Set : Point_Set) return Bridge_Edge
   is
      Ln : constant Natural := Left_Set'Length;
      Rn : constant Natural := Right_Set'Length;
   begin
      Require_Bridge_Sets (Ln, Rn);

      declare
         L  : constant Point_Array := Dense_Copy (Left_Set);
         R  : constant Point_Array := Dense_Copy (Right_Set);
         Best_L, Best_R : Point;
         Found : Boolean := False;
         Ok    : Boolean;
         O     : Real;
      begin
         for I in L'Range loop
            for J in R'Range loop
               if not Near_Point (L (I), R (J)) then
                  Ok := True;
                  for K in L'Range loop
                     if not Near_Point (L (K), L (I)) then
                        O := Orient2D (L (I), R (J), L (K));
                        if O > Epsilon then
                           Ok := False;
                           exit;
                        end if;
                     end if;
                  end loop;
                  if Ok then
                     for K in R'Range loop
                        if not Near_Point (R (K), R (J)) then
                           O := Orient2D (L (I), R (J), R (K));
                           if O > Epsilon then
                              Ok := False;
                              exit;
                           end if;
                        end if;
                     end loop;
                  end if;
                  if Ok then
                     if not Found
                       or else L (I).X > Best_L.X + Epsilon
                       or else (Near (L (I).X, Best_L.X)
                                and then L (I).Y > Best_L.Y + Epsilon)
                       or else (Near_Point (L (I), Best_L)
                                and then (R (J).X < Best_R.X - Epsilon
                                          or else (Near (R (J).X, Best_R.X)
                                                   and then
                                                   R (J).Y > Best_R.Y
                                                   + Epsilon)))
                     then
                        Best_L := L (I);
                        Best_R := R (J);
                        Found := True;
                     end if;
                  end if;
               end if;
            end loop;
         end loop;

         if not Found then
            Best_L := L (L'First);
            for I in L'Range loop
               if L (I).Y > Best_L.Y + Epsilon
                 or else (Near (L (I).Y, Best_L.Y)
                          and then L (I).X > Best_L.X + Epsilon)
               then
                  Best_L := L (I);
               end if;
            end loop;
            Best_R := R (R'First);
            for J in R'Range loop
               if R (J).Y > Best_R.Y + Epsilon
                 or else (Near (R (J).Y, Best_R.Y)
                          and then R (J).X < Best_R.X - Epsilon)
               then
                  Best_R := R (J);
               end if;
            end loop;
         end if;

         return (Left => Best_L, Right => Best_R);
      end;
   end Upper_Bridge;

   function Lower_Bridge
     (Left_Set, Right_Set : Point_Set) return Bridge_Edge
   is
      Ln : constant Natural := Left_Set'Length;
      Rn : constant Natural := Right_Set'Length;
   begin
      Require_Bridge_Sets (Ln, Rn);

      declare
         L  : constant Point_Array := Dense_Copy (Left_Set);
         R  : constant Point_Array := Dense_Copy (Right_Set);
         Best_L, Best_R : Point;
         Found : Boolean := False;
         Ok    : Boolean;
         O     : Real;
      begin
         for I in L'Range loop
            for J in R'Range loop
               if not Near_Point (L (I), R (J)) then
                  Ok := True;
                  for K in L'Range loop
                     if not Near_Point (L (K), L (I)) then
                        O := Orient2D (L (I), R (J), L (K));
                        if O < -Epsilon then
                           Ok := False;
                           exit;
                        end if;
                     end if;
                  end loop;
                  if Ok then
                     for K in R'Range loop
                        if not Near_Point (R (K), R (J)) then
                           O := Orient2D (L (I), R (J), R (K));
                           if O < -Epsilon then
                              Ok := False;
                              exit;
                           end if;
                        end if;
                     end loop;
                  end if;
                  if Ok then
                     if not Found
                       or else L (I).X > Best_L.X + Epsilon
                       or else (Near (L (I).X, Best_L.X)
                                and then L (I).Y < Best_L.Y - Epsilon)
                       or else (Near_Point (L (I), Best_L)
                                and then (R (J).X < Best_R.X - Epsilon
                                          or else (Near (R (J).X, Best_R.X)
                                                   and then
                                                   R (J).Y < Best_R.Y
                                                   - Epsilon)))
                     then
                        Best_L := L (I);
                        Best_R := R (J);
                        Found := True;
                     end if;
                  end if;
               end if;
            end loop;
         end loop;

         if not Found then
            Best_L := L (L'First);
            for I in L'Range loop
               if L (I).Y < Best_L.Y - Epsilon
                 or else (Near (L (I).Y, Best_L.Y)
                          and then L (I).X > Best_L.X + Epsilon)
               then
                  Best_L := L (I);
               end if;
            end loop;
            Best_R := R (R'First);
            for J in R'Range loop
               if R (J).Y < Best_R.Y - Epsilon
                 or else (Near (R (J).Y, Best_R.Y)
                          and then R (J).X < Best_R.X - Epsilon)
               then
                  Best_R := R (J);
               end if;
            end loop;
         end if;

         return (Left => Best_L, Right => Best_R);
      end;
   end Lower_Bridge;

   ---------------------------------------------------------------------------
   -- Upper / lower hull (marriage-before-conquest recursion)
   ---------------------------------------------------------------------------

   function Upper_Hull (Pts : Point_Array) return Point_Array;
   function Lower_Hull (Pts : Point_Array) return Point_Array;

   function Upper_Hull (Pts : Point_Array) return Point_Array is
      N : constant Natural := Pts'Length;
   begin
      if N = 0 then
         return Pts (1 .. 0);
      end if;
      if N = 1 then
         return Pts;
      end if;

      declare
         Sort : Point_Array := Pts;
      begin
         Sort_By_X (Sort);

         if N = 2 then
            return Sort;
         end if;

         --  All x nearly equal: upper hull is the topmost point.
         if Near (Sort (Sort'First).X, Sort (Sort'Last).X) then
            declare
               Hi : Point := Sort (Sort'First);
            begin
               for I in Sort'Range loop
                  if Sort (I).Y > Hi.Y + Epsilon then
                     Hi := Sort (I);
                  end if;
               end loop;
               return Point_Array'(1 => Hi);
            end;
         end if;

         declare
            Mid : constant Natural := (N + 1) / 2;
            L   : constant Point_Array := Sort (1 .. Mid);
            R   : constant Point_Array := Sort (Mid + 1 .. N);
            Br  : constant Bridge_Edge := Upper_Bridge (L, R);
            L_Keep : Point_Array (1 .. Mid);
            R_Keep : Point_Array (1 .. N - Mid);
            Ln, Rn : Natural := 0;
         begin
            for I in L'Range loop
               if L (I).X < Br.Left.X - Epsilon
                 or else Near_Point (L (I), Br.Left)
               then
                  Ln := Ln + 1;
                  L_Keep (Ln) := L (I);
               end if;
            end loop;
            declare
               Has : Boolean := False;
            begin
               for I in 1 .. Ln loop
                  if Near_Point (L_Keep (I), Br.Left) then
                     Has := True;
                     exit;
                  end if;
               end loop;
               if not Has then
                  Ln := Ln + 1;
                  L_Keep (Ln) := Br.Left;
               end if;
            end;

            for I in R'Range loop
               if R (I).X > Br.Right.X + Epsilon
                 or else Near_Point (R (I), Br.Right)
               then
                  Rn := Rn + 1;
                  R_Keep (Rn) := R (I);
               end if;
            end loop;
            declare
               Has : Boolean := False;
            begin
               for I in 1 .. Rn loop
                  if Near_Point (R_Keep (I), Br.Right) then
                     Has := True;
                     exit;
                  end if;
               end loop;
               if not Has then
                  Rn := Rn + 1;
                  R_Keep (Rn) := Br.Right;
               end if;
            end;

            declare
               LH : constant Point_Array := Upper_Hull (L_Keep (1 .. Ln));
               RH : constant Point_Array := Upper_Hull (R_Keep (1 .. Rn));
               K  : Natural := 0;
               Raw : Point_Array (1 .. N);
            begin
               for I in LH'Range loop
                  K := K + 1;
                  Raw (K) := LH (I);
               end loop;
               for I in RH'Range loop
                  if K = 0 or else not Near_Point (Raw (K), RH (I)) then
                     K := K + 1;
                     Raw (K) := RH (I);
                  end if;
               end loop;
               if K = 0 then
                  return Point_Array'(1 => Br.Left);
               end if;
               return Clean_Upper_Chain (Raw (1 .. K));
            end;
         end;
      end;
   end Upper_Hull;

   function Lower_Hull (Pts : Point_Array) return Point_Array is
      N : constant Natural := Pts'Length;
   begin
      if N = 0 then
         return Pts (1 .. 0);
      end if;
      if N = 1 then
         return Pts;
      end if;

      declare
         Sort : Point_Array := Pts;
      begin
         Sort_By_X (Sort);

         if N = 2 then
            return Sort;
         end if;

         if Near (Sort (Sort'First).X, Sort (Sort'Last).X) then
            declare
               Lo : Point := Sort (Sort'First);
            begin
               for I in Sort'Range loop
                  if Sort (I).Y < Lo.Y - Epsilon then
                     Lo := Sort (I);
                  end if;
               end loop;
               return Point_Array'(1 => Lo);
            end;
         end if;

         declare
            Mid : constant Natural := (N + 1) / 2;
            L   : constant Point_Array := Sort (1 .. Mid);
            R   : constant Point_Array := Sort (Mid + 1 .. N);
            Br  : constant Bridge_Edge := Lower_Bridge (L, R);
            L_Keep : Point_Array (1 .. Mid);
            R_Keep : Point_Array (1 .. N - Mid);
            Ln, Rn : Natural := 0;
         begin
            for I in L'Range loop
               if L (I).X < Br.Left.X - Epsilon
                 or else Near_Point (L (I), Br.Left)
               then
                  Ln := Ln + 1;
                  L_Keep (Ln) := L (I);
               end if;
            end loop;
            declare
               Has : Boolean := False;
            begin
               for I in 1 .. Ln loop
                  if Near_Point (L_Keep (I), Br.Left) then
                     Has := True;
                     exit;
                  end if;
               end loop;
               if not Has then
                  Ln := Ln + 1;
                  L_Keep (Ln) := Br.Left;
               end if;
            end;

            for I in R'Range loop
               if R (I).X > Br.Right.X + Epsilon
                 or else Near_Point (R (I), Br.Right)
               then
                  Rn := Rn + 1;
                  R_Keep (Rn) := R (I);
               end if;
            end loop;
            declare
               Has : Boolean := False;
            begin
               for I in 1 .. Rn loop
                  if Near_Point (R_Keep (I), Br.Right) then
                     Has := True;
                     exit;
                  end if;
               end loop;
               if not Has then
                  Rn := Rn + 1;
                  R_Keep (Rn) := Br.Right;
               end if;
            end;

            declare
               LH : constant Point_Array := Lower_Hull (L_Keep (1 .. Ln));
               RH : constant Point_Array := Lower_Hull (R_Keep (1 .. Rn));
               K  : Natural := 0;
               Raw : Point_Array (1 .. N);
            begin
               for I in LH'Range loop
                  K := K + 1;
                  Raw (K) := LH (I);
               end loop;
               for I in RH'Range loop
                  if K = 0 or else not Near_Point (Raw (K), RH (I)) then
                     K := K + 1;
                     Raw (K) := RH (I);
                  end if;
               end loop;
               if K = 0 then
                  return Point_Array'(1 => Br.Left);
               end if;
               return Clean_Lower_Chain (Raw (1 .. K));
            end;
         end;
      end;
   end Lower_Hull;

   ---------------------------------------------------------------------------
   -- Convex_Hull — assemble lower + upper into CCW open ring
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
         begin
            if U = 1 then
               return Uniq;
            end if;
            if U = 2 then
               return Uniq;
            end if;

            declare
               Up : constant Point_Array := Upper_Hull (Uniq);
               Lo : constant Point_Array := Lower_Hull (Uniq);
               Out_Buf : Point_Array (1 .. U);
               Out_N : Natural := 0;
            begin
               --  CCW: leftmost → lower arc (L→R) → upper arc reversed (R→L).
               for I in Lo'Range loop
                  Out_N := Out_N + 1;
                  Out_Buf (Out_N) := Lo (I);
               end loop;

               for I in reverse Up'Range loop
                  if Out_N = 0
                    or else not Near_Point (Out_Buf (Out_N), Up (I))
                  then
                     if Out_N > 0
                       and then Near_Point (Out_Buf (1), Up (I))
                     then
                        null;  --  omit closing vertex (open ring)
                     else
                        Out_N := Out_N + 1;
                        Out_Buf (Out_N) := Up (I);
                     end if;
                  end if;
               end loop;

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

end Kirkpatrick_Seidel;
