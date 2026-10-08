--  Own checks (see tests/SOURCES.txt). Assume Liang_Barsky is wrong or does
--  nothing; compare it with a reference that uses a different method: the
--  segment is sampled at 4,001 evenly spaced parameters and each sample is
--  tested against the window with exact coordinate comparisons; the first
--  and last inside samples bound the expected clipped piece. Seeded random
--  segments with integer and half-integer endpoints (many cross, touch or
--  run along the window edges) against random integer windows.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Liang_Barsky; use Liang_Barsky;

procedure Own_Checks is
   Samples : constant := 4_000;
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
   Checked, Accepted : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   function Inside (X, Y : Long_Float; W : Clip_Window) return Boolean is
     (X >= Long_Float (W.X_Min) and then X <= Long_Float (W.X_Max)
      and then Y >= Long_Float (W.Y_Min) and then Y <= Long_Float (W.Y_Max));

   procedure Fail (What : String; S : Segment; W : Clip_Window) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " for segment ("
        & S.P0.X'Image & S.P0.Y'Image & ") - (" & S.P1.X'Image & S.P1.Y'Image & "), window"
        & W.X_Min'Image & W.Y_Min'Image & W.X_Max'Image & W.Y_Max'Image);
      raise Program_Error;
   end Fail;

   --  helpers against their definitions
   procedure Check_Helpers is
      W : constant Clip_Window := Make_Window (-2.0, -1.0, 3.0, 4.0);
      E2 : constant Real := 2.0 * Epsilon;
      function Raises (X0, Y0, X1, Y1 : Real) return Boolean is
         V : Clip_Window;
      begin
         V := Make_Window (X0, Y0, X1, Y1);
         return V.X_Min > V.X_Max;   --  never: the call must raise
      exception
         when others => return True;
      end Raises;
      procedure Expect (Cond : Boolean; What : String) is
      begin
         if not Cond then
            Ada.Text_IO.Put_Line ("FAIL own check: " & What);
            raise Program_Error;
         end if;
      end Expect;
   begin
      --  boundary is inside (inclusive, within Epsilon); 2 * Epsilon beyond is outside
      for I in -4 .. 6 loop
         declare
            T : constant Real := Real (I) / 2.0;
         begin
            Expect (Point_Inside_Window ((-2.0, T), W) = (T >= -1.0 and then T <= 4.0), "Point_Inside_Window left edge");
            Expect (Point_Inside_Window ((3.0, T), W) = (T >= -1.0 and then T <= 4.0), "Point_Inside_Window right edge");
            Expect (Point_Inside_Window ((T, -1.0), W) = (T >= -2.0 and then T <= 3.0), "Point_Inside_Window bottom edge");
            Expect (Point_Inside_Window ((T, 4.0), W) = (T >= -2.0 and then T <= 3.0), "Point_Inside_Window top edge");
         end;
      end loop;
      Expect (not Point_Inside_Window ((-2.0 - E2, 0.0), W) and then not Point_Inside_Window ((3.0 + E2, 0.0), W)
              and then not Point_Inside_Window ((0.0, -1.0 - E2), W) and then not Point_Inside_Window ((0.0, 4.0 + E2), W),
              "Point_Inside_Window just outside");
      Expect (Point_Inside_Window ((-2.0 - Epsilon / 2.0, 0.0), W) and then Point_Inside_Window ((3.0 + Epsilon / 2.0, 0.0), W)
              and then Point_Inside_Window ((0.0, -1.0 - Epsilon / 2.0), W) and then Point_Inside_Window ((0.0, 4.0 + Epsilon / 2.0), W),
              "Point_Inside_Window within Epsilon");
      --  exactly Epsilon away still counts, as in Near (abs (A - B) <= Tol)
      Expect (Point_Inside_Window ((W.X_Min - Epsilon, 0.0), W) and then Point_Inside_Window ((W.X_Max + Epsilon, 0.0), W)
              and then Point_Inside_Window ((0.0, W.Y_Min - Epsilon), W) and then Point_Inside_Window ((0.0, W.Y_Max + Epsilon), W),
              "Point_Inside_Window at exactly Epsilon");
      --  windows need positive width and height
      Expect (Raises (0.0, 0.0, 0.0, 1.0) and then Raises (0.0, 0.0, 1.0, 0.0) and then Raises (1.0, 0.0, 0.0, 1.0)
              and then Raises (0.0, 1.0, 1.0, 0.0), "Make_Window accepts an empty window");
      Expect (not Is_Valid_Window ((0.0, 0.0, 1.0, 0.0)) and then not Is_Valid_Window ((0.0, 0.0, 0.0, 1.0))
              and then Is_Valid_Window ((0.0, 0.0, 1.0, 1.0)), "Is_Valid_Window");
      --  vector arithmetic, Near, Length
      for I in 1 .. 200 loop
         declare
            A : constant Vec2 := (Real (Rand (-9, 9)) / 4.0, Real (Rand (-9, 9)) / 4.0);
            B : constant Vec2 := (Real (Rand (-9, 9)) / 4.0, Real (Rand (-9, 9)) / 4.0);
            K : constant Real := Real (Rand (-9, 9)) / 2.0;
            L : constant Long_Float := Long_Float (A.X - B.X) ** 2 + Long_Float (A.Y - B.Y) ** 2;
         begin
            Expect (A + B = (A.X + B.X, A.Y + B.Y) and then A - B = (A.X - B.X, A.Y - B.Y)
                    and then K * A = (K * A.X, K * A.Y) and then Dot (A, B) = A.X * B.X + A.Y * B.Y,
                    "vector operators");
            Expect (abs (Long_Float (Length (Make_Segment (A, B))) ** 2 - L) <= 1.0E-3 * (1.0 + L), "Length");
            Expect (Near_Point (A, (A.X + Epsilon / 2.0, A.Y)) and then not Near_Point (A, (A.X, A.Y + E2))
                    and then not Near_Point (A, (A.X + E2, A.Y)), "Near_Point");
            Expect (Same_Clipped_Segment ((A, B), (B, A)) and then Same_Clipped_Segment ((A, B), (A, B))
                    and then (Same_Clipped_Segment ((A, B), (A, A)) = (A = B))
                    and then (Same_Clipped_Segment ((A, B), (B, B)) = (A = B)),
                    "Same_Clipped_Segment (undirected endpoints)");
         end;
      end loop;
      Expect (Near (1.0, 1.0 + Epsilon / 2.0) and then not Near (1.0, 1.0 + E2) and then Near (0.0, 0.0, 0.0),
              "Near");
   end Check_Helpers;
