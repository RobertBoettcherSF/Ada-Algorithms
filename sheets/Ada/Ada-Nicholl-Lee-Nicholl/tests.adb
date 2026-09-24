--  Standalone test suite for Nicholl_Lee_Nicholl (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nicholl_Lee_Nicholl; use Nicholl_Lee_Nicholl;

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
   Put_Line ("Nicholl_Lee_Nicholl test suite");
   Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Dot / Cross_Z");
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
      Check (Approx (Cross_Z ((1.0, 0.0), (0.0, 1.0)), 1.0),
             "Cross_Z of basis is 1");
      Check (Near_Point (A, A), "Near_Point identical");
      Check (not Near_Point (A, B), "Near_Point distinct");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Window / Is_Valid_Window");
   ---------------------------------------------------------------------
   declare
      W  : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 5.0);
      Bad : Clip_Window;
   begin
      Check (Is_Valid_Window (W), "Make_Window yields valid window");
      Check (Approx (W.X_Max - W.X_Min, 10.0), "window width 10");
      Check (Approx (W.Y_Max - W.Y_Min, 5.0), "window height 5");
      Bad := (0.0, 0.0, 0.0, 1.0);
      Check (not Is_Valid_Window (Bad), "zero-width window invalid");
      Bad := (0.0, 2.0, 1.0, 1.0);
      Check (not Is_Valid_Window (Bad), "inverted Y window invalid");
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
   Section ("4. Classify_Point / Region_Is_Corner / Region_Is_Edge");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
   begin
      Check (Classify_Point ((5.0, 5.0), W) = Inside, "center => Inside");
      Check (Classify_Point ((-1.0, 5.0), W) = Left, "left edge region");
      Check (Classify_Point ((11.0, 5.0), W) = Right, "right edge region");
      Check (Classify_Point ((5.0, 11.0), W) = Top, "top edge region");
      Check (Classify_Point ((5.0, -1.0), W) = Bottom, "bottom edge region");
      Check (Classify_Point ((-1.0, 11.0), W) = Left_Top, "left-top corner");
      Check (Classify_Point ((11.0, -1.0), W) = Right_Bottom,
             "right-bottom corner");
      Check (Region_Is_Corner (Left_Top), "Left_Top is corner");
      Check (Region_Is_Edge (Left), "Left is edge");
      Check (not Region_Is_Corner (Inside), "Inside is not corner");
   end;

   ---------------------------------------------------------------------
   Section ("5. Intersection_With_Edge");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((-5.0, 5.0), (15.0, 5.0));
      L : constant Vec2 := Intersection_With_Edge (S, W, Left_Edge);
      R : constant Vec2 := Intersection_With_Edge (S, W, Right_Edge);
      V : constant Segment := Make_Segment ((5.0, -2.0), (5.0, 12.0));
      B : constant Vec2 := Intersection_With_Edge (V, W, Bottom_Edge);
      T : constant Vec2 := Intersection_With_Edge (V, W, Top_Edge);
      Raised : Boolean := False;
   begin
      Check (Approx_Vec (L, (0.0, 5.0)), "hit left at (0,5)");
      Check (Approx_Vec (R, (10.0, 5.0)), "hit right at (10,5)");
      Check (Approx_Vec (B, (5.0, 0.0)), "hit bottom at (5,0)");
      Check (Approx_Vec (T, (5.0, 10.0)), "hit top at (5,10)");
      begin
         declare
            Dummy : Vec2;
         begin
            Dummy := Intersection_With_Edge
              (Make_Segment ((1.0, 1.0), (1.0, 2.0)), W, Left_Edge);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "parallel to left raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("6. Canonicalize_Segment / inverse transform");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      S_Out : Segment;
      W_Out : Clip_Window;
      T     : Canonical_Transform;
      Fam   : Canonical_Family;
      Back  : Segment;
   begin
      --  P0 already Left
      Canonicalize_Segment
        (Make_Segment ((-2.0, 5.0), (12.0, 5.0)), W,
         S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Left, "Left P0 stays Canon_Left");
      Check (Classify_Point (S_Out.P0, W_Out) = Left, "canonical P0 is Left");
      Check (not T.Flip_X and then not T.Flip_Y and then not T.Rot90,
             "no transform needed for Left");

      --  P0 Right -> Flip_X -> Left
      Canonicalize_Segment
        (Make_Segment ((12.0, 5.0), (-2.0, 5.0)), W,
         S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Left, "Right maps to Canon_Left");
      Check (T.Flip_X, "Right uses Flip_X");
      Back := Apply_Inverse_Segment (S_Out, T, W);
      Check (Approx_Vec (Back.P0, (12.0, 5.0)), "inverse restores P0");
      Check (Approx_Vec (Back.P1, (-2.0, 5.0)), "inverse restores P1");

      --  P0 Top -> Rot90 -> Left
      Canonicalize_Segment
        (Make_Segment ((5.0, 12.0), (5.0, -2.0)), W,
         S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Left, "Top maps to Canon_Left via Rot90");
      Check (T.Rot90, "Top uses Rot90");
      Check (Classify_Point (S_Out.P0, W_Out) = Left,
             "after Rot90 P0 is Left");
   end;

   ---------------------------------------------------------------------
   Section ("7. Clip_Without_Canonicalize (Inside / Left / Left_Top)");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      Raised : Boolean := False;
   begin
      R := Clip_Without_Canonicalize
        (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      Check (R.Status = Clip_Accept, "fully inside accepted");
      Check (Approx_Vec (R.Clipped.P0, (2.0, 2.0)), "inside P0 unchanged");
      Check (Approx_Vec (R.Clipped.P1, (8.0, 8.0)), "inside P1 unchanged");

      R := Clip_Without_Canonicalize
        (Make_Segment ((2.0, 2.0), (2.0, 20.0)), W);
      Check (R.Status = Clip_Accept, "inside->top clip accepted");
      Check (Approx (R.Clipped.P1.Y, 10.0), "P1 clipped to top y=10");

      R := Clip_Without_Canonicalize
        (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "Left through window accepted");
      Check (Approx (R.Clipped.P0.X, 0.0), "enters at left x=0");
      Check (Approx (R.Clipped.P1.X, 10.0), "exits at right x=10");

      R := Clip_Without_Canonicalize
        (Make_Segment ((-2.0, 12.0), (5.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "Left_Top into window accepted");

      begin
         declare
            Ignore : Clip_Result;
         begin
            Ignore := Clip_Without_Canonicalize
              (Make_Segment ((12.0, 5.0), (15.0, 5.0)), W);
            if Ignore.Status = Clip_Accept then
               Raised := False;
            end if;
         end;
      exception
         when Not_Canonical =>
            Raised := True;
      end;
      Check (Raised, "Right P0 raises Not_Canonical");
   end;

   ---------------------------------------------------------------------
   Section ("8. Nicholl_Lee_Nicholl_Clip fixtures");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 100.0, 100.0);
      R : Clip_Result;
   begin
      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((20.0, 20.0), (80.0, 80.0)), W);
      Check (R.Status = Clip_Accept, "fully inside accept");
      Check (Approx_Vec (R.Clipped.P0, (20.0, 20.0)), "inside endpoints P0");
      Check (Approx_Vec (R.Clipped.P1, (80.0, 80.0)), "inside endpoints P1");

      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((-10.0, 50.0), (50.0, 50.0)), W);
      Check (R.Status = Clip_Accept, "enter from left accept");
      Check (Approx (R.Clipped.P0.X, 0.0), "clipped start on left edge");
      Check (Point_Inside_Window (R.Clipped.P1, W), "end inside");

      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((-20.0, -20.0), (-5.0, -5.0)), W);
      Check (R.Status = Clip_Reject, "fully outside reject");

      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((-10.0, 50.0), (110.0, 50.0)), W);
      Check (R.Status = Clip_Accept, "cross horizontal accept");
      Check (Approx (Length (R.Clipped), 100.0), "full width length 100");

      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((50.0, 50.0), (50.0, 50.0)), W);
      Check (R.Status = Clip_Accept, "degenerate inside point accept");
   end;

   ---------------------------------------------------------------------
   Section ("9. Cohen_Sutherland_Clip reference");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Cohen_Sutherland_Clip
        (Make_Segment ((1.0, 1.0), (9.0, 9.0)), W);
      Check (R.Status = Clip_Accept, "CS fully inside");
      Check (Approx_Vec (R.Clipped.P0, (1.0, 1.0)), "CS P0");
      Check (Approx_Vec (R.Clipped.P1, (9.0, 9.0)), "CS P1");

      R := Cohen_Sutherland_Clip
        (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "CS crosses window");
      Check (Approx (R.Clipped.P0.X, 0.0) or else Approx (R.Clipped.P1.X, 0.0),
             "CS hits left");
      Check (Approx (R.Clipped.P0.X, 10.0)
             or else Approx (R.Clipped.P1.X, 10.0),
             "CS hits right");

      R := Cohen_Sutherland_Clip
        (Make_Segment ((-2.0, -2.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "CS fully outside");
   end;

   ---------------------------------------------------------------------
   Section ("10. NLN vs Cohen–Sutherland agreement (fixtures)");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 100.0, 80.0);
      type Pair is record
         A, B : Vec2;
      end record;
      Fixtures : constant array (Positive range <>) of Pair :=
        [((10.0, 10.0), (90.0, 70.0)),
         ((-20.0, 40.0), (50.0, 40.0)),
         ((50.0, -10.0), (50.0, 90.0)),
         ((-10.0, -10.0), (110.0, 90.0)),
         ((110.0, 40.0), (120.0, 50.0)),
         ((-30.0, 90.0), (30.0, 40.0)),
         ((120.0, -20.0), (50.0, 40.0)),
         ((40.0, 120.0), (40.0, -20.0))];
   begin
      for F of Fixtures loop
         declare
            S  : constant Segment := Make_Segment (F.A, F.B);
            N  : constant Clip_Result := Nicholl_Lee_Nicholl_Clip (S, W);
            C  : constant Clip_Result := Cohen_Sutherland_Clip (S, W);
         begin
            Check (Status_Agree (N, C),
                   "NLN agrees with CS on fixture");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. NLN vs CS random-ish lattice segments");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (-5.0, -5.0, 5.0, 5.0);
      Agree : Natural := 0;
      Total : constant Natural := 16;
      Xs : constant array (1 .. 4) of Real := [-8.0, -2.0, 2.0, 8.0];
      Ys : constant array (1 .. 4) of Real := [-8.0, -2.0, 2.0, 8.0];
   begin
      for I in Xs'Range loop
         for J in Ys'Range loop
            declare
               S : constant Segment :=
                 Make_Segment ((Xs (I), Ys (J)),
                               (Ys (J), Xs (I)));  -- swap-ish endpoint
               N : constant Clip_Result := Nicholl_Lee_Nicholl_Clip (S, W);
               C : constant Clip_Result := Cohen_Sutherland_Clip (S, W);
            begin
               if Status_Agree (N, C) then
                  Agree := Agree + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Agree = Total, "all 16 lattice segments agree");
      Check (Agree > 0, "at least one lattice agreement");
      Check (Agree >= Total / 2, "majority of lattice agrees");
   end;

   ---------------------------------------------------------------------
   Section ("12. Corner / edge canonicalize families");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 4.0, 2.0);
      S_Out : Segment;
      W_Out : Clip_Window;
      T : Canonical_Transform;
      Fam : Canonical_Family;
   begin
      Canonicalize_Segment
        (Make_Segment ((-1.0, 3.0), (2.0, 1.0)), W, S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Left_Top, "Left_Top stays Left_Top");
      Check (Classify_Point (S_Out.P0, W_Out) = Left_Top,
             "canonical P0 Left_Top");

      Canonicalize_Segment
        (Make_Segment ((5.0, 3.0), (2.0, 1.0)), W, S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Left_Top, "Right_Top -> Left_Top");
      Check (T.Flip_X, "Right_Top Flip_X");

      Canonicalize_Segment
        (Make_Segment ((-1.0, -1.0), (2.0, 1.0)), W, S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Left_Top, "Left_Bottom -> Left_Top via Flip_Y");
      Check (T.Flip_Y, "Left_Bottom Flip_Y");

      Canonicalize_Segment
        (Make_Segment ((1.0, 1.0), (3.0, 1.5)), W, S_Out, W_Out, T, Fam);
      Check (Fam = Canon_Inside, "Inside stays Inside");
   end;

   ---------------------------------------------------------------------
   Section ("13. Same_Clipped_Segment / undirected equality");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 0.0));
      B : constant Segment := Make_Segment ((10.0, 0.0), (0.0, 0.0));
      C : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 1.0));
   begin
      Check (Same_Clipped_Segment (A, A), "identical segments equal");
      Check (Same_Clipped_Segment (A, B), "reversed segments equal");
      Check (not Same_Clipped_Segment (A, C), "different segments unequal");
   end;

   ---------------------------------------------------------------------
   Section ("14. Named exceptions");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 1.0, 1.0);
      Saw_Degenerate : Boolean := False;
      Saw_Not_Canon  : Boolean := False;
   begin
      begin
         declare
            Dummy : Vec2;
         begin
            Dummy := Intersection_With_Edge
              (Make_Segment ((0.0, 0.0), (0.0, 1.0)), W, Right_Edge);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Degenerate_Geometry =>
            Saw_Degenerate := True;
      end;
      Check (Saw_Degenerate, "vertical || right => Degenerate_Geometry");

      begin
         declare
            Dummy : Clip_Result;
         begin
            Dummy := Clip_Without_Canonicalize
              (Make_Segment ((2.0, 0.5), (3.0, 0.5)), W);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Not_Canonical =>
            Saw_Not_Canon := True;
      end;
      Check (Saw_Not_Canon, "non-canonical P0 => Not_Canonical");
      Check (Is_Valid_Window (W), "fixture window still valid");
   end;

   ---------------------------------------------------------------------
   Section ("15. Diagonal / vertical / horizontal clips");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      C : Clip_Result;
   begin
      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      C := Cohen_Sutherland_Clip
        (Make_Segment ((-5.0, -5.0), (15.0, 15.0)), W);
      Check (R.Status = Clip_Accept, "diagonal through accept");
      Check (Status_Agree (R, C), "diagonal NLN=CS");
      Check (Approx (R.Clipped.P0.X, R.Clipped.P0.Y),
             "diagonal clip stays on y=x");

      R := Nicholl_Lee_Nicholl_Clip
        (Make_Segment ((5.0, -5.0), (5.0, 15.0)), W);
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
