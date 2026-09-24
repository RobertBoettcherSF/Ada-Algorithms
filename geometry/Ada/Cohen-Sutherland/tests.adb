--  Standalone test suite for Cohen_Sutherland (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Cohen_Sutherland; use Cohen_Sutherland;

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

   function Approx_Vec3 (A, B : Vec3; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol)
        and then Approx (A.Y, B.Y, Tol)
        and then Approx (A.Z, B.Z, Tol);
   end Approx_Vec3;

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
   Put_Line ("Cohen_Sutherland test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Dot (2-D and 3-D)");
   ---------------------------------------------------------------------
   declare
      A : constant Vec2 := (3.0, 4.0);
      B : constant Vec2 := (0.0, 0.0);
      S : constant Vec2 := A + (1.0, 1.0);
      D : constant Vec2 := A - (1.0, 1.0);
      M : constant Vec2 := 2.0 * (1.0, 2.0);
      A3 : constant Vec3 := (1.0, 2.0, 3.0);
      B3 : constant Vec3 := A3 + (1.0, 1.0, 1.0);
   begin
      Check (Near (1.0, 1.0 + 1.0E-6), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx_Vec (S, (4.0, 5.0)), "vector +");
      Check (Approx_Vec (D, (2.0, 3.0)), "vector -");
      Check (Approx_Vec (M, (2.0, 4.0)), "scalar *");
      declare
         U2 : constant Vec2 := (1.0, 0.0);
         V2 : constant Vec2 := (0.0, 1.0);
         U3 : constant Vec3 := (1.0, 0.0, 0.0);
         V3 : constant Vec3 := (0.0, 1.0, 0.0);
      begin
         Check (Approx (Dot (U2, V2), 0.0), "Dot orthogonal 2-D");
         Check (Near_Point (A, A), "Near_Point identical 2-D");
         Check (not Near_Point (A, B), "Near_Point distinct 2-D");
         Check (Approx_Vec3 (B3, (2.0, 3.0, 4.0)), "vector3 +");
         Check (Approx (Dot (U3, V3), 0.0), "Dot orthogonal 3-D");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Window / Is_Valid_Window / Make_Box");
   ---------------------------------------------------------------------
   declare
      W   : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 5.0);
      Bx  : constant Clip_Box := Make_Box (0.0, 0.0, 0.0, 1.0, 2.0, 3.0);
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
      Check (Is_Valid_Box (Bx), "Make_Box yields valid box");
      Check (Approx (Bx.Z_Max - Bx.Z_Min, 3.0), "box depth 3");
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
   Section ("3. Make_Segment / Length / Point_Inside_Window / Same");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((0.0, 0.0), (3.0, 4.0));
      S3 : constant Segment3 :=
        Make_Segment ((0.0, 0.0, 0.0), (1.0, 2.0, 2.0));
      Bx : constant Clip_Box := Make_Box (0.0, 0.0, 0.0, 5.0, 5.0, 5.0);
   begin
      Check (Approx_Vec (S.P0, (0.0, 0.0)), "Make_Segment P0");
      Check (Approx_Vec (S.P1, (3.0, 4.0)), "Make_Segment P1");
      Check (Approx (Length (S), 5.0), "Length 3-4-5");
      Check (Approx (Length (S3), 3.0), "Length3 1-2-2");
      Check (Point_Inside_Window ((5.0, 5.0), W), "center inside");
      Check (Point_Inside_Window ((0.0, 0.0), W), "corner counts inside");
      Check (not Point_Inside_Window ((-1.0, 5.0), W), "outside left");
      Check (Point_Inside_Box ((1.0, 1.0, 1.0), Bx), "box interior");
      Check (Same_Clipped_Segment (S, S), "Same_Clipped_Segment identical");
      Check (Same_Clipped_Segment
               (S, Make_Segment (S.P1, S.P0)), "Same undirected reverse");
   end;

   ---------------------------------------------------------------------
   Section ("4. Compute_OutCode nine-region bits");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
   begin
      Check (Compute_OutCode ((5.0, 5.0), W) = 0, "inside outcode 0");
      Check (Compute_OutCode ((-1.0, 5.0), W) = Bit_Left, "LEFT");
      Check (Compute_OutCode ((11.0, 5.0), W) = Bit_Right, "RIGHT");
      Check (Compute_OutCode ((5.0, -1.0), W) = Bit_Bottom, "BOTTOM");
      Check (Compute_OutCode ((5.0, 11.0), W) = Bit_Top, "TOP");
      Check (Compute_OutCode ((-1.0, 11.0), W) = (Bit_Left or Bit_Top),
             "TOP-LEFT 1001");
      Check (Compute_OutCode ((11.0, -1.0), W) = (Bit_Right or Bit_Bottom),
             "BOTTOM-RIGHT 0110");
   end;

   ---------------------------------------------------------------------
   Section ("5. Trivial_Accept / Trivial_Reject");
   ---------------------------------------------------------------------
   declare
      Inside : constant Out_Code := 0;
      Left   : constant Out_Code := Bit_Left;
      Right  : constant Out_Code := Bit_Right;
      TopL   : constant Out_Code := Bit_Left or Bit_Top;
   begin
      Check (Trivial_Accept (Inside, Inside), "both inside Accept");
      Check (not Trivial_Accept (Inside, Left), "one outside not Accept");
      Check (Trivial_Reject (Left, TopL), "share LEFT ⇒ Reject");
      Check (not Trivial_Reject (Left, Right), "opposite sides not Reject");
      Check (not Trivial_Reject (Inside, Left), "inside & outside not Reject");
      Check (Trivial_Accept (Out_Code_3D'(0), Out_Code_3D'(0)),
             "3-D both inside Accept");
      Check (Trivial_Reject (Bit3_Near, Bit3_Near or Bit3_Left),
             "3-D share Near ⇒ Reject");
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
              (Make_Segment ((5.0, 0.0), (5.0, 10.0)), W, Left_Edge);
         begin
            pragma Unreferenced (Unused_Hit);
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "vertical || left raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("7. Cohen_Sutherland_Clip fully inside");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((1.0, 2.0), (3.0, 4.0));
      R : constant Clip_Result := Cohen_Sutherland_Clip (S, W);
      L : constant Clip_Result := Liang_Barsky_Clip_Lite (S, W);
   begin
      Check (R.Status = Clip_Accept, "fully inside Accept");
      Check (Approx_Vec (R.Clipped.P0, S.P0), "inside P0 unchanged");
      Check (Approx_Vec (R.Clipped.P1, S.P1), "inside P1 unchanged");
      Check (Status_Agree (R, L), "inside CS=LB");
   end;

   ---------------------------------------------------------------------
   Section ("8. Cohen_Sutherland_Clip fully outside / edge crossings");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      L : Clip_Result;
   begin
      R := Cohen_Sutherland_Clip (Make_Segment ((-5.0, 5.0), (-1.0, 5.0)), W);
      Check (R.Status = Clip_Reject, "fully left Reject");

      R := Cohen_Sutherland_Clip (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "horizontal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "horiz clip P0");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "horiz clip P1");
      L := Liang_Barsky_Clip_Lite (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (Status_Agree (R, L), "horiz CS=LB");

      R := Cohen_Sutherland_Clip (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "vertical through Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 0.0)), "vert clip P0");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 10.0)), "vert clip P1");

      R := Cohen_Sutherland_Clip (Make_Segment ((-2.0, -2.0), (12.0, 12.0)), W);
      Check (R.Status = Clip_Accept, "diagonal through Accept");
      Check (Point_Inside_Window (R.Clipped.P0, W), "diag P0 inside");
      Check (Point_Inside_Window (R.Clipped.P1, W), "diag P1 inside");
   end;

   ---------------------------------------------------------------------
   Section ("9. Partial clips / corner / degenerate point");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Cohen_Sutherland_Clip (Make_Segment ((5.0, 5.0), (20.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "half-out right Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 5.0)), "half-out P0 stays");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "half-out P1 at right");

      R := Cohen_Sutherland_Clip (Make_Segment ((-5.0, -5.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "from SW corner into Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 0.0)), "enters at origin");

      R := Cohen_Sutherland_Clip (Make_Segment ((-2.0, 12.0), (12.0, -2.0)), W);
      Check (R.Status = Clip_Accept, "corner-to-corner Accept");
      Check (Point_Inside_Window (R.Clipped.P0, W), "corner clip P0 inside");
      Check (Point_Inside_Window (R.Clipped.P1, W), "corner clip P1 inside");

      R := Cohen_Sutherland_Clip (Make_Segment ((5.0, 5.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "degenerate point inside Accept");

      R := Cohen_Sutherland_Clip (Make_Segment ((-1.0, -1.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "degenerate point outside Reject");
   end;

   ---------------------------------------------------------------------
   Section ("10. Liang_Barsky_Clip_Lite agreement lattice");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      Pts : constant array (1 .. 4) of Vec2 :=
        [(-5.0, 5.0), (5.0, -5.0), (15.0, 5.0), (5.0, 15.0)];
      Agree : Boolean := True;
      CS, LB : Clip_Result;
   begin
      for I in Pts'Range loop
         for J in Pts'Range loop
            CS := Cohen_Sutherland_Clip (Make_Segment (Pts (I), Pts (J)), W);
            LB := Liang_Barsky_Clip_Lite (Make_Segment (Pts (I), Pts (J)), W);
            if not Status_Agree (CS, LB) then
               Agree := False;
            end if;
         end loop;
      end loop;
      Check (Agree, "CS=LB on 4x4 outer lattice");

      CS := Cohen_Sutherland_Clip (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      LB := Liang_Barsky_Clip_Lite (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      Check (Status_Agree (CS, LB), "CS=LB interior diagonal");

      CS := Cohen_Sutherland_Clip (Make_Segment ((-1.0, 20.0), (-1.0, -5.0)), W);
      LB := Liang_Barsky_Clip_Lite (Make_Segment ((-1.0, 20.0), (-1.0, -5.0)), W);
      Check (Status_Agree (CS, LB), "CS=LB left-side vertical reject");
      Check (CS.Status = Clip_Reject, "left-side vertical is Reject");
   end;

   ---------------------------------------------------------------------
   Section ("11. Cohen_Sutherland_Clip_3D_Lite inside / outside");
   ---------------------------------------------------------------------
   declare
      Bx : constant Clip_Box := Make_Box (0.0, 0.0, 0.0, 10.0, 10.0, 10.0);
      R  : Clip_Result_3D;
      S  : Segment3;
   begin
      S := Make_Segment ((1.0, 2.0, 3.0), (4.0, 5.0, 6.0));
      R := Cohen_Sutherland_Clip_3D_Lite (S, Bx);
      Check (R.Status = Clip_Accept, "3-D fully inside Accept");
      Check (Approx_Vec3 (R.Clipped.P0, S.P0), "3-D inside P0 unchanged");
      Check (Approx_Vec3 (R.Clipped.P1, S.P1), "3-D inside P1 unchanged");

      S := Make_Segment ((-5.0, 5.0, 5.0), (-1.0, 5.0, 5.0));
      R := Cohen_Sutherland_Clip_3D_Lite (S, Bx);
      Check (R.Status = Clip_Reject, "3-D fully left Reject");

      S := Make_Segment ((5.0, 5.0, -5.0), (5.0, 5.0, 15.0));
      R := Cohen_Sutherland_Clip_3D_Lite (S, Bx);
      Check (R.Status = Clip_Accept, "3-D Z-through Accept");
      Check (Approx_Vec3 (R.Clipped.P0, (5.0, 5.0, 0.0)), "3-D Z clip near");
      Check (Approx_Vec3 (R.Clipped.P1, (5.0, 5.0, 10.0)), "3-D Z clip far");
   end;

   ---------------------------------------------------------------------
   Section ("12. 3-D outcodes and partial clips");
   ---------------------------------------------------------------------
   declare
      Bx : constant Clip_Box := Make_Box (0.0, 0.0, 0.0, 10.0, 10.0, 10.0);
      R  : Clip_Result_3D;
   begin
      Check (Compute_OutCode ((5.0, 5.0, 5.0), Bx) = 0, "3-D inside code 0");
      Check (Compute_OutCode ((5.0, 5.0, -1.0), Bx) = Bit3_Near, "Near bit");
      Check (Compute_OutCode ((5.0, 5.0, 11.0), Bx) = Bit3_Far, "Far bit");
      Check (Compute_OutCode ((-1.0, 11.0, -1.0), Bx) =
               (Bit3_Left or Bit3_Top or Bit3_Near),
             "3-D corner code");

      R := Cohen_Sutherland_Clip_3D_Lite
        (Make_Segment ((5.0, 5.0, 5.0), (20.0, 5.0, 5.0)), Bx);
      Check (R.Status = Clip_Accept, "3-D half-out Accept");
      Check (Approx_Vec3 (R.Clipped.P1, (10.0, 5.0, 5.0)),
             "3-D half-out at X_Max");
      Check (Point_Inside_Box (R.Clipped.P0, Bx), "3-D clipped P0 inside");
      Check (Point_Inside_Box (R.Clipped.P1, Bx), "3-D clipped P1 inside");
   end;

   ---------------------------------------------------------------------
   Section ("13. Outcode region grid coverage");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      --  Sample one point per CS region (row-major: TL,T,TR / L,C,R / BL,B,BR)
      Samples : constant array (1 .. 9) of Vec2 :=
        [(-1.0, 11.0), (5.0, 11.0), (11.0, 11.0),
         (-1.0,  5.0), (5.0,  5.0), (11.0,  5.0),
         (-1.0, -1.0), (5.0, -1.0), (11.0, -1.0)];
      Expected : constant array (1 .. 9) of Out_Code :=
        [Bit_Left or Bit_Top, Bit_Top, Bit_Right or Bit_Top,
         Bit_Left, 0, Bit_Right,
         Bit_Left or Bit_Bottom, Bit_Bottom, Bit_Right or Bit_Bottom];
      Ok : Boolean := True;
      R  : Clip_Result;
   begin
      for I in Samples'Range loop
         if Compute_OutCode (Samples (I), W) /= Expected (I) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "all 9 region outcodes match");

      --  Clip from each outside sample into the center.
      Ok := True;
      for I in Samples'Range loop
         if I /= 5 then
            R := Cohen_Sutherland_Clip
              (Make_Segment (Samples (I), (5.0, 5.0)), W);
            if R.Status /= Clip_Accept then
               Ok := False;
            elsif not Point_Inside_Window (R.Clipped.P0, W)
              or else not Point_Inside_Window (R.Clipped.P1, W)
            then
               Ok := False;
            end if;
         end if;
      end loop;
      Check (Ok, "clip from every outside region into center Accept");

      R := Cohen_Sutherland_Clip
        (Make_Segment ((-2.0, 11.0), (12.0, 11.0)), W);
      Check (R.Status = Clip_Reject, "above-window horizontal Reject");
      R := Cohen_Sutherland_Clip
        (Make_Segment ((-2.0, -1.0), (12.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "below-window horizontal Reject");
   end;

   ---------------------------------------------------------------------
   Section ("14. Make_Box raise / Same_Clipped_Segment3 / Length edge");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      S3a : constant Segment3 :=
        Make_Segment ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0));
      S3b : constant Segment3 :=
        Make_Segment ((1.0, 0.0, 0.0), (0.0, 0.0, 0.0));
      Bx  : constant Clip_Box := Make_Box (-1.0, -1.0, -1.0, 1.0, 1.0, 1.0);
      R   : Clip_Result_3D;
   begin
      begin
         declare
            Unused : Clip_Box;
         begin
            Unused := Make_Box (0.0, 0.0, 0.0, 0.0, 1.0, 1.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "Make_Box zero X extent raises");
      Check (Approx (Length (S3a), 0.0), "zero-length Segment3");
      Check (Same_Clipped_Segment (S3b, Make_Segment (S3b.P1, S3b.P0)),
             "Same_Clipped_Segment3 undirected");
      R := Cohen_Sutherland_Clip_3D_Lite
        (Make_Segment ((-2.0, 0.0, 0.0), (2.0, 0.0, 0.0)), Bx);
      Check (R.Status = Clip_Accept, "3-D X-through unit box Accept");
      Check (Approx_Vec3 (R.Clipped.P0, (-1.0, 0.0, 0.0)), "3-D unit P0");
      Check (Approx_Vec3 (R.Clipped.P1, (1.0, 0.0, 0.0)), "3-D unit P1");
   end;

   ---------------------------------------------------------------------
   Section ("15. Endpoint on boundary / short clips");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      L : Clip_Result;
   begin
      R := Cohen_Sutherland_Clip (Make_Segment ((0.0, 5.0), (10.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "on left/right edges Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0)), "boundary P0");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0)), "boundary P1");

      R := Cohen_Sutherland_Clip (Make_Segment ((0.0, 0.0), (10.0, 10.0)), W);
      L := Liang_Barsky_Clip_Lite (Make_Segment ((0.0, 0.0), (10.0, 10.0)), W);
      Check (R.Status = Clip_Accept, "corner diagonal Accept");
      Check (Status_Agree (R, L), "corner diagonal CS=LB");

      R := Cohen_Sutherland_Clip (Make_Segment ((11.0, 5.0), (20.0, 5.0)), W);
      Check (R.Status = Clip_Reject, "fully right Reject");
   end;

   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;
