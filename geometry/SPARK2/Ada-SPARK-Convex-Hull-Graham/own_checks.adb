--  Own tests for Convex_Hull_Graham (see tests/SOURCES.txt).
--  Points are prepared as Scan expects them (pivot = lowest, then leftmost point first; the rest
--  sorted counter-clockwise by angle around it, nearer first on ties); the hull must equal an own
--  monotone-chain hull (strict: no collinear points) as a cyclic sequence, counter-clockwise.
with Ada.Text_IO; use Ada.Text_IO;
with Convex_Hull_Graham; use Convex_Hull_Graham;

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
   function Dist2 (A, B : Point) return Long_Long_Integer is
     (Long_Long_Integer (A.X - B.X) ** 2 + Long_Long_Integer (A.Y - B.Y) ** 2);

   type Pts is array (Positive range <>) of Point;

   --  own reference: Andrew's monotone chain, strict turns, counter-clockwise
   function Monotone (P_In : Pts) return Pts is
      P : Pts := P_In;
      H : Pts (1 .. 2 * P_In'Length + 1) := [others => (0, 0)];
      K : Natural := 0;
      T : Point;
      J : Integer;
   begin
      for I in P'First + 1 .. P'Last loop   --  insertion sort by (X, Y)
         T := P (I); J := I - 1;
         while J >= P'First and then (P (J).X > T.X or else (P (J).X = T.X and then P (J).Y > T.Y)) loop
            P (J + 1) := P (J); J := J - 1;
         end loop;
         P (J + 1) := T;
      end loop;
      if P'Length = 1 then return P; end if;
      for I in P'Range loop   --  lower chain
         while K >= 2 and then Cross (H (K - 1), H (K), P (I)) <= 0 loop K := K - 1; end loop;
         K := K + 1; H (K) := P (I);
      end loop;
      declare
         Lower : constant Natural := K + 1;
      begin
         for I in reverse P'First .. P'Last - 1 loop   --  upper chain
            while K >= Lower and then Cross (H (K - 1), H (K), P (I)) <= 0 loop K := K - 1; end loop;
            K := K + 1; H (K) := P (I);
         end loop;
      end;
      return H (1 .. K - 1);   --  last point repeats the first
   end Monotone;

   function Same_Cycle (A, B : Pts) return Boolean is
   begin
      if A'Length /= B'Length then return False; end if;
      for Shift in 0 .. A'Length - 1 loop
         declare
            Ok : Boolean := True;
         begin
            for I in 0 .. A'Length - 1 loop
               if A (A'First + I) /= B (B'First + (I + Shift) mod B'Length) then Ok := False; exit; end if;
            end loop;
            if Ok then return True; end if;
         end;
      end loop;
      return False;
   end Same_Cycle;

   procedure Check (Raw : Pts; Label : String) is
      P : Pts := Raw;
      Input : Point_Array := [others => (0, 0)];
      Hull : Point_Array;
      HC : Hull_Length;
      Piv : Positive := P'First;
      T : Point;
      J : Integer;
   begin
      for I in P'Range loop   --  pivot: lowest, then leftmost
         if P (I).Y < P (Piv).Y or else (P (I).Y = P (Piv).Y and then P (I).X < P (Piv).X) then Piv := I; end if;
      end loop;
      T := P (P'First); P (P'First) := P (Piv); P (Piv) := T;
      for I in P'First + 2 .. P'Last loop   --  insertion sort by angle around the pivot, nearer first
         T := P (I); J := I - 1;
         while J > P'First and then
           (Cross (P (P'First), P (J), T) < 0
            or else (Cross (P (P'First), P (J), T) = 0 and then Dist2 (P (P'First), P (J)) > Dist2 (P (P'First), T)))
         loop
            P (J + 1) := P (J); J := J - 1;
         end loop;
         P (J + 1) := T;
      end loop;
      for I in P'Range loop Input (I - P'First + 1) := P (I); end loop;
      Scan (Input, P'Length, Hull, HC);
      declare
         Ref : constant Pts := Monotone (Raw);
      begin
         Report (Same_Cycle (Pts (Hull (1 .. HC)), Ref) and then (HC = 0 or else Hull (1) = P (P'First)), Label);
      end;
   end Check;
begin
   for Trial in 1 .. 20_000 loop
      declare
         N : constant Positive := Next (1, Max_Points);
         Span : constant Integer := (if Trial mod 3 = 0 then 3 else 100);   --  small span: many collinear points
         Raw : Pts (1 .. N);
         Fresh : Boolean;
      begin
         for I in Raw'Range loop
            loop   --  distinct points
               Raw (I) := (Next (-Span, Span), Next (-Span, Span));
               Fresh := True;
               for J in 1 .. I - 1 loop
                  if Raw (J) = Raw (I) then Fresh := False; end if;
               end loop;
               exit when Fresh;
            end loop;
         end loop;
         Check (Raw, "random set" & Integer'Image (Trial));
      end;
   end loop;
   --  all points on one line, and the coordinate extremes
   Check ([(0, 0), (1, 1), (2, 2), (3, 3)], "collinear diagonal");
   Check ([(5, 0), (1, 0), (3, 0)], "collinear horizontal");
   Check ([(-100, -100), (100, -100), (100, 100), (-100, 100), (0, 0)], "extreme square");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
