--  Gift_Wrapping body — 2D Jarvis march + Andrew monotone-chain teaching oracle.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Gift_Wrapping
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
      --  A before B iff A has smaller polar angle (CCW from +x), or same
      --  ray and A is closer to Pivot than B.
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
   -- Dense copy / lex helpers (shared by Jarvis + Andrew)
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
   -- Jarvis march core
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

   --  True if candidate Q should replace Endpoint as the next hull vertex
   --  from Current for a CCW wrap. Prefer a rightward turn relative to the
   --  current candidate edge (so all points end up left of Current→Next);
   --  on a shared ray keep the farther extreme.
   function Better_Next
     (Current, Endpoint, Q : Point) return Boolean
   is
      O : constant Real := Orient2D (Current, Endpoint, Q);
   begin
      if Near_Point (Endpoint, Current) then
         return not Near_Point (Q, Current);
      end if;
      if O < -Epsilon then
         --  Q is strictly right of Current→Endpoint ⇒ more CCW candidate.
         return True;
      end if;
      if abs (O) <= Epsilon then
         --  Collinear on the ray: keep the farthest extreme vertex.
         return Dist2 (Current, Q) > Dist2 (Current, Endpoint) + Epsilon * Epsilon;
      end if;
      return False;
   end Better_Next;

   function Convex_Hull (Points : Point_Set) return Point_Array is
      N : constant Natural := Points'Length;
   begin
      Require_Nonempty (N);

      declare
         Raw : Point_Array := Dense_Copy (Points);
      begin
         --  Drop near-duplicates via lex sort (stable classroom filter).
         Sort_Lex (Raw);
         declare
            Uniq : constant Point_Array := Dedup_Sorted (Raw);
            U    : constant Natural := Uniq'Length;
         begin
            if U = 1 then
               return Uniq;
            end if;
            if U = 2 then
               return Uniq;
            end if;

            declare
               Hull       : Point_Array (1 .. U);
               H          : Natural := 0;
               Start_I    : constant Positive := Leftmost_Then_Lowest (Uniq);
               Point_On_Hull : Point := Uniq (Start_I);
               Endpoint   : Point;
               Guard      : Natural := 0;
            begin
               --  Jarvis march: wrap until we return to the start.
               loop
                  H := H + 1;
                  Hull (H) := Point_On_Hull;

                  --  Initial candidate: any point other than Point_On_Hull.
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
                  --  Safety: cannot exceed unique-point count of extreme verts.
                  exit when Guard >= U;
               end loop;

               if H < 1 then
                  return Uniq (Uniq'First .. Uniq'First);
               end if;
               return Hull (1 .. H);
            end;
         end;
      end;
   end Convex_Hull;

   function Jarvis_March (Points : Point_Set) return Point_Array is
   begin
      return Convex_Hull (Points);
   end Jarvis_March;

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

end Gift_Wrapping;
