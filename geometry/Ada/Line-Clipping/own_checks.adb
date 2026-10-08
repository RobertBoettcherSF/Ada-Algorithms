pragma Ada_2022;
--  Own tests for Line_Clipping (see tests/SOURCES.txt).
--  All four clippers against an own brute-force reference: the segment is sampled at 4001 evenly
--  spaced parameters in Long_Float and each sample is tested against the window. Accept/reject must
--  match, and an accepted segment must run (undirected) from the first to the last inside sample,
--  within one sample step plus 0.02. Cases where the segment only grazes the window (inside the
--  window grown by 0.01 but not inside it shrunk by 0.01) are skipped as ambiguous.
with Ada.Text_IO; use Ada.Text_IO;
with Line_Clipping; use Line_Clipping;

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
   N : constant := 4000;
   type LF is new Long_Float;
   function Inside (X, Y : LF; X0, Y0, X1, Y1 : LF; D : LF) return Boolean is
     (X >= X0 + D and then X <= X1 - D and then Y >= Y0 + D and then Y <= Y1 - D);
   function Near (A : Vec2; X, Y, Tol : LF) return Boolean is (abs (LF (A.X) - X) <= Tol and then abs (LF (A.Y) - Y) <= Tol);
   function R2 return Real is (Real (Next (-2000, 3000)) / 100.0);
begin
   for Run in 1 .. 3000 loop
      declare
         X0 : constant Real := Real (Next (-500, 500)) / 100.0;
         Y0 : constant Real := Real (Next (-500, 500)) / 100.0;
         W : constant Clip_Window := Make_Window (X0, Y0, X0 + Real (Next (50, 1500)) / 100.0, Y0 + Real (Next (50, 1500)) / 100.0);
         S : constant Segment := Make_Segment ((R2, R2), (R2, R2));
         Ax : constant LF := LF (S.P0.X); Ay : constant LF := LF (S.P0.Y);
         Dx : constant LF := LF (S.P1.X) - Ax; Dy : constant LF := LF (S.P1.Y) - Ay;
         Cin, Cout : Natural := 0;
         First, Last : Integer := -1;
         Px, Py, Qx, Qy, Tol : LF;
      begin
         for K in 0 .. N loop
            Px := Ax + Dx * LF (K) / LF (N); Py := Ay + Dy * LF (K) / LF (N);
            if Inside (Px, Py, LF (W.X_Min), LF (W.Y_Min), LF (W.X_Max), LF (W.Y_Max), 0.01) then Cin := Cin + 1; end if;
            if Inside (Px, Py, LF (W.X_Min), LF (W.Y_Min), LF (W.X_Max), LF (W.Y_Max), -0.01) then Cout := Cout + 1; end if;
            if Inside (Px, Py, LF (W.X_Min), LF (W.Y_Min), LF (W.X_Max), LF (W.Y_Max), 0.0) then
               if First < 0 then First := K; end if;
               Last := K;
            end if;
         end loop;
         if Cin > 0 or else Cout = 0 then
            Px := Ax + Dx * LF (First) / LF (N); Py := Ay + Dy * LF (First) / LF (N);
            Qx := Ax + Dx * LF (Last) / LF (N);  Qy := Ay + Dy * LF (Last) / LF (N);
            Tol := 0.02 + (abs Dx + abs Dy) / LF (N);
            for Kind in Algorithm_Kind loop
               declare
                  C : constant Clip_Result := Clip_With (S, W, Kind);
               begin
                  if Cout = 0 then
                     Report (C.Status = Clip_Reject, Kind'Image & " accepted an outside segment, run" & Run'Image);
                  else
                     Report (C.Status = Clip_Accept
                             and then ((Near (C.Clipped.P0, Px, Py, Tol) and then Near (C.Clipped.P1, Qx, Qy, Tol))
                                       or else (Near (C.Clipped.P1, Px, Py, Tol) and then Near (C.Clipped.P0, Qx, Qy, Tol))),
                             Kind'Image & " clip differs from the sampled clip, run" & Run'Image);
                  end if;
               end;
            end loop;
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
