pragma Ada_2022;
--  Own tests for Bowyer_Watson (see tests/SOURCES.txt).
--  Delaunay triangulation of random points in general position, checked against own geometry:
--  each triangle is non-degenerate with vertex indices in range; no input point lies strictly inside
--  any triangle's circumcircle (own determinant in Long_Float); the triangle count is 2n - 2 - h and
--  the total area equals the convex-hull area, with h and the hull from an own monotone-chain hull.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Bowyer_Watson; use Bowyer_Watson;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   type LF is new Long_Float;
   function Cross (O, A, B : Point) return LF is
     ((LF (A.X) - LF (O.X)) * (LF (B.Y) - LF (O.Y)) - (LF (A.Y) - LF (O.Y)) * (LF (B.X) - LF (O.X)));
   function In_Circle (A, B, C, D : Point) return LF is   --  > 0 when D is inside the circle of CCW A, B, C
      Ax : constant LF := LF (A.X) - LF (D.X); Ay : constant LF := LF (A.Y) - LF (D.Y);
      Bx : constant LF := LF (B.X) - LF (D.X); By : constant LF := LF (B.Y) - LF (D.Y);
      Cx : constant LF := LF (C.X) - LF (D.X); Cy : constant LF := LF (C.Y) - LF (D.Y);
   begin
      return (Ax * Ax + Ay * Ay) * (Bx * Cy - Cx * By) - (Bx * Bx + By * By) * (Ax * Cy - Cx * Ay)
             + (Cx * Cx + Cy * Cy) * (Ax * By - Bx * Ay);
   end In_Circle;
begin
   for Run in 1 .. 1500 loop
      declare
         N : constant Positive := Next (3, 40);
         P : Point_Array (1 .. N);
         S : Point_Array (1 .. N);
         Hull : array (1 .. 2 * N) of Point;
         H : Natural := 0;
         T : Triangulation;
         Tmp : Point;
         J : Integer;
         Hull_Area, Tri_Area, D : LF := 0.0;
         Ok : Boolean := True;
      begin
         for I in 1 .. N loop P (I) := (Real (Next (0, 1_000_000)) / 1000.0, Real (Next (0, 1_000_000)) / 1000.0); end loop;
         S := P;
         for I in 2 .. N loop   --  sort by (X, Y)
            Tmp := S (I); J := I - 1;
            while J >= 1 and then (S (J).X > Tmp.X or else (S (J).X = Tmp.X and then S (J).Y > Tmp.Y)) loop
               S (J + 1) := S (J); J := J - 1;
            end loop;
            S (J + 1) := Tmp;
         end loop;
         for I in 1 .. N loop   --  lower hull
            while H >= 2 and then Cross (Hull (H - 1), Hull (H), S (I)) <= 0.0 loop H := H - 1; end loop;
            H := H + 1; Hull (H) := S (I);
         end loop;
         declare L : constant Natural := H + 1; begin
            for I in reverse 1 .. N - 1 loop   --  upper hull
               while H >= L and then Cross (Hull (H - 1), Hull (H), S (I)) <= 0.0 loop H := H - 1; end loop;
               H := H + 1; Hull (H) := S (I);
            end loop;
         end;
         H := H - 1;   --  last point repeats the first
         for I in 1 .. H loop Hull_Area := Hull_Area + Cross (Hull (1), Hull (I), Hull (I mod H + 1)); end loop;
         Hull_Area := Hull_Area / 2.0;
         if Hull_Area > 1.0 then   --  skip near-collinear sets
            T := Triangulate (P);
            for K in 1 .. T.Count loop
               declare
                  X : constant Triangle := T.Tris (K);
               begin
                  if X.A > N or else X.B > N or else X.C > N then Ok := False;
                  else
                     D := Cross (P (X.A), P (X.B), P (X.C));
                     if abs D < 1.0E-9 then Ok := False; end if;
                     Tri_Area := Tri_Area + abs D / 2.0;
                     for I in 1 .. N loop
                        if I /= X.A and then I /= X.B and then I /= X.C then
                           if (if D > 0.0 then In_Circle (P (X.A), P (X.B), P (X.C), P (I))
                               else In_Circle (P (X.A), P (X.C), P (X.B), P (I))) > 1.0E-3 then
                              Ok := False;
                           end if;
                        end if;
                     end loop;
                  end if;
               end;
            end loop;
            Report (Ok, "triangles invalid or not Delaunay, run" & Run'Image & " N =" & N'Image);
            Report (T.Count = 2 * N - 2 - H and then Triangle_Count_Of (T) = T.Count,
                    "triangle count" & T.Count'Image & ", expected 2n - 2 - h =" & Integer'Image (2 * N - 2 - H)
                    & ", run" & Run'Image);
            Report (abs (Tri_Area - Hull_Area) <= 1.0E-6 * Hull_Area,
                    "triangle area" & Tri_Area'Image & " /= hull area" & Hull_Area'Image & ", run" & Run'Image);
         end if;
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
