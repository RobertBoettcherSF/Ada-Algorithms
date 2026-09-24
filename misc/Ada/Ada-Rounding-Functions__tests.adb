--  Standalone test suite for Rounding_Functions (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Rounding_Functions; use Rounding_Functions;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   procedure Expect_Out_Of_Range (X : Long_Float; Label : String) is
      R : Integer;
      pragma Unreferenced (R);
   begin
      R := Floor (X);
      Check (False, Label & " (no exception)");
   exception
      when Out_Of_Range =>
         Check (True, Label);
      when others =>
         Check (False, Label & " (wrong exception)");
   end Expect_Out_Of_Range;

begin
   Ada.Text_IO.Put_Line ("Rounding_Functions test suite");
   Ada.Text_IO.Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Sign / In_Domain / Is_Integer");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-13), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects far");
   Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
   Check (Sign (3.0) = 1.0, "Sign(+)");
   Check (Sign (-3.0) = -1.0, "Sign(-)");
   Check (Sign (0.0) = 0.0, "Sign(0)");
   Check (In_Domain (0.0), "In_Domain(0)");
   Check (In_Domain (Max_Abs_Arg), "In_Domain(Max)");
   Check (In_Domain (-Max_Abs_Arg), "In_Domain(-Max)");
   Check (not In_Domain (Max_Abs_Arg + 1.0), "reject above Max");
   Check (Is_Integer (0.0), "Is_Integer(0)");
   Check (Is_Integer (42.0), "Is_Integer(42)");
   Check (Is_Integer (-7.0), "Is_Integer(-7)");
   Check (not Is_Integer (2.5), "not Is_Integer(2.5)");
   Check (not Is_Integer (-2.3), "not Is_Integer(-2.3)");

   ---------------------------------------------------------------------
   Section ("2. Floor — positives, negatives, integers");
   ---------------------------------------------------------------------
   Check (Floor (23.7) = 23, "Floor(23.7)=23");
   Check (Floor (23.2) = 23, "Floor(23.2)=23");
   Check (Floor (0.9) = 0, "Floor(0.9)=0");
   Check (Floor (0.0) = 0, "Floor(0)=0");
   Check (Floor (-23.2) = -24, "Floor(-23.2)=-24");
   Check (Floor (-23.7) = -24, "Floor(-23.7)=-24");
   Check (Floor (-0.1) = -1, "Floor(-0.1)=-1");
   Check (Floor (5.0) = 5, "Floor(5)=5");
   Check (Floor (-5.0) = -5, "Floor(-5)=-5");
   Check (Floor (2.5) = 2, "Floor(2.5)=2");
   Check (Floor (-2.5) = -3, "Floor(-2.5)=-3");
   --  Duality ⌊X⌋ = −⌈−X⌉
   Check (Floor (3.2) = -Ceiling (-3.2), "duality Floor(3.2)");
   Check (Floor (-3.2) = -Ceiling (3.2), "duality Floor(-3.2)");

   ---------------------------------------------------------------------
   Section ("3. Ceiling — positives, negatives, integers");
   ---------------------------------------------------------------------
   Check (Ceiling (23.2) = 24, "Ceiling(23.2)=24");
   Check (Ceiling (23.7) = 24, "Ceiling(23.7)=24");
   Check (Ceiling (0.1) = 1, "Ceiling(0.1)=1");
   Check (Ceiling (0.0) = 0, "Ceiling(0)=0");
   Check (Ceiling (-23.7) = -23, "Ceiling(-23.7)=-23");
   Check (Ceiling (-23.2) = -23, "Ceiling(-23.2)=-23");
   Check (Ceiling (-0.1) = 0, "Ceiling(-0.1)=0");
   Check (Ceiling (5.0) = 5, "Ceiling(5)=5");
   Check (Ceiling (-5.0) = -5, "Ceiling(-5)=-5");
   Check (Ceiling (2.5) = 3, "Ceiling(2.5)=3");
   Check (Ceiling (-2.5) = -2, "Ceiling(-2.5)=-2");

   ---------------------------------------------------------------------
   Section ("4. Truncate vs Floor for negatives");
   ---------------------------------------------------------------------
   Check (Truncate (23.7) = 23, "Truncate(23.7)=23");
   Check (Truncate (-23.7) = -23, "Truncate(-23.7)=-23");
   Check (Truncate (0.9) = 0, "Truncate(0.9)=0");
   Check (Truncate (-0.9) = 0, "Truncate(-0.9)=0");
   Check (Truncate (5.0) = 5, "Truncate(5)=5");
   Check (Truncate (-5.0) = -5, "Truncate(-5)=-5");
   --  For X ≥ 0: Truncate = Floor; for X < 0 non-integer: Truncate ≠ Floor
   Check (Truncate (3.7) = Floor (3.7), "pos Truncate=Floor");
   Check (Truncate (-3.7) /= Floor (-3.7), "neg Truncate≠Floor");
   Check (Truncate (-3.7) = Ceiling (-3.7), "neg Truncate=Ceiling");
   Check (Truncate (-3.7) = -3, "Truncate(-3.7)=-3");
   Check (Floor (-3.7) = -4, "Floor(-3.7)=-4");

   ---------------------------------------------------------------------
   Section ("5. Round_Away_From_Zero (directed)");
   ---------------------------------------------------------------------
   Check (Round_Away_From_Zero (23.2) = 24, "Away(23.2)=24");
   Check (Round_Away_From_Zero (-23.2) = -24, "Away(-23.2)=-24");
   Check (Round_Away_From_Zero (23.0) = 23, "Away(23)=23");
   Check (Round_Away_From_Zero (-23.0) = -23, "Away(-23)=-23");
   Check (Round_Away_From_Zero (0.1) = 1, "Away(0.1)=1");
   Check (Round_Away_From_Zero (-0.1) = -1, "Away(-0.1)=-1");

   ---------------------------------------------------------------------
   Section ("6. Round_Half_Up (ties toward +∞)");
   ---------------------------------------------------------------------
   Check (Round_Half_Up (23.5) = 24, "HalfUp(23.5)=24");
   Check (Round_Half_Up (-23.5) = -23, "HalfUp(-23.5)=-23");
   Check (Round_Half_Up (2.5) = 3, "HalfUp(2.5)=3");
   Check (Round_Half_Up (-2.5) = -2, "HalfUp(-2.5)=-2");
   Check (Round_Half_Up (2.4) = 2, "HalfUp(2.4)=2");
   Check (Round_Half_Up (2.6) = 3, "HalfUp(2.6)=3");
   Check (Round_Half_Up (-2.4) = -2, "HalfUp(-2.4)=-2");
   Check (Round_Half_Up (-2.6) = -3, "HalfUp(-2.6)=-3");
   Check (Round_Half_Up (0.5) = 1, "HalfUp(0.5)=1");
   Check (Round_Half_Up (-0.5) = 0, "HalfUp(-0.5)=0");

   ---------------------------------------------------------------------
   Section ("7. Round_Half_Down (ties toward −∞)");
   ---------------------------------------------------------------------
   Check (Round_Half_Down (23.5) = 23, "HalfDown(23.5)=23");
   Check (Round_Half_Down (-23.5) = -24, "HalfDown(-23.5)=-24");
   Check (Round_Half_Down (2.5) = 2, "HalfDown(2.5)=2");
   Check (Round_Half_Down (-2.5) = -3, "HalfDown(-2.5)=-3");
   Check (Round_Half_Down (0.5) = 0, "HalfDown(0.5)=0");
   Check (Round_Half_Down (-0.5) = -1, "HalfDown(-0.5)=-1");

   ---------------------------------------------------------------------
   Section ("8. Round_Half_Away_From_Zero (school rule)");
   ---------------------------------------------------------------------
   Check (Round_Half_Away_From_Zero (2.5) = 3, "HalfAway(2.5)=3");
   Check (Round_Half_Away_From_Zero (-2.5) = -3, "HalfAway(-2.5)=-3");
   Check (Round_Half_Away_From_Zero (3.5) = 4, "HalfAway(3.5)=4");
   Check (Round_Half_Away_From_Zero (-3.5) = -4, "HalfAway(-3.5)=-4");
   Check (Round_Half_Away_From_Zero (2.4) = 2, "HalfAway(2.4)=2");
   Check (Round_Half_Away_From_Zero (-2.4) = -2, "HalfAway(-2.4)=-2");
   Check (Round_Half_Away_From_Zero (2.6) = 3, "HalfAway(2.6)=3");
   Check (Round_Half_Away_From_Zero (-2.6) = -3, "HalfAway(-2.6)=-3");
   Check (Round_Half_Away_From_Zero (0.5) = 1, "HalfAway(0.5)=1");
   Check (Round_Half_Away_From_Zero (-0.5) = -1, "HalfAway(-0.5)=-1");

   ---------------------------------------------------------------------
   Section ("9. Round_Half_Toward_Zero");
   ---------------------------------------------------------------------
   Check (Round_Half_Toward_Zero (2.5) = 2, "HalfToZero(2.5)=2");
   Check (Round_Half_Toward_Zero (-2.5) = -2, "HalfToZero(-2.5)=-2");
   Check (Round_Half_Toward_Zero (3.5) = 3, "HalfToZero(3.5)=3");
   Check (Round_Half_Toward_Zero (-3.5) = -3, "HalfToZero(-3.5)=-3");
   Check (Round_Half_Toward_Zero (2.6) = 3, "HalfToZero(2.6)=3");
   Check (Round_Half_Toward_Zero (-2.6) = -3, "HalfToZero(-2.6)=-3");
   Check (Round_Half_Toward_Zero (0.5) = 0, "HalfToZero(0.5)=0");
   Check (Round_Half_Toward_Zero (-0.5) = 0, "HalfToZero(-0.5)=0");

   ---------------------------------------------------------------------
   Section ("10. Round_Half_To_Even (banker's) — classic ties");
   ---------------------------------------------------------------------
   Check (Round_Half_To_Even (2.5) = 2, "Even(2.5)=2");
   Check (Round_Half_To_Even (3.5) = 4, "Even(3.5)=4");
   Check (Round_Half_To_Even (4.5) = 4, "Even(4.5)=4");
   Check (Round_Half_To_Even (5.5) = 6, "Even(5.5)=6");
   Check (Round_Half_To_Even (-2.5) = -2, "Even(-2.5)=-2");
   Check (Round_Half_To_Even (-3.5) = -4, "Even(-3.5)=-4");
   Check (Round_Half_To_Even (-4.5) = -4, "Even(-4.5)=-4");
   Check (Round_Half_To_Even (-5.5) = -6, "Even(-5.5)=-6");
   Check (Round_Half_To_Even (23.5) = 24, "Even(23.5)=24");
   Check (Round_Half_To_Even (24.5) = 24, "Even(24.5)=24");
   Check (Round_Half_To_Even (-23.5) = -24, "Even(-23.5)=-24");
   Check (Round_Half_To_Even (-24.5) = -24, "Even(-24.5)=-24");
   --  Non-ties: ordinary nearest
   Check (Round_Half_To_Even (2.4) = 2, "Even(2.4)=2");
   Check (Round_Half_To_Even (2.6) = 3, "Even(2.6)=3");
   Check (Round_Half_To_Even (-2.4) = -2, "Even(-2.4)=-2");
   Check (Round_Half_To_Even (-2.6) = -3, "Even(-2.6)=-3");
   Check (Round_Half_To_Even (0.5) = 0, "Even(0.5)=0");
   Check (Round_Half_To_Even (1.5) = 2, "Even(1.5)=2");
   Check (Round_Half_To_Even (-0.5) = 0, "Even(-0.5)=0");
   Check (Round_Half_To_Even (-1.5) = -2, "Even(-1.5)=-2");

   ---------------------------------------------------------------------
   Section ("11. Round_Half_To_Odd");
   ---------------------------------------------------------------------
   Check (Round_Half_To_Odd (2.5) = 3, "Odd(2.5)=3");
   Check (Round_Half_To_Odd (3.5) = 3, "Odd(3.5)=3");
   Check (Round_Half_To_Odd (-2.5) = -3, "Odd(-2.5)=-3");
   Check (Round_Half_To_Odd (-3.5) = -3, "Odd(-3.5)=-3");
   Check (Round_Half_To_Odd (0.5) = 1, "Odd(0.5)=1");
   Check (Round_Half_To_Odd (-0.5) = -1, "Odd(-0.5)=-1");

   ---------------------------------------------------------------------
   Section ("12. Frac / Floor_Frac / Is_Half_Tie");
   ---------------------------------------------------------------------
   Check (Near (Frac (3.7), 0.7), "Frac(3.7)≈0.7");
   Check (Near (Frac (-3.7), -0.7), "Frac(-3.7)≈-0.7");
   Check (Near (Frac (5.0), 0.0), "Frac(5)=0");
   Check (Near (Floor_Frac (3.7), 0.7), "Floor_Frac(3.7)≈0.7");
   Check (Near (Floor_Frac (-3.7), 0.3), "Floor_Frac(-3.7)≈0.3");
   Check (Near (Floor_Frac (-3.0), 0.0), "Floor_Frac(-3)=0");
   Check (Is_Half_Tie (2.5), "Is_Half_Tie(2.5)");
   Check (Is_Half_Tie (-2.5), "Is_Half_Tie(-2.5)");
   Check (Is_Half_Tie (0.5), "Is_Half_Tie(0.5)");
   Check (not Is_Half_Tie (2.4), "not Is_Half_Tie(2.4)");
   Check (not Is_Half_Tie (3.0), "not Is_Half_Tie(3)");

   ---------------------------------------------------------------------
   Section ("13. Round_To_Decimals / Round_To_Decimals_Even");
   ---------------------------------------------------------------------
   Check (Near (Round_To_Decimals (3.14159, 2), 3.14), "ToDec(π,2)≈3.14");
   Check (Near (Round_To_Decimals (3.14159, 3), 3.142), "ToDec(π,3)≈3.142");
   Check (Near (Round_To_Decimals (1.25, 1), 1.3), "ToDec(1.25,1) half-away→1.3");
   Check (Near (Round_To_Decimals (-1.25, 1), -1.3), "ToDec(-1.25,1)→-1.3");
   Check (Near (Round_To_Decimals (2.5, 0), 3.0), "ToDec(2.5,0)→3");
   Check (Near (Round_To_Decimals_Even (2.5, 0), 2.0), "ToDecEven(2.5,0)→2");
   Check (Near (Round_To_Decimals_Even (3.5, 0), 4.0), "ToDecEven(3.5,0)→4");
   Check (Near (Round_To_Decimals_Even (1.25, 1), 1.2), "ToDecEven(1.25,1)→1.2");
   Check (Near (Round_To_Decimals_Even (1.35, 1), 1.4), "ToDecEven(1.35,1)→1.4");
   Check (Near (Round_To_Decimals (9.994, 2), 9.99), "ToDec(9.994,2)");
   Check (Near (Round_To_Decimals (0.0, 5), 0.0), "ToDec(0,5)");
   Check (Near (Round_To_Decimals (-2.71828, 3), -2.718), "ToDec(-e,3)");

   ---------------------------------------------------------------------
   Section ("14. Domain / Out_Of_Range");
   ---------------------------------------------------------------------
   Expect_Out_Of_Range (Max_Abs_Arg + 10.0, "Floor above Max → Out_Of_Range");
   Expect_Out_Of_Range (-(Max_Abs_Arg + 10.0), "Floor below -Max → Out_Of_Range");
   begin
      declare
         R : constant Integer := Floor (Max_Abs_Arg);
      begin
         Check (R = Integer (Max_Abs_Arg), "Floor(Max_Abs_Arg) ok");
      end;
   exception
      when others =>
         Check (False, "Floor(Max_Abs_Arg) ok");
   end;
   begin
      declare
         R : constant Integer := Truncate (-Max_Abs_Arg);
      begin
         Check (R = -Integer (Max_Abs_Arg), "Truncate(-Max) ok");
      end;
   exception
      when others =>
         Check (False, "Truncate(-Max) ok");
   end;

   ---------------------------------------------------------------------
   Section ("15. Integers are fixed points of all modes");
   ---------------------------------------------------------------------
   declare
      Vals : constant array (Positive range <>) of Long_Float :=
        [0.0, 1.0, -1.0, 42.0, -42.0, 100.0, -100.0];
      All_Ok : Boolean := True;
   begin
      for V of Vals loop
         declare
            K : constant Integer := Integer (V);
         begin
            if Floor (V) /= K
              or else Ceiling (V) /= K
              or else Truncate (V) /= K
              or else Round_Half_Up (V) /= K
              or else Round_Half_Away_From_Zero (V) /= K
              or else Round_Half_To_Even (V) /= K
              or else Round_Half_Toward_Zero (V) /= K
              or else Round_Away_From_Zero (V) /= K
            then
               All_Ok := False;
            end if;
         end;
      end loop;
      Check (All_Ok, "integers fixed by all modes");
   end;

   ---------------------------------------------------------------------
   Section ("16. Cross-mode contrasts at ±2.5 / ±3.5");
   ---------------------------------------------------------------------
   Check (Floor (2.5) = 2, "contrast Floor(2.5)");
   Check (Ceiling (2.5) = 3, "contrast Ceiling(2.5)");
   Check (Truncate (2.5) = 2, "contrast Truncate(2.5)");
   Check (Round_Half_Up (2.5) = 3, "contrast HalfUp(2.5)");
   Check (Round_Half_Away_From_Zero (2.5) = 3, "contrast HalfAway(2.5)");
   Check (Round_Half_Toward_Zero (2.5) = 2, "contrast HalfToZero(2.5)");
   Check (Round_Half_To_Even (2.5) = 2, "contrast Even(2.5)");
   Check (Round_Half_To_Odd (2.5) = 3, "contrast Odd(2.5)");

   Check (Floor (-2.5) = -3, "contrast Floor(-2.5)");
   Check (Ceiling (-2.5) = -2, "contrast Ceiling(-2.5)");
   Check (Truncate (-2.5) = -2, "contrast Truncate(-2.5)");
   Check (Round_Half_Up (-2.5) = -2, "contrast HalfUp(-2.5)");
   Check (Round_Half_Away_From_Zero (-2.5) = -3, "contrast HalfAway(-2.5)");
   Check (Round_Half_Toward_Zero (-2.5) = -2, "contrast HalfToZero(-2.5)");
   Check (Round_Half_To_Even (-2.5) = -2, "contrast Even(-2.5)");
   Check (Round_Half_To_Odd (-2.5) = -3, "contrast Odd(-2.5)");

   Check (Round_Half_To_Even (3.5) = 4, "contrast Even(3.5)");
   Check (Round_Half_To_Odd (3.5) = 3, "contrast Odd(3.5)");
   Check (Round_Half_Up (3.5) = 4, "contrast HalfUp(3.5)");
   Check (Round_Half_Toward_Zero (3.5) = 3, "contrast HalfToZero(3.5)");

   ---------------------------------------------------------------------
   Section ("17. Summary");
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " Passed," & Fail_Count'Image
      & " Failed");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
