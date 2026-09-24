--  Standalone test suite for Liang_Barsky (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Liang_Barsky; use Liang_Barsky;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Approx_Vec (A, B : Vec2; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Approx_Vec;

   function Status_Agree (A, B : Clip_Result) return Boolean is
   begin
      if A.Status /= B.Status then
         return False;
      end if;
      if A.Status = Clip_Reject then
         return True;
      end if;
      return Same_Clipped_Segment (A.Clipped, B.Clipped, 1.0E-3);
   end Status_Agree;

begin
   Put_Line ("Liang_Barsky test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Dot");
   ---------------------------------------------------------------------
   declare
      A : constant Vec2 := (3.0, 4.0);
      B : constant Vec2 := (0.0, 0.0);
      S : constant Vec2 := A + (1.0, 1.0);
      D : constant Vec2 := A - (1.0, 1.0);
      M : constant Vec2 := 2.0 * (1.0, 2.0);
   begin
      Check (Near (1.0, 1.0 + 1.0E-6), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx_Vec (S, (4.0, 5.0)), "vector +");
      Check (Approx_Vec (D, (2.0, 3.0)), "vector -");
      Check (Approx_Vec (M, (2.0, 4.0)), "scalar *");
      Check (Approx (Dot ((1.0, 0.0), (0.0, 1.0)), 0.0), "Dot orthogonal");
      Check (Near_Point (A, A), "Near_Point identical");
      Check (not Near_Point (A, B), "Near_Point distinct");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Window / Is_Valid_Window");
   ---------------------------------------------------------------------
   declare
      W   : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 5.0);
      Bad : Clip_Window;
      Raised : Boolean := False;
   begin
      Check (Is_Valid_Window (W), "Make_Window yields valid window");
      Check (Approx (W.X_Max - W.X_Min, 10.0), "window width 10");
      Check (Approx (W.Y_Max - W.Y_Min, 5.0), "window height 5");
      Bad := (0.0, 0.0, 0.0, 1.0);
      Check (not Is_Valid_Window (Bad), "zero-width window invalid");
      Bad := (0.0, 2.0, 1.0, 1.0);
      Check (not Is_Valid_Window (Bad), "inverted Y window invalid");
      begin
         declare
            Unused : Clip_Window;
         begin
            Unused := Make_Window (1.0, 0.0, 0.0, 1.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "Make_Window inverted X raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Segment / Length / Point_Inside_Window");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((0.0, 0.0), (3.0, 4.0));
   begin
      Check (Approx_Vec (S.P0, (0.0, 0.0)), "Make_Segment P0");
      Check (Approx_Vec (S.P1, (3.0, 4.0)), "Make_Segment P1");
      Check (Approx (Length (S), 5.0), "Length 3-4-5");
      Check (Point_Inside_Window ((5.0, 5.0), W), "center inside");
      Check (Point_Inside_Window ((0.0, 0.0), W), "corner counts inside");
      Check (not Point_Inside_Window ((-1.0, 5.0), W), "outside left");
   end;

   ---------------------------------------------------------------------
   Section ("4. Compute_PQ left/right/bottom/top");
   ---------------------------------------------------------------------
   declare
      W  : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S  : constant Segment := Make_Segment ((2.0, 3.0), (8.0, 7.0));
      PQ : constant PQ_Values := Compute_PQ (S, W);
      --  Δx=6, Δy=4
   begin
      Check (Approx (PQ.P (1), -6.0), "p1 = -Δx (left)");
      Check (Approx (PQ.Q (1), 2.0), "q1 = x0 - xmin");
      Check (Approx (PQ.P (2), 6.0), "p2 = Δx (right)");
      Check (Approx (PQ.Q (2), 8.0), "q2 = xmax - x0");
      Check (Approx (PQ.P (3), -4.0), "p3 = -Δy (bottom)");
      Check (Approx (PQ.Q (3), 3.0), "q3 = y0 - ymin");
      Check (Approx (PQ.P (4), 4.0), "p4 = Δy (top)");
      Check (Approx (PQ.Q (4), 7.0), "q4 = ymax - y0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Clip_Parameters fully inside / outside");
   ---------------------------------------------------------------------
   declare
      W  : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      In_Seg : constant Segment :=
        Make_Segment ((2.0, 2.0), (8.0, 8.0));
      Out_Seg : constant Segment :=
        Make_Segment ((-5.0, -5.0), (-1.0, -1.0));
      PR : Parameter_Result;
   begin
      PR := Clip_Parameters (In_Seg, W);
      Check (PR.Accepted, "inside segment Accepted");
      Check (Approx (PR.T_Enter, 0.0), "inside t_enter = 0");
      Check (Approx (PR.T_Leave, 1.0), "inside t_leave = 1");

      PR := Clip_Parameters (Out_Seg, W);
      Check (not PR.Accepted, "fully outside Rejected");
   end;

   ---------------------------------------------------------------------
   Section ("6. Point_At_Parameter");
   ---------------------------------------------------------------------
   declare
      S : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 20.0));
      M : constant Vec2 := Point_At_Parameter (S, 0.5);
      A : constant Vec2 := Point_At_Parameter (S, 0.0);
      B : constant Vec2 := Point_At_Parameter (S, 1.0);
   begin
      Check (Approx_Vec (A, (0.0, 0.0)), "t=0 is P0");
      Check (Approx_Vec (B, (10.0, 20.0)), "t=1 is P1");
      Check (Approx_Vec (M, (5.0, 10.0)), "t=0.5 midpoint");
   end;

   ---------------------------------------------------------------------
   Section ("7. Liang_Barsky_Clip fully inside");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((1.0, 2.0), (3.0, 4.0));
      R : constant Clip_Result := Liang_Barsky_Clip (S, W);
      C : constant Clip_Result := Cohen_Sutherland_Clip (S, W);
   begin
      Check (R.Status = Clip_Accept, "fully inside Accept");
      Check (Approx_Vec (R.Clipped.P0, S.P0), "inside P0 unchanged");
      Check (Approx_Vec (R.Clipped.P1, S.P1), "inside P1 unchanged");
      Check (Status_Agree (R, C), "inside LB=CS");
   end;

   ---------------------------------------------------------------------
   Section ("8. Liang_Barsky_Clip fully outside / edge crossings");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      C : Clip_Result;
   begin
      R := Liang_Barsky_Clip (Make_Segment ((-5.0, 5.0), (-1.0, 5.0)), W);
      Check (R.Status = Clip_Reject, "left-outside horizontal Reject");

      R := Liang_Barsky_Clip (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      C := Cohen_Sutherland_Clip (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "horizontal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "enter left at (0,5)");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "leave right at (10,5)");
      Check (Status_Agree (R, C), "horizontal through LB=CS");

      R := Liang_Barsky_Clip (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "vertical through Accept");
      Check (Approx (R.Clipped.P0.Y, 0.0) and then Approx (R.Clipped.P1.Y, 10.0),
             "vertical clipped to [0,10]");
   end;

   ---------------------------------------------------------------------
   Section ("9. Liang_Barsky_Clip_Params returns t0/t1");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((-5.0, 5.0), (15.0, 5.0));
      P : constant Clip_Params_Result := Liang_Barsky_Clip_Params (S, W);
      --  x = -5 + t*20; enter at x=0 ⇒ t=0.25; leave at x=10 ⇒ t=0.75
   begin
      Check (P.Status = Clip_Accept, "params Accept");
      Check (Approx (P.T0, 0.25), "t0 = 0.25 enter left");
      Check (Approx (P.T1, 0.75), "t1 = 0.75 leave right");
      Check (Approx_Vec (P.Clipped.P0, Point_At_Parameter (S, P.T0), 1.0E-2),
             "clipped P0 matches t0");
      Check (Approx_Vec (P.Clipped.P1, Point_At_Parameter (S, P.T1), 1.0E-2),
             "clipped P1 matches t1");
   end;

   ---------------------------------------------------------------------
   Section ("10. Parallel outside / horizontal / vertical");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      PQ : PQ_Values;
   begin
      --  Horizontal above window (parallel to top/bottom, outside)
      R := Liang_Barsky_Clip (Make_Segment ((-2.0, 12.0), (12.0, 12.0)), W);
      Check (R.Status = Clip_Reject, "horizontal above Reject");

      PQ := Compute_PQ (Make_Segment ((-2.0, 12.0), (12.0, 12.0)), W);
      Check (Near (PQ.P (3), 0.0) and then Near (PQ.P (4), 0.0),
             "horizontal ⇒ p3=p4=0");
      Check (PQ.Q (4) < 0.0, "above ⇒ q4 < 0");

      R := Liang_Barsky_Clip (Make_Segment ((12.0, -2.0), (12.0, 12.0)), W);
      Check (R.Status = Clip_Reject, "vertical right-outside Reject");

      R := Liang_Barsky_Clip (Make_Segment ((0.0, 5.0), (10.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "on mid horizontal Accept");
      Check (Approx (Length (R.Clipped), 10.0), "full width preserved");
   end;

   ---------------------------------------------------------------------
   Section ("11. Diagonal clips");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      C : Clip_Result;
      P : Clip_Params_Result;
   begin
      R := Liang_Barsky_Clip (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      C := Cohen_Sutherland_Clip (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "diagonal through Accept");
      Check (Status_Agree (R, C), "diagonal LB=CS");
      Check (Approx (R.Clipped.P0.X, R.Clipped.P0.Y), "diagonal P0 on y=x");
      Check (Approx (R.Clipped.P1.X, R.Clipped.P1.Y), "diagonal P1 on y=x");

      P := Liang_Barsky_Clip_Params
        (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      Check (Approx (P.T0, 0.25) and then Approx (P.T1, 0.75),
             "diagonal t in [0.25,0.75]");
   end;

   ---------------------------------------------------------------------
   Section ("12. Degenerate point segment");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      Rin  : constant Clip_Result :=
        Liang_Barsky_Clip (Make_Segment ((5.0, 5.0), (5.0, 5.0)), W);
      Rout : constant Clip_Result :=
        Liang_Barsky_Clip (Make_Segment ((-1.0, -1.0), (-1.0, -1.0)), W);
      PQ : constant PQ_Values :=
        Compute_PQ (Make_Segment ((5.0, 5.0), (5.0, 5.0)), W);
   begin
      Check (Rin.Status = Clip_Accept, "point inside Accept");
      Check (Approx_Vec (Rin.Clipped.P0, (5.0, 5.0)), "point inside P0");
      Check (Rout.Status = Clip_Reject, "point outside Reject");
      Check (Near (PQ.P (1), 0.0) and then Near (PQ.P (2), 0.0)
             and then Near (PQ.P (3), 0.0) and then Near (PQ.P (4), 0.0),
             "degenerate ⇒ all p_i = 0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Cohen_Sutherland_Clip reference + agreement lattice");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      C : Clip_Result;
      Agree_Count : Natural := 0;
      Total       : Natural := 0;
      type Pt is record
         X, Y : Real;
      end record;
      Pts : constant array (1 .. 4) of Pt :=
        [(-5.0, -5.0), (5.0, 5.0), (15.0, 15.0), (5.0, -5.0)];
   begin
      R := Cohen_Sutherland_Clip (Make_Segment ((1.0, 1.0), (9.0, 9.0)), W);
      Check (R.Status = Clip_Accept, "CS fully inside Accept");
      R := Cohen_Sutherland_Clip (Make_Segment ((-2.0, -2.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "CS fully outside Reject");
      R := Cohen_Sutherland_Clip (Make_Segment ((-2.0, 5.0), (12.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "CS horizontal through Accept");

      for I in Pts'Range loop
         for J in Pts'Range loop
            declare
               S : constant Segment :=
                 Make_Segment ((Pts (I).X, Pts (I).Y),
                               (Pts (J).X, Pts (J).Y));
            begin
               R := Liang_Barsky_Clip (S, W);
               C := Cohen_Sutherland_Clip (S, W);
               Total := Total + 1;
               if Status_Agree (R, C) then
                  Agree_Count := Agree_Count + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Agree_Count = Total,
             "LB=CS on 4x4 endpoint lattice ("
             & Agree_Count'Image & "/" & Total'Image & ")");
      Check (Total = 16, "lattice has 16 segments");
   end;

   ---------------------------------------------------------------------
   Section ("14. Clip_Parameters edge enter/leave values");
   ---------------------------------------------------------------------
   declare
      W  : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S  : constant Segment := Make_Segment ((5.0, -5.0), (5.0, 15.0));
      PR : constant Parameter_Result := Clip_Parameters (S, W);
      --  y = -5 + t*20; enter y=0 ⇒ t=0.25; leave y=10 ⇒ t=0.75
   begin
      Check (PR.Accepted, "vertical through params Accepted");
      Check (Approx (PR.T_Enter, 0.25), "vertical t_enter 0.25");
      Check (Approx (PR.T_Leave, 0.75), "vertical t_leave 0.75");
   end;

   ---------------------------------------------------------------------
   Section ("15. Partial edge clips / Same_Clipped_Segment");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      A : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 10.0));
      B : constant Segment := Make_Segment ((10.0, 10.0), (0.0, 0.0));
   begin
      R := Liang_Barsky_Clip (Make_Segment ((-5.0, 2.0), (5.0, 2.0)), W);
      Check (R.Status = Clip_Accept, "enter from left Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 2.0)), "clipped start on left");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 2.0)), "clipped end at P1");
      Check (Point_Inside_Window (R.Clipped.P0, W)
             and then Point_Inside_Window (R.Clipped.P1, W),
             "clipped endpoints inside");
      Check (Same_Clipped_Segment (A, B), "Same_Clipped undirected");
      Check (not Same_Clipped_Segment
               (A, Make_Segment ((0.0, 0.0), (5.0, 5.0))),
             "Same_Clipped rejects different");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " passed, "
             & Fail_Count'Image & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;
