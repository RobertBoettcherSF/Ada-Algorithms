--  Standalone test suite for Fast_Clipping (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Fast_Clipping; use Fast_Clipping;

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
   Put_Line ("Fast_Clipping test suite");
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
   Section ("4. Region_Outcode / Classify_Point nine regions");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
   begin
      Check (Region_Outcode ((5.0, 5.0), W) = 0, "inside code 0");
      Check (Classify_Point ((5.0, 5.0), W) = 0, "Classify_Point alias");
      Check (Region_Outcode ((-1.0, 5.0), W) = Bit_Left, "left");
      Check (Region_Outcode ((11.0, 5.0), W) = Bit_Right, "right");
      Check (Region_Outcode ((5.0, -1.0), W) = Bit_Bottom, "bottom");
      Check (Region_Outcode ((5.0, 11.0), W) = Bit_Top, "top");
      Check (Region_Outcode ((-1.0, -1.0), W) = (Bit_Left or Bit_Bottom),
             "left-bottom corner");
      Check (Region_Outcode ((11.0, 11.0), W) = (Bit_Right or Bit_Top),
             "right-top corner");
      Check (Encode_Line (Bit_Left, Bit_Right) =
               Line_Code (Natural (Bit_Left) * 16 + Natural (Bit_Right)),
             "Encode_Line packs nibbles");
   end;

   ---------------------------------------------------------------------
   Section ("5. Fast_Clip_Case Accept / Reject / Need_Clip");
   ---------------------------------------------------------------------
   declare
      D : Fast_Clip_Decision;
   begin
      D := Fast_Clip_Case (0, 0);
      Check (D.Kind = Case_Accept, "both inside => Accept");
      Check (D.Edges_P0 = 0 and then D.Edges_P1 = 0, "Accept edges empty");

      D := Fast_Clip_Case (Bit_Left, Bit_Left);
      Check (D.Kind = Case_Reject, "both left => Reject");
      Check (D.Edges_P0 = Bit_Left, "Reject shares left bit");

      D := Fast_Clip_Case (Bit_Left or Bit_Top, Bit_Left or Bit_Bottom);
      Check (D.Kind = Case_Reject, "shared left on corners => Reject");

      D := Fast_Clip_Case (Bit_Left, 0);
      Check (D.Kind = Case_Need_Clip, "left->inside => Need_Clip");
      Check (D.Edges_P0 = Bit_Left and then D.Edges_P1 = 0,
             "Need_Clip suggests left for P0");

      D := Fast_Clip_Case (Bit_Left, Bit_Right);
      Check (D.Kind = Case_Need_Clip, "left->right => Need_Clip");
      Check (D.Edges_P0 = Bit_Left and then D.Edges_P1 = Bit_Right,
             "Need_Clip suggests left+right");
   end;

   ---------------------------------------------------------------------
   Section ("6. Clip_Against_Edge intersections");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((-5.0, 5.0), (15.0, 5.0));
      Hit : Vec2;
      Raised : Boolean := False;
   begin
      Hit := Clip_Against_Edge (S, W, Left_Edge);
      Check (Approx_Vec (Hit, (0.0, 5.0)), "hit left at (0,5)");
      Hit := Clip_Against_Edge (S, W, Right_Edge);
      Check (Approx_Vec (Hit, (10.0, 5.0)), "hit right at (10,5)");

      Hit := Clip_Against_Edge
        (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W, Bottom_Edge);
      Check (Approx_Vec (Hit, (5.0, 0.0)), "hit bottom at (5,0)");
      Hit := Clip_Against_Edge
        (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W, Top_Edge);
      Check (Approx_Vec (Hit, (5.0, 10.0)), "hit top at (5,10)");

      begin
         declare
            Unused_Hit : constant Vec2 := Clip_Against_Edge
              (Make_Segment ((1.0, 1.0), (1.0, 9.0)), W, Left_Edge);
         begin
            if Unused_Hit.X = Unused_Hit.X then
               null;  -- should not reach: parallel must raise
            end if;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "parallel to left raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("7. Fast_Clip trivial accept / reject");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Fast_Clip (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      Check (R.Status = Clip_Accept, "fully inside Accept");
      Check (Approx_Vec (R.Clipped.P0, (2.0, 2.0)), "inside P0 unchanged");
      Check (Approx_Vec (R.Clipped.P1, (8.0, 8.0)), "inside P1 unchanged");

      R := Fast_Clip (Make_Segment ((-5.0, -5.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "fully outside Reject");

      R := Fast_Clip (Make_Segment ((-5.0, 5.0), (-1.0, 5.0)), W);
      Check (R.Status = Clip_Reject, "left of window Reject");
   end;

   ---------------------------------------------------------------------
   Section ("8. Fast_Clip edge crossings");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Fast_Clip (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "horizontal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "enter left");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "exit right");

      R := Fast_Clip (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "vertical through Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 0.0)), "enter bottom");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 10.0)), "exit top");

      R := Fast_Clip (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "diagonal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 0.0)), "diagonal enter corner");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 10.0)), "diagonal exit corner");
   end;

   ---------------------------------------------------------------------
   Section ("9. Fast_Clip partial / degenerate");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Fast_Clip (Make_Segment ((-5.0, 2.0), (5.0, 2.0)), W);
      Check (R.Status = Clip_Accept, "enter from left Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 2.0)), "clipped start on left");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 2.0)), "end unchanged inside");

      R := Fast_Clip (Make_Segment ((5.0, 5.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "degenerate point inside Accept");

      R := Fast_Clip (Make_Segment ((-1.0, -1.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "degenerate point outside Reject");

      R := Fast_Clip (Make_Segment ((-2.0, 12.0), (12.0, -2.0)), W);
      Check (R.Status = Clip_Accept, "corner-to-corner crossing Accept");
      Check (Point_Inside_Window (R.Clipped.P0, W)
             and then Point_Inside_Window (R.Clipped.P1, W),
             "crossing endpoints inside");
   end;

   ---------------------------------------------------------------------
   Section ("10. Cohen_Sutherland_Clip reference");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Cohen_Sutherland_Clip (Make_Segment ((1.0, 1.0), (9.0, 9.0)), W);
      Check (R.Status = Clip_Accept, "CS fully inside Accept");
      R := Cohen_Sutherland_Clip
        (Make_Segment ((-2.0, -2.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "CS fully outside Reject");
      R := Cohen_Sutherland_Clip (Make_Segment ((-2.0, 5.0), (12.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "CS horizontal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "CS enter left");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "CS exit right");
   end;

   ---------------------------------------------------------------------
   Section ("11. Liang_Barsky_Clip_Lite reference");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Liang_Barsky_Clip_Lite
        (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      Check (R.Status = Clip_Accept, "LB lite inside Accept");
      R := Liang_Barsky_Clip_Lite
        (Make_Segment ((-5.0, -5.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "LB lite outside Reject");
      R := Liang_Barsky_Clip_Lite
        (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "LB lite horizontal Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "LB lite enter left");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "LB lite exit right");
   end;

   ---------------------------------------------------------------------
   Section ("12. Fast_Clip = CS = LB agreement lattice");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      F, C, L : Clip_Result;
      Agree_CS : Natural := 0;
      Agree_LB : Natural := 0;
      Total    : Natural := 0;
      type Pt is record
         X, Y : Real;
      end record;
      Pts : constant array (1 .. 4) of Pt :=
        [(-5.0, -5.0), (5.0, 5.0), (15.0, 15.0), (5.0, -5.0)];
   begin
      for I in Pts'Range loop
         for J in Pts'Range loop
            declare
               S : constant Segment :=
                 Make_Segment ((Pts (I).X, Pts (I).Y),
                               (Pts (J).X, Pts (J).Y));
            begin
               F := Fast_Clip (S, W);
               C := Cohen_Sutherland_Clip (S, W);
               L := Liang_Barsky_Clip_Lite (S, W);
               Total := Total + 1;
               if Status_Agree (F, C) then
                  Agree_CS := Agree_CS + 1;
               end if;
               if Status_Agree (F, L) then
                  Agree_LB := Agree_LB + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Agree_CS = Total,
             "Fast=CS on 4x4 lattice ("
             & Agree_CS'Image & "/" & Total'Image & ")");
      Check (Agree_LB = Total,
             "Fast=LB on 4x4 lattice ("
             & Agree_LB'Image & "/" & Total'Image & ")");
      Check (Total = 16, "lattice has 16 segments");
   end;

   ---------------------------------------------------------------------
   Section ("13. Same_Clipped_Segment / more fixtures");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      A : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 10.0));
      B : constant Segment := Make_Segment ((10.0, 10.0), (0.0, 0.0));
      R : Clip_Result;
   begin
      Check (Same_Clipped_Segment (A, B), "Same_Clipped undirected");
      Check (not Same_Clipped_Segment
               (A, Make_Segment ((0.0, 0.0), (5.0, 5.0))),
             "Same_Clipped rejects different");
      R := Fast_Clip (Make_Segment ((12.0, 5.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "enter from right Accept");
      Check (Approx_Vec (R.Clipped.P0, (10.0, 5.0))
             or else Approx_Vec (R.Clipped.P1, (10.0, 5.0)),
             "right boundary present");
      Check (Point_Inside_Window (R.Clipped.P0, W)
             and then Point_Inside_Window (R.Clipped.P1, W),
             "right-enter endpoints inside");
   end;

   ---------------------------------------------------------------------
   Section ("14. Fast_Clip_Case vs Encode_Line coverage");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      C0, C1 : Out_Code;
      D : Fast_Clip_Decision;
      LC : Line_Code;
      Accept_N, Reject_N, Need_N : Natural := 0;
   begin
      for X in -1 .. 2 loop
         for Y in -1 .. 2 loop
            C0 := Region_Outcode
              ((Real (X) * 8.0 - 3.0, Real (Y) * 8.0 - 3.0), W);
            for X2 in -1 .. 2 loop
               for Y2 in -1 .. 2 loop
                  C1 := Region_Outcode
                    ((Real (X2) * 8.0 - 3.0, Real (Y2) * 8.0 - 3.0), W);
                  D := Fast_Clip_Case (C0, C1);
                  LC := Encode_Line (C0, C1);
                  if LC /= Encode_Line (C0, C1) then
                     null;  -- unreachable consistency guard
                  end if;
                  case D.Kind is
                     when Case_Accept =>
                        Accept_N := Accept_N + 1;
                     when Case_Reject =>
                        Reject_N := Reject_N + 1;
                     when Case_Need_Clip =>
                        Need_N := Need_N + 1;
                  end case;
               end loop;
            end loop;
         end loop;
      end loop;
      Check (Accept_N >= 1, "case table saw Accept");
      Check (Reject_N >= 1, "case table saw Reject");
      Check (Need_N >= 1, "case table saw Need_Clip");
      Check (Accept_N + Reject_N + Need_N = 256,
             "4x4x4x4 = 256 classifications");
   end;

   ---------------------------------------------------------------------
   Section ("15. Diagonal / vertical / horizontal vs CS");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      C : Clip_Result;
   begin
      R := Fast_Clip (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      C := Cohen_Sutherland_Clip
        (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "diagonal through accept");
      Check (Status_Agree (R, C), "diagonal Fast=CS");
      Check (Approx (R.Clipped.P0.X, R.Clipped.P0.Y),
             "diagonal clip stays on y=x");

      R := Fast_Clip (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "vertical through accept");
      Check (Approx (R.Clipped.P0.X, 5.0)
             and then Approx (R.Clipped.P1.X, 5.0),
             "vertical x preserved");
      Check (Approx (abs (R.Clipped.P1.Y - R.Clipped.P0.Y), 10.0),
             "vertical clipped length 10");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " passed, "
             & Fail_Count'Image & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;
