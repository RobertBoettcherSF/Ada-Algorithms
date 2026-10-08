--  Own tests for Point_In_Polygon (see tests/SOURCES.txt).
--  For simple polygons and query points off the boundary, Contains must agree with an own
--  winding-number reference (non-zero winding = inside); polygons with fewer than 3 vertices
--  have no interior.
with Ada.Text_IO; use Ada.Text_IO;
with Point_In_Polygon; use Point_In_Polygon;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
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
   function Cross (O, A, B : Point) return Long_Long_Integer is
     (Long_Long_Integer (A.X - O.X) * Long_Long_Integer (B.Y - O.Y)
      - Long_Long_Integer (A.Y - O.Y) * Long_Long_Integer (B.X - O.X));

   function On_Segment (A, B, Q : Point) return Boolean is
     (Cross (A, B, Q) = 0
      and then Q.X in Integer'Min (A.X, B.X) .. Integer'Max (A.X, B.X)
      and then Q.Y in Integer'Min (A.Y, B.Y) .. Integer'Max (A.Y, B.Y));

   function Sign (V : Long_Long_Integer) return Integer is (if V > 0 then 1 elsif V < 0 then -1 else 0);

   function Segments_Meet (A, B, C, D : Point) return Boolean is
      D1 : constant Integer := Sign (Cross (A, B, C));
      D2 : constant Integer := Sign (Cross (A, B, D));
      D3 : constant Integer := Sign (Cross (C, D, A));
      D4 : constant Integer := Sign (Cross (C, D, B));
   begin
      return (D1 * D2 < 0 and then D3 * D4 < 0)
        or else On_Segment (A, B, C) or else On_Segment (A, B, D)
        or else On_Segment (C, D, A) or else On_Segment (C, D, B);
   end Segments_Meet;

   function Next_V (I, N : Index) return Index is (if I = N then 1 else I + 1);

   function Winding (S : Polygon; N : Point_In_Polygon.Count; Q : Point) return Integer is
      W : Integer := 0;
   begin
      for I in 1 .. N loop
         declare
            A : constant Point := S (I);
            B : constant Point := S (Next_V (I, N));
         begin
            if A.Y <= Q.Y then
               if B.Y > Q.Y and then Cross (A, B, Q) > 0 then W := W + 1; end if;
            elsif B.Y <= Q.Y and then Cross (A, B, Q) < 0 then
               W := W - 1;
            end if;
         end;
      end loop;
      return W;
   end Winding;

   function Simple (S : Polygon; N : Point_In_Polygon.Count) return Boolean is
      Area2 : Long_Long_Integer := 0;
   begin
      for I in 1 .. N loop
         Area2 := Area2 + Cross ((0, 0), S (I), S (Next_V (I, N)));
         for J in 1 .. N loop   --  non-adjacent edges must not meet
            if I /= J and then Next_V (I, N) /= J and then Next_V (J, N) /= I
              and then Segments_Meet (S (I), S (Next_V (I, N)), S (J), S (Next_V (J, N)))
            then
               return False;
            end if;
         end loop;
         if S (I) = S (Next_V (I, N)) then return False; end if;
      end loop;
      return Area2 /= 0;
   end Simple;

   S : Polygon;
   Polygons : Natural := 0;
begin
   while Polygons < 4_000 loop
      declare
         N : constant Point_In_Polygon.Count := (if Polygons mod 2 = 0 then 3 else 4);
         Span : constant Integer := (if Polygons mod 4 < 2 then 6 else 100);
      begin
         S := [others => (0, 0)];
         for I in 1 .. N loop
            S (I) := (Next (-Span, Span), Next (-Span, Span));
         end loop;
         if Simple (S, N) then
            Polygons := Polygons + 1;
            for Q_Trial in 1 .. 60 loop
               declare
                  Q : constant Point := (Next (Integer'Max (-100, -Span - 1), Integer'Min (100, Span + 1)),
                                          Next (Integer'Max (-100, -Span - 1), Integer'Min (100, Span + 1)));
                  Boundary : Boolean := False;
               begin
                  for I in 1 .. N loop
                     if On_Segment (S (I), S (Next_V (I, N)), Q) then Boundary := True; end if;
                  end loop;
                  if not Boundary then
                     Report (Contains (S, N, Q) = (Winding (S, N, Q) /= 0), "polygon query");
                  end if;
               end;
            end loop;
         end if;
      end;
   end loop;
   --  fewer than three vertices: no interior
   for Trial in 1 .. 2_000 loop
      S := [others => (Next (-100, 100), Next (-100, 100))];
      S (2) := (Next (-100, 100), Next (-100, 100));
      Report (not Contains (S, 1, (Next (-100, 100), Next (-100, 100)))
              and then not Contains (S, 2, (Next (-100, 100), Next (-100, 100))), "degenerate");
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
