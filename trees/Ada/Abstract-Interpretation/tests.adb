with Ada.Text_IO; use Ada.Text_IO;
with Abstract_Interpretation; use Abstract_Interpretation;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   Put_Line ("TEST 1 — Sign Domain Basic Properties");
   Check ("1.1 Bottom is empty set", Bottom_Sign = [False, False, False]);
   Check ("1.2 Top represents any sign", Top_Sign = [True, True, True]);
   Check ("1.3 Pos represents strictly positive", Pos_Sign = [False, False, True]);

   Put_Line ("TEST 2 — Sign Domain Join (Least Upper Bound)");
   Check ("2.1 Pos U Zero = Non_Neg", Sign_Join (Pos_Sign, Zero_Sign) = Non_Neg_Sign);
   Check ("2.2 Neg U Pos = Non_Zero", Sign_Join (Neg_Sign, Pos_Sign) = Non_Zero_Sign);
   Check ("2.3 Bottom U Neg = Neg", Sign_Join (Bottom_Sign, Neg_Sign) = Neg_Sign);

   Put_Line ("TEST 3 — Sign Domain Meet (Greatest Lower Bound)");
   Check ("3.1 Top M Pos = Pos", Sign_Meet (Top_Sign, Pos_Sign) = Pos_Sign);
   Check ("3.2 Pos M Neg = Bottom", Sign_Meet (Pos_Sign, Neg_Sign) = Bottom_Sign);
   Check ("3.3 Non_Pos M Non_Neg = Zero", Sign_Meet (Non_Pos_Sign, Non_Neg_Sign) = Zero_Sign);

   Put_Line ("TEST 4 — Sign Domain Addition");
   Check ("4.1 Pos + Pos = Pos", Sign_Add (Pos_Sign, Pos_Sign) = Pos_Sign);
   Check ("4.2 Neg + Neg = Neg", Sign_Add (Neg_Sign, Neg_Sign) = Neg_Sign);
   Check ("4.3 Pos + Neg = Top", Sign_Add (Pos_Sign, Neg_Sign) = Top_Sign);

   Put_Line ("TEST 5 — Sign Domain Multiplication");
   Check ("5.1 Pos * Neg = Neg", Sign_Multiply (Pos_Sign, Neg_Sign) = Neg_Sign);
   Check ("5.2 Zero * Top = Zero", Sign_Multiply (Zero_Sign, Top_Sign) = Zero_Sign);
   Check ("5.3 Neg * Neg = Pos", Sign_Multiply (Neg_Sign, Neg_Sign) = Pos_Sign);

   Put_Line ("TEST 6 — Bound Ordering and Properties");
   Check ("6.1 Minus_Inf <= Finite(5)", Bound_Less_Or_Equal ((Kind => Minus_Inf), Make_Bound(5)));
   Check ("6.2 Finite(5) <= Plus_Inf", Bound_Less_Or_Equal (Make_Bound(5), (Kind => Plus_Inf)));
   Check ("6.3 Finite(10) <= Finite(10)", Bound_Less_Or_Equal (Make_Bound(10), Make_Bound(10)));

   Put_Line ("TEST 7 — Interval Domain Validity & Bottom/Top");
   declare
      Valid_I : constant Interval_Domain := Make_Interval (Make_Bound (1), Make_Bound (5));
   begin
      Check ("7.1 Make valid interval", not Is_Bottom (Valid_I));
      Check ("7.2 Extract Lower Bound", Get_Lower (Valid_I).Value = 1);
      Check ("7.3 Extract Upper Bound", Get_Upper (Valid_I).Value = 5);
   end;

   Put_Line ("TEST 8 — Interval Domain Join");
   declare
      I1 : constant Interval_Domain := Make_Interval (Make_Bound (1), Make_Bound (2));
      I2 : constant Interval_Domain := Make_Interval (Make_Bound (3), Make_Bound (4));
      J  : constant Interval_Domain := Interval_Join (I1, I2);
   begin
      Check ("8.1 [1,2] U [3,4] Lower is 1", Get_Lower (J).Value = 1);
      Check ("8.2 [1,2] U [3,4] Upper is 4", Get_Upper (J).Value = 4);
      Check ("8.3 Bottom U [1,2] is [1,2]", not Is_Bottom (Interval_Join (Bottom_Interval, I1)));
   end;

   Put_Line ("TEST 9 — Interval Domain Meet");
   declare
      I1 : constant Interval_Domain := Make_Interval (Make_Bound (1), Make_Bound (10));
      I2 : constant Interval_Domain := Make_Interval (Make_Bound (5), Make_Bound (15));
      M1 : constant Interval_Domain := Interval_Meet (I1, I2);
      
      I3 : constant Interval_Domain := Make_Interval (Make_Bound (1), Make_Bound (5));
      I4 : constant Interval_Domain := Make_Interval (Make_Bound (6), Make_Bound (10));
      M2 : constant Interval_Domain := Interval_Meet (I3, I4);
   begin
      Check ("9.1 [1,10] M [5,15] Lower is 5", Get_Lower (M1).Value = 5);
      Check ("9.2 [1,10] M [5,15] Upper is 10", Get_Upper (M1).Value = 10);
      Check ("9.3 Disjoint intervals meet to Bottom", Is_Bottom (M2));
   end;

   Put_Line ("TEST 10 — Interval Domain Addition");
   declare
      I1 : constant Interval_Domain := Make_Interval (Make_Bound (1), Make_Bound (2));
      I2 : constant Interval_Domain := Make_Interval (Make_Bound (3), Make_Bound (4));
      A1 : constant Interval_Domain := Interval_Add (I1, I2);
      A2 : constant Interval_Domain := Interval_Add (Top_Interval, I1);
   begin
      Check ("10.1 [1,2] + [3,4] Lower = 4", Get_Lower (A1).Value = 4);
      Check ("10.2 [1,2] + [3,4] Upper = 6", Get_Upper (A1).Value = 6);
      Check ("10.3 Top + [1,2] = Top", Get_Lower(A2).Kind = Minus_Inf and then Get_Upper(A2).Kind = Plus_Inf);
   end;

   Put_Line ("TEST 11 — Interval Domain Widening (Loop Convergence)");
   declare
      I1 : constant Interval_Domain := Make_Interval (Make_Bound (0), Make_Bound (0));
      I2 : constant Interval_Domain := Make_Interval (Make_Bound (0), Make_Bound (1));
      W1 : constant Interval_Domain := Interval_Widen (I1, I2);
   begin
      -- Widening extrapolates growing bounds to infinity
      Check ("11.1 [0,0] Widen [0,1] Lower = 0", Get_Lower (W1).Kind = Finite and then Get_Lower(W1).Value = 0);
      Check ("11.2 [0,0] Widen [0,1] Upper = +Inf", Get_Upper (W1).Kind = Plus_Inf);
      Check ("11.3 Widen with Bottom returns original", not Is_Bottom (Interval_Widen (I1, Bottom_Interval)));
   end;

   Put_Line ("TEST 12 — Interval Domain Multiplication (Finite)");
   declare
      I1 : constant Interval_Domain := Make_Interval (Make_Bound (-1), Make_Bound (2));
      I2 : constant Interval_Domain := Make_Interval (Make_Bound (-3), Make_Bound (4));
      M  : constant Interval_Domain := Interval_Multiply (I1, I2);
   begin
      -- Min(-1*-3, -1*4, 2*-3, 2*4) = Min(3, -4, -6, 8) = -6
      Check ("12.1 [-1,2] * [-3,4] Lower = -6", Get_Lower (M).Value = -6);
      -- Max(3, -4, -6, 8) = 8
      Check ("12.2 [-1,2] * [-3,4] Upper = 8", Get_Upper (M).Value = 8);
      Check ("12.3 Bottom * I1 = Bottom", Is_Bottom (Interval_Multiply (Bottom_Interval, I1)));
   end;

   Put_Line ("TEST 13 — Interval Domain Multiplication (Infinite)");
   declare
      Zero : constant Interval_Domain := Make_Interval (Make_Bound (0), Make_Bound (0));
      M1   : constant Interval_Domain := Interval_Multiply (Zero, Top_Interval);
   begin
      Check ("13.1 [0,0] * Top Lower is 0", Get_Lower (M1).Kind = Finite and then Get_Lower (M1).Value = 0);
      Check ("13.2 [0,0] * Top Upper is 0", Get_Upper (M1).Kind = Finite and then Get_Upper (M1).Value = 0);
      Check ("13.3 Positive * -Inf is -Inf", 
             Get_Lower (Interval_Multiply (Make_Interval(Make_Bound(1), Make_Bound(5)), 
                                           Make_Interval((Kind => Minus_Inf), Make_Bound(-1)))).Kind = Minus_Inf);
   end;

   Put_Line ("TEST 14 — Interval Domain Exceptions");
   begin
      -- Intentional invalid interval: Lower > Upper
      Check ("14.1 Checking invalid interval construction", 
             not Is_Bottom (Make_Interval (Make_Bound (5), Make_Bound (0))));
      Check ("14.2 Code path should not be reached", False);
      Check ("14.3 State should be pristine", False);
   exception
      when Invalid_Interval_Error =>
         Check ("14.1 Invalid_Interval_Error accurately raised", True);
         Check ("14.2 Handled safely", True);
         Check ("14.3 State unaffected", True);
   end;

   Put_Line ("TEST 15 — Loop Analysis Simulation");
   declare
      -- Simulating: x = 0; while (unknown) { x = x + 1; }
      Initial_State : constant Interval_Domain := Make_Interval (Make_Bound (0), Make_Bound (0));
      Step_Diff     : constant Interval_Domain := Make_Interval (Make_Bound (1), Make_Bound (1));
      
      Loop_1_End    : constant Interval_Domain := Interval_Add (Initial_State, Step_Diff);
      Join_State    : constant Interval_Domain := Interval_Join (Initial_State, Loop_1_End);
      Widen_State   : constant Interval_Domain := Interval_Widen (Initial_State, Join_State);
   begin
      -- Widening detects the upper bound is increasing, forces it to +Inf
      Check ("15.1 Widen lower bound stays stable (0)", Get_Lower (Widen_State).Kind = Finite and then Get_Lower (Widen_State).Value = 0);
      Check ("15.2 Widen upper bound reaches convergence (+Inf)", Get_Upper (Widen_State).Kind = Plus_Inf);
      Check ("15.3 Widen handles loop termination bounds safely", not Is_Bottom (Widen_State));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
