--  Standalone test suite for Line_Clipping (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Line_Clipping; use Line_Clipping;

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

   function Status_Agree (A, B : Clip_Result; Tol : Real := 1.0E-3)
     return Boolean
   is
   begin
      if A.Status /= B.Status then
         return False;
      end if;
      if A.Status = Clip_Reject then
         return True;
      end if;
      return Same_Clipped_Segment (A.Clipped, B.Clipped, Tol);
   end Status_Agree;

begin
   Put_Line ("Line_Clipping test suite");
   Put_Line ("========================");

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
   Section ("2. Make_Window / Is_Valid_Window / Point_Inside_Window");
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
      Check (Point_Inside_Window ((5.0, 2.5), W), "center inside");
      Check (Point_Inside_Window ((0.0, 0.0), W), "corner counts inside");
      Check (not Point_Inside_Window ((-1.0, 2.0), W), "outside left");
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
   Section ("3. Make_Segment / Length / Same_Clipped_Segment");
   ---------------------------------------------------------------------
   declare
      S : constant Segment := Make_Segment ((0.0, 0.0), (3.0, 4.0));
      A : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 10.0));
      B : constant Segment := Make_Segment ((10.0, 10.0), (0.0, 0.0));
   begin
      Check (Approx_Vec (S.P0, (0.0, 0.0)), "Make_Segment P0");
      Check (Approx_Vec (S.P1, (3.0, 4.0)), "Make_Segment P1");
      Check (Approx (Length (S), 5.0), "Length 3-4-5");
      Check (Same_Clipped_Segment (A, B), "Same_Clipped undirected");
      Check (not Same_Clipped_Segment
               (A, Make_Segment ((0.0, 0.0), (5.0, 5.0))),
             "Same_Clipped rejects different");
      Check (Approx (Length (Make_Segment ((1.0, 1.0), (1.0, 1.0))), 0.0),
             "degenerate Length 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Outcodes / Trivial_Accept / Trivial_Reject");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      C_In    : constant Out_Code := Compute_OutCode ((5.0, 5.0), W);
      C_Left  : constant Out_Code := Compute_OutCode ((-1.0, 5.0), W);
      C_TR    : constant Out_Code := Compute_OutCode ((12.0, 12.0), W);
   begin
      Check (C_In = 0, "inside outcode 0");
      Check ((C_Left and Bit_Left) /= 0, "left bit set");
      Check ((C_TR and Bit_Top) /= 0 and then (C_TR and Bit_Right) /= 0,
             "top-right bits set");
      Check (Trivial_Accept (0, 0), "trivial accept both inside");
      Check (not Trivial_Accept (C_Left, 0), "not accept mixed");
      Check (Trivial_Reject (C_Left, Compute_OutCode ((-2.0, 8.0), W)),
             "trivial reject both left");
      Check (not Trivial_Reject (C_Left, Compute_OutCode ((12.0, 5.0), W)),
             "not reject left vs right");
   end;

   ---------------------------------------------------------------------
   Section ("5. Cohen_Sutherland_Clip fixtures");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Cohen_Sutherland_Clip (Make_Segment ((1.0, 1.0), (9.0, 9.0)), W);
      Check (R.Status = Clip_Accept, "CS fully inside Accept");
      Check (Approx_Vec (R.Clipped.P0, (1.0, 1.0)), "CS inside keeps P0");
      Check (Approx_Vec (R.Clipped.P1, (9.0, 9.0)), "CS inside keeps P1");

      R := Cohen_Sutherland_Clip
        (Make_Segment ((-2.0, -2.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "CS fully outside Reject");

      R := Cohen_Sutherland_Clip (Make_Segment ((-2.0, 5.0), (12.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "CS horizontal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "CS clip left");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "CS clip right");
   end;

   ---------------------------------------------------------------------
   Section ("6. Liang_Barsky_Clip fixtures");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Liang_Barsky_Clip (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      Check (R.Status = Clip_Accept, "LB fully inside Accept");
      Check (Point_Inside_Window (R.Clipped.P0, W)
             and then Point_Inside_Window (R.Clipped.P1, W),
             "LB inside endpoints inside");

      R := Liang_Barsky_Clip (Make_Segment ((-5.0, -5.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "LB fully outside Reject");

      R := Liang_Barsky_Clip (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "LB vertical through Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 0.0)), "LB vertical enter");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 10.0)), "LB vertical leave");

      R := Liang_Barsky_Clip (Make_Segment ((-5.0, 2.0), (5.0, 2.0)), W);
      Check (R.Status = Clip_Accept, "LB enter from left Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 2.0)), "LB clipped on left");
   end;

   ---------------------------------------------------------------------
   Section ("7. Midpoint_Subdivision_Clip fixtures");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Midpoint_Subdivision_Clip
        (Make_Segment ((2.0, 3.0), (7.0, 8.0)), W);
      Check (R.Status = Clip_Accept, "Mid fully inside Accept");
      Check (Approx_Vec (R.Clipped.P0, (2.0, 3.0), 1.0E-2),
             "Mid inside keeps P0");
      Check (Approx_Vec (R.Clipped.P1, (7.0, 8.0), 1.0E-2),
             "Mid inside keeps P1");

      R := Midpoint_Subdivision_Clip
        (Make_Segment ((-4.0, -4.0), (-2.0, -2.0)), W);
      Check (R.Status = Clip_Reject, "Mid fully outside Reject");

      R := Midpoint_Subdivision_Clip
        (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "Mid horizontal through Accept");
      Check (Approx (R.Clipped.P0.X, 0.0, 5.0E-2), "Mid enter ~x=0");
      Check (Approx (R.Clipped.P1.X, 10.0, 5.0E-2), "Mid leave ~x=10");
      Check (Point_Inside_Window (R.Clipped.P0, W)
             and then Point_Inside_Window (R.Clipped.P1, W),
             "Mid clipped endpoints inside");
   end;

   ---------------------------------------------------------------------
   Section ("8. Skala_Clip_Lite fixtures");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Skala_Clip_Lite (Make_Segment ((1.0, 1.0), (9.0, 4.0)), W);
      Check (R.Status = Clip_Accept, "Skala inside Accept");
      Check (Approx_Vec (R.Clipped.P0, (1.0, 1.0)), "Skala inside P0");
      Check (Approx_Vec (R.Clipped.P1, (9.0, 4.0)), "Skala inside P1");

      R := Skala_Clip_Lite (Make_Segment ((20.0, 20.0), (30.0, 25.0)), W);
      Check (R.Status = Clip_Reject, "Skala outside Reject");

      R := Skala_Clip_Lite (Make_Segment ((-2.0, 5.0), (12.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "Skala through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "Skala clip left");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "Skala clip right");

      R := Skala_Clip_Lite (Make_Segment ((5.0, 5.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "Skala point inside Accept");
   end;

   ---------------------------------------------------------------------
   Section ("9. Clip_With dispatch");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((-2.0, 5.0), (12.0, 5.0));
      R_CS : constant Clip_Result :=
        Clip_With (S, W, Cohen_Sutherland);
      R_LB : constant Clip_Result :=
        Clip_With (S, W, Liang_Barsky);
      R_Mid : constant Clip_Result :=
        Clip_With (S, W, Midpoint_Subdivision);
      R_Sk : constant Clip_Result :=
        Clip_With (S, W, Skala_Lite);
   begin
      Check (R_CS.Status = Clip_Accept, "Clip_With CS Accept");
      Check (R_LB.Status = Clip_Accept, "Clip_With LB Accept");
      Check (R_Mid.Status = Clip_Accept, "Clip_With Mid Accept");
      Check (R_Sk.Status = Clip_Accept, "Clip_With Skala Accept");
      Check (Status_Agree (R_CS, R_LB, 1.0E-2), "Clip_With CS~LB");
      Check (Status_Agree (R_CS, R_Sk, 1.0E-2), "Clip_With CS~Skala");
   end;

   ---------------------------------------------------------------------
   Section ("10. Compare_Algorithms agreement");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      Rep : Agreement_Report;
   begin
      Rep := Compare_Algorithms
        (Make_Segment ((1.0, 1.0), (9.0, 9.0)), W,
         Cohen_Sutherland, Liang_Barsky);
      Check (Rep.Agree, "Compare CS/LB inside Agree");
      Check (Rep.Same_Status, "Compare CS/LB inside Same_Status");
      Check (Rep.Same_Clipped_Seg, "Compare CS/LB inside Same_Clipped");

      Rep := Compare_Algorithms
        (Make_Segment ((-3.0, -3.0), (-1.0, -1.0)), W,
         Cohen_Sutherland, Midpoint_Subdivision);
      Check (Rep.Agree, "Compare CS/Mid outside Agree");
      Check (Rep.Left.Status = Clip_Reject, "Compare outside Left Reject");
      Check (Rep.Right.Status = Clip_Reject, "Compare outside Right Reject");

      Rep := Compare_Algorithms
        (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W,
         Liang_Barsky, Skala_Lite, 1.0E-3);
      Check (Rep.Agree, "Compare LB/Skala through Agree");
      Check (Rep.Same_Clipped_Seg, "Compare LB/Skala Same_Clipped");
   end;

   ---------------------------------------------------------------------
   Section ("11. Lattice CS == LB == Midpoint");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      type Pt is record
         X, Y : Real;
      end record;
      Pts : constant array (1 .. 5) of Pt :=
        [(-5.0, -5.0), (5.0, 5.0), (15.0, 15.0), (5.0, -5.0), (-5.0, 15.0)];
      Agree_CS_LB  : Natural := 0;
      Agree_CS_Mid : Natural := 0;
      Agree_LB_Mid : Natural := 0;
      Total        : Natural := 0;
      R_CS, R_LB, R_Mid : Clip_Result;
   begin
      for I in Pts'Range loop
         for J in Pts'Range loop
            declare
               S : constant Segment :=
                 Make_Segment ((Pts (I).X, Pts (I).Y),
                               (Pts (J).X, Pts (J).Y));
            begin
               R_CS  := Cohen_Sutherland_Clip (S, W);
               R_LB  := Liang_Barsky_Clip (S, W);
               R_Mid := Midpoint_Subdivision_Clip (S, W, 1.0E-3);
               Total := Total + 1;
               if Status_Agree (R_CS, R_LB, 5.0E-2) then
                  Agree_CS_LB := Agree_CS_LB + 1;
               end if;
               if Status_Agree (R_CS, R_Mid, 5.0E-2) then
                  Agree_CS_Mid := Agree_CS_Mid + 1;
               end if;
               if Status_Agree (R_LB, R_Mid, 5.0E-2) then
                  Agree_LB_Mid := Agree_LB_Mid + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Total = 25, "lattice has 25 segments");
      Check (Agree_CS_LB = Total,
             "CS=LB lattice ("
             & Agree_CS_LB'Image & "/" & Total'Image & ")");
      Check (Agree_CS_Mid = Total,
             "CS=Mid lattice ("
             & Agree_CS_Mid'Image & "/" & Total'Image & ")");
      Check (Agree_LB_Mid = Total,
             "LB=Mid lattice ("
             & Agree_LB_Mid'Image & "/" & Total'Image & ")");
   end;

   ---------------------------------------------------------------------
   Section ("12. Lattice CS == Skala_Lite");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      type Pt is record
         X, Y : Real;
      end record;
      Pts : constant array (1 .. 4) of Pt :=
        [(-5.0, -5.0), (5.0, 5.0), (15.0, 5.0), (5.0, -5.0)];
      Agree_Count : Natural := 0;
      Total       : Natural := 0;
      R_CS, R_Sk  : Clip_Result;
   begin
      for I in Pts'Range loop
         for J in Pts'Range loop
            declare
               S : constant Segment :=
                 Make_Segment ((Pts (I).X, Pts (I).Y),
                               (Pts (J).X, Pts (J).Y));
            begin
               R_CS := Cohen_Sutherland_Clip (S, W);
               R_Sk := Skala_Clip_Lite (S, W);
               Total := Total + 1;
               if Status_Agree (R_CS, R_Sk, 1.0E-2) then
                  Agree_Count := Agree_Count + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Total = 16, "Skala lattice has 16 segments");
      Check (Agree_Count = Total,
             "CS=Skala lattice ("
             & Agree_Count'Image & "/" & Total'Image & ")");
      Check (Agree_Count > 0, "Skala lattice non-empty");
   end;

   ---------------------------------------------------------------------
   Section ("13. Degenerate / edge / diagonal cases");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      Rep : Agreement_Report;
   begin
      R := Liang_Barsky_Clip (Make_Segment ((5.0, 5.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "LB point inside Accept");
      R := Cohen_Sutherland_Clip
        (Make_Segment ((-1.0, -1.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "CS point outside Reject");

      R := Clip_With (Make_Segment ((0.0, 0.0), (10.0, 10.0)), W,
                      Liang_Barsky);
      Check (R.Status = Clip_Accept, "diagonal corner-to-corner Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 0.0)), "diagonal P0");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 10.0)), "diagonal P1");

      Rep := Compare_Algorithms
        (Make_Segment ((-5.0, 0.0), (5.0, 10.0)), W,
         Cohen_Sutherland, Liang_Barsky, 1.0E-2);
      Check (Rep.Agree, "diagonal crossing CS=LB");
      Check (Rep.Left.Status = Clip_Accept, "diagonal crossing Accept");
   end;

   ---------------------------------------------------------------------
   Section ("14. Algorithm_Kind exhaustiveness via Clip_With reject");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((20.0, 20.0), (30.0, 30.0));
      All_Reject : Boolean := True;
   begin
      for K in Algorithm_Kind loop
         if Clip_With (S, W, K).Status /= Clip_Reject then
            All_Reject := False;
         end if;
      end loop;
      Check (All_Reject, "all algorithms reject far outside");
      Check (Algorithm_Kind'Pos (Skala_Lite)
             = Algorithm_Kind'Pos (Cohen_Sutherland) + 3,
             "Algorithm_Kind has 4 values");
      Check (Algorithm_Kind'First = Cohen_Sutherland,
             "Algorithm_Kind first is CS");
   end;

   ---------------------------------------------------------------------
   Section ("15. Compare_Algorithms Same_Clipped_Segment field");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      Rep : constant Agreement_Report :=
        Compare_Algorithms
          (Make_Segment ((-2.0, 2.0), (12.0, 2.0)), W,
           Midpoint_Subdivision, Skala_Lite, 5.0E-2);
   begin
      Check (Rep.Same_Status, "Mid/Skala Same_Status");
      Check (Rep.Agree, "Mid/Skala Agree");
      Check (Rep.Same_Clipped_Seg, "Mid/Skala Same_Clipped_Seg");
      Check (Rep.Left.Status = Clip_Accept, "Mid/Skala Left Accept");
      Check (Point_Inside_Window (Rep.Left.Clipped.P0, W),
             "Mid/Skala Left P0 inside");
      Check (Point_Inside_Window (Rep.Right.Clipped.P1, W),
             "Mid/Skala Right P1 inside");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " passed, "
             & Fail_Count'Image & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;