begin
   Check_Helpers;
   for Round in 1 .. 20_000 loop
      declare
         X0 : constant Integer := Rand (-5, 5);
         Y0 : constant Integer := Rand (-5, 5);
         W  : constant Clip_Window :=
           Make_Window (Real (X0), Real (Y0), Real (X0 + Rand (1, 6)), Real (Y0 + Rand (1, 6)));
         S  : constant Segment :=
           ((Real (Rand (-20, 20)) / 2.0, Real (Rand (-20, 20)) / 2.0),
            (Real (Rand (-20, 20)) / 2.0, Real (Rand (-20, 20)) / 2.0));
         DX : constant Long_Float := Long_Float (S.P1.X - S.P0.X);
         DY : constant Long_Float := Long_Float (S.P1.Y - S.P0.Y);
         Len : constant Long_Float := abs DX + abs DY;
         First, Last : Integer := -1;
         R  : constant Clip_Result := Liang_Barsky_Clip (S, W);
         CS : constant Clip_Result := Cohen_Sutherland_Clip (S, W);
         RP : constant Clip_Params_Result := Liang_Barsky_Clip_Params (S, W);
         Tol : constant Long_Float := 2.0 * Len / Long_Float (Samples) + 1.0E-3;
         function Near_L (A : Real; B : Long_Float) return Boolean is (abs (Long_Float (A) - B) <= Tol);
      begin
         for K in 0 .. Samples loop
            declare
               T : constant Long_Float := Long_Float (K) / Long_Float (Samples);
            begin
               if Inside (Long_Float (S.P0.X) + T * DX, Long_Float (S.P0.Y) + T * DY, W) then
                  if First < 0 then First := K; end if;
                  Last := K;
               end if;
            end;
         end loop;
         if First >= 0 then
            declare
               T0 : constant Long_Float := Long_Float (First) / Long_Float (Samples);
               T1 : constant Long_Float := Long_Float (Last) / Long_Float (Samples);
            begin
               if R.Status /= Clip_Accept or else RP.Status /= Clip_Accept then
                  Fail ("rejected although sample points lie inside", S, W);
               end if;
               if not (Near_L (R.Clipped.P0.X, Long_Float (S.P0.X) + T0 * DX)
                       and then Near_L (R.Clipped.P0.Y, Long_Float (S.P0.Y) + T0 * DY)
                       and then Near_L (R.Clipped.P1.X, Long_Float (S.P0.X) + T1 * DX)
                       and then Near_L (R.Clipped.P1.Y, Long_Float (S.P0.Y) + T1 * DY))
               then
                  Fail ("clipped piece differs from the sampled inside part", S, W);
               end if;
               if CS.Status /= Clip_Accept or else not Same_Clipped_Segment (CS.Clipped, R.Clipped, Real (2.0 * Tol)) then
                  Fail ("Cohen_Sutherland_Clip differs from the sampled inside part", S, W);
               end if;
               if RP.Clipped /= R.Clipped
                 or else (Len > 0.0 and then (abs (Long_Float (RP.T0) - T0) > 2.0 / Long_Float (Samples) + 1.0E-4
                                              or else abs (Long_Float (RP.T1) - T1) > 2.0 / Long_Float (Samples) + 1.0E-4))
               then
                  Fail ("Liang_Barsky_Clip_Params T0 / T1 differ from the sampled range", S, W);
               end if;
               Accepted := Accepted + 1;
            end;
         elsif R.Status = Clip_Accept then
            --  no sample inside: only a piece shorter than the sample spacing may be accepted
            declare
               P_Len : constant Long_Float := abs Long_Float (R.Clipped.P1.X - R.Clipped.P0.X)
                                              + abs Long_Float (R.Clipped.P1.Y - R.Clipped.P0.Y);
            begin
               if P_Len > Tol then
                  Fail ("accepted a piece although no sample lies inside", S, W);
               end if;
            end;
         end if;
         Checked := Checked + 1;
      end;
   end loop;
   if Accepted < 2_000 or else Checked - Accepted < 2_000 then
      Ada.Text_IO.Put_Line ("FAIL own check: random cases do not cover both outcomes");
      raise Program_Error;
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image & " segments ("
                         & Accepted'Image & " accepted; 4,001-point sampling reference)");
end Own_Checks;
