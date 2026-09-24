--  Standalone test suite for Hungarian_Algorithm.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Hungarian_Algorithm; use Hungarian_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Cost_Of (X : Integer) return Cost_Value is (Cost_Value (X));

   function Clear_Raises (Size : Natural) return Boolean is
      P : Problem;
   begin
      Clear (P, Size);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Set_Cost_Raises
     (P : in out Problem; Row, Col : Index; Cost : Integer) return Boolean
   is
   begin
      Set_Cost (P, Row, Col, Cost);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Cost_Raises;

   function Get_Cost_Raises
     (P : Problem; Row, Col : Index) return Boolean
   is
      Unused : Cost_Value;
   begin
      Unused := Get_Cost (P, Row, Col);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Cost_Raises;

   function Load_Raises (Costs : Cost_Matrix) return Boolean is
      P : Problem;
   begin
      Load_Matrix (P, Costs);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Raises;

   function Brute_Min_Raises (P : Problem) return Boolean is
      R : Solution;
   begin
      Solve_Brute_Minimize (P, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Brute_Min_Raises;

   function Assignment_Cost_Raises
     (P : Problem; A : Assignment_Array) return Boolean
   is
      Unused : Cost_Value;
   begin
      Unused := Assignment_Cost (P, A);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Assignment_Cost_Raises;

   procedure Fill_Identity (P : in out Problem; N : Natural; Diag : Integer) is
   begin
      Clear (P, N);
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               Set_Cost (P, Index (I), Index (J), Diag);
            else
               Set_Cost (P, Index (I), Index (J), Diag + 100);
            end if;
         end loop;
      end loop;
   end Fill_Identity;

   function Agree_Min (P : Problem) return Boolean is
      R1, R2 : Solution;
   begin
      Solve_Minimize (P, R1);
      Solve_Brute_Minimize (P, R2);
      return R1.Total_Cost = R2.Total_Cost
        and then Is_Permutation (R1.Assignment, Size (P))
        and then Is_Permutation (R2.Assignment, Size (P))
        and then Assignment_Cost (P, R1.Assignment) = R1.Total_Cost;
   end Agree_Min;

   function Agree_Max (P : Problem) return Boolean is
      R1, R2 : Solution;
   begin
      Solve_Maximize (P, R1);
      Solve_Brute_Maximize (P, R2);
      return R1.Total_Cost = R2.Total_Cost
        and then Is_Permutation (R1.Assignment, Size (P))
        and then Assignment_Cost (P, R1.Assignment) = R1.Total_Cost;
   end Agree_Max;

begin
   Put_Line ("Hungarian_Algorithm test suite");
   Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Empty N=0");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Clear (P, Nat (0));
      Check (Size (P) = 0, "Size 0 after Clear");
      Solve_Minimize (P, R);
      Check (R.N = 0 and then R.Total_Cost = 0, "empty minimize");
      Solve_Maximize (P, R);
      Check (R.N = 0 and then R.Total_Cost = 0, "empty maximize");
      Solve_Brute_Minimize (P, R);
      Check (R.N = 0 and then R.Total_Cost = 0, "empty brute min");
      Solve_Brute_Maximize (P, R);
      Check (R.N = 0 and then R.Total_Cost = 0, "empty brute max");
      Check (Is_Permutation (R.Assignment, 0), "empty is permutation");
   end;

   ---------------------------------------------------------------------
   Section ("2. 1x1");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Clear (P, 1);
      Set_Cost (P, 1, 1, 42);
      Check (Size (P) = 1, "Size 1");
      Check (Get_Cost (P, 1, 1) = 42, "Get_Cost 42");
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 42 and then R.Assignment (1) = 1, "1x1 min");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = 42 and then R.Assignment (1) = 1, "1x1 max");
      Check (Agree_Min (P), "1x1 agree min");
      Check (Agree_Max (P), "1x1 agree max");
      Set_Cost (P, 1, 1, -7);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = -7, "1x1 negative min");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = -7, "1x1 negative max");
   end;

   ---------------------------------------------------------------------
   Section ("3. Identity / diagonal preference");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Fill_Identity (P, 4, 0);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "diag4 min cost 0");
      Check (Is_Permutation (R.Assignment, 4), "diag4 permutation");
      Check (R.Assignment (1) = 1 and then R.Assignment (2) = 2
             and then R.Assignment (3) = 3 and then R.Assignment (4) = 4,
             "diag4 identity mapping");
      Check (Assignment_Cost (P, R.Assignment) = 0, "diag4 Assignment_Cost");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = 400, "diag4 max all off-diag 100*4");
   end;

   ---------------------------------------------------------------------
   Section ("4. Wikipedia Alice/Bob/Carol (min 15)");
   ---------------------------------------------------------------------
   --  Clean bathroom | Sweep floors | Wash windows
   --  Alice   8   4   7
   --  Bob     5   2   3
   --  Carol   9   4   8
   --  Optimal: Alice-bath, Carol-sweep, Bob-windows ⇒ 8+4+3 = 15
   declare
      P : Problem;
      R : Solution;
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[8, 4, 7],
         [5, 2, 3],
         [9, 4, 8]];
   begin
      Load_Matrix (P, M);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 15, "wiki3 Total 15");
      Check (Is_Permutation (R.Assignment, 3), "wiki3 permutation");
      Check (R.Assignment (1) = 1 and then R.Assignment (2) = 3
             and then R.Assignment (3) = 2,
             "wiki3 Alice-bath Bob-win Carol-sweep");
      Check (Assignment_Cost (P, R.Assignment) = 15, "wiki3 cost check");
      Check (Agree_Min (P), "wiki3 agree brute");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = 18, "wiki3 max 8+2+8=18");
      Check (Agree_Max (P), "wiki3 agree max brute");
   end;

   ---------------------------------------------------------------------
   Section ("5. Classic 4x4 Munkres textbook");
   ---------------------------------------------------------------------
   --  Optimal: 1→2(75), 2→4(65), 3→3(90), 4→1(45) = 275
   declare
      P : Problem;
      R : Solution;
      M : constant Cost_Matrix (1 .. 4, 1 .. 4) :=
        [[90,  75,  75,  80],
         [35,  85,  55,  65],
         [125, 95,  90, 105],
         [45, 110,  95, 115]];
   begin
      Load_Matrix (P, M);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 275, "munkres4 Total 275");
      Check (Is_Permutation (R.Assignment, 4), "munkres4 permutation");
      Check (Assignment_Cost (P, R.Assignment) = 275, "munkres4 cost");
      Check (Agree_Min (P), "munkres4 agree brute");
      Solve_Maximize (P, R);
      Check (Agree_Max (P), "munkres4 agree max");
   end;

   ---------------------------------------------------------------------
   Section ("6. 2x2 hand matrices");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Clear (P, 2);
      Set_Cost (P, 1, 1, 1); Set_Cost (P, 1, 2, 2);
      Set_Cost (P, 2, 1, 3); Set_Cost (P, 2, 2, 4);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 5, "2x2 min 1+4=5");
      Check (Agree_Min (P), "2x2 agree min");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = 5, "2x2 max 2+3=5");
      Check (Agree_Max (P), "2x2 agree max");

      Clear (P, 2);
      Set_Cost (P, 1, 1, 0); Set_Cost (P, 1, 2, 1);
      Set_Cost (P, 2, 1, 1); Set_Cost (P, 2, 2, 0);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "2x2 anti-diag min 0");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = 2, "2x2 anti-diag max 2");

      Clear (P, 2);
      Set_Cost (P, 1, 1, 4); Set_Cost (P, 1, 2, 1);
      Set_Cost (P, 2, 1, 2); Set_Cost (P, 2, 2, 3);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 3, "2x2 min 1+2=3");
      Check (Agree_Min (P), "2x2b agree");
   end;

   ---------------------------------------------------------------------
   Section ("7. All-equal / zeros / negatives");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Clear (P, 3);
      for I in Index range 1 .. 3 loop
         for J in Index range 1 .. 3 loop
            Set_Cost (P, I, J, 5);
         end loop;
      end loop;
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 15, "all-equal min 15");
      Check (Is_Permutation (R.Assignment, 3), "all-equal permutation");
      Solve_Maximize (P, R);
      Check (R.Total_Cost = 15, "all-equal max 15");

      Clear (P, 3);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "zeros min 0");
      Check (Agree_Min (P), "zeros agree");

      Clear (P, 3);
      Set_Cost (P, 1, 1, -5); Set_Cost (P, 1, 2, 1); Set_Cost (P, 1, 3, 2);
      Set_Cost (P, 2, 1, 3);  Set_Cost (P, 2, 2, -1); Set_Cost (P, 2, 3, 4);
      Set_Cost (P, 3, 1, 0);  Set_Cost (P, 3, 2, 2); Set_Cost (P, 3, 3, -3);
      Check (Agree_Min (P), "negatives agree min");
      Check (Agree_Max (P), "negatives agree max");
      Solve_Minimize (P, R);
      Check (R.Total_Cost = -9, "negatives min -5+-1+-3=-9");
   end;

   ---------------------------------------------------------------------
   Section ("8. Load_Matrix and Get/Set");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      M : constant Cost_Matrix (1 .. 2, 1 .. 2) :=
        [[10, 20], [30, 40]];
      Bad_Rect : constant Cost_Matrix (1 .. 2, 1 .. 3) :=
        [[1, 2, 3], [4, 5, 6]];
      Bad_First : constant Cost_Matrix (2 .. 3, 2 .. 3) :=
        [[1, 2], [3, 4]];
   begin
      Load_Matrix (P, M);
      Check (Size (P) = 2, "Load size 2");
      Check (Get_Cost (P, 1, 2) = 20, "Load Get_Cost");
      Check (Load_Raises (Bad_Rect), "Load rejects rectangular");
      Check (Load_Raises (Bad_First), "Load rejects First/=1");
      Set_Cost (P, 2, 2, 99);
      Check (Get_Cost (P, 2, 2) = 99, "Set_Cost overwrite");
   end;

   ---------------------------------------------------------------------
   Section ("9. Invalid_Argument guards");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      Bad_Asg : constant Assignment_Array (1 .. 3) := [1, 1, 2];
      Ok_Asg  : constant Assignment_Array (1 .. 3) := [2, 3, 1];
      Empty_A : Assignment_Array (1 .. 0);
   begin
      Check (Clear_Raises (Nat (Max_N + 1)), "Clear Max_N+1");
      Check (Clear_Raises (Nat (1000)), "Clear 1000");
      Clear (P, 2);
      Check (Set_Cost_Raises (P, 3, 1, 0), "Set_Cost row OOB");
      Check (Set_Cost_Raises (P, 1, 3, 0), "Set_Cost col OOB");
      Check (Get_Cost_Raises (P, 3, 1), "Get_Cost row OOB");
      Check (Get_Cost_Raises (P, 1, 3), "Get_Cost col OOB");
      Check (Assignment_Cost_Raises (P, Bad_Asg), "Assignment_Cost dup");
      Clear (P, 3);
      Check (Assignment_Cost (P, Ok_Asg) = 0, "Assignment_Cost ok zeros");
      Check (not Is_Permutation (Bad_Asg, 3), "Is_Permutation rejects dup");
      Check (Is_Permutation (Ok_Asg, 3), "Is_Permutation ok");
      Check (Is_Permutation (Empty_A, 0), "Is_Permutation empty");
      Check (not Is_Permutation (Ok_Asg, 4), "Is_Permutation N>length");

      Clear (P, 9);
      for I in 1 .. 9 loop
         for J in 1 .. 9 loop
            Set_Cost (P, Index (I), Index (J), Integer (I + J));
         end loop;
      end loop;
      Check (Brute_Min_Raises (P), "brute rejects N=9");
   end;

   ---------------------------------------------------------------------
   Section ("10. Brute vs Hungarian random-ish small N");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      --  Deterministic “pseudo-random” matrices
      Seeds : constant array (1 .. 8) of Integer :=
        [3, 7, 11, 13, 17, 19, 23, 29];
   begin
      for N in 1 .. 6 loop
         Clear (P, N);
         for I in 1 .. N loop
            for J in 1 .. N loop
               Set_Cost
                 (P, Index (I), Index (J),
                  (Seeds (((I + J) mod 8) + 1) * I * J) mod 97);
            end loop;
         end loop;
         Check (Agree_Min (P),
                "agree min N=" & Natural'Image (N));
         Check (Agree_Max (P),
                "agree max N=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("11. More hand 3x3");
   ---------------------------------------------------------------------
   declare
      type Mat3 is array (1 .. 3, 1 .. 3) of Integer;
      Mats : constant array (1 .. 6) of Mat3 :=
        [[[1, 2, 3], [4, 5, 6], [7, 8, 9]],
         [[9, 8, 7], [6, 5, 4], [3, 2, 1]],
         [[5, 5, 5], [5, 5, 5], [5, 5, 5]],
         [[0, 1, 2], [1, 0, 1], [2, 1, 0]],
         [[10, 1, 10], [10, 10, 1], [1, 10, 10]],
         [[2, 9, 4], [7, 1, 3], [6, 8, 5]]];
      Expected_Min : constant array (1 .. 6) of Integer :=
        [15, 15, 15, 0, 3, 8];
      P : Problem;
      R : Solution;
   begin
      for K in Mats'Range loop
         Clear (P, 3);
         for I in 1 .. 3 loop
            for J in 1 .. 3 loop
               Set_Cost (P, Index (I), Index (J), Mats (K) (I, J));
            end loop;
         end loop;
         Solve_Minimize (P, R);
         Check (R.Total_Cost = Cost_Of (Expected_Min (K)),
                "hand3#" & Integer'Image (K) & " min");
         Check (Agree_Min (P), "hand3#" & Integer'Image (K) & " brute");
         Check (Agree_Max (P), "hand3#" & Integer'Image (K) & " max");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Cycle / path preferences");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      --  Prefer a 4-cycle of 1s over diagonal of 100
      Clear (P, 4);
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            Set_Cost (P, Index (I), Index (J), 100);
         end loop;
      end loop;
      Set_Cost (P, 1, 2, 1);
      Set_Cost (P, 2, 3, 1);
      Set_Cost (P, 3, 4, 1);
      Set_Cost (P, 4, 1, 1);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 4, "cycle4 cost 4");
      Check (Agree_Min (P), "cycle4 agree");

      Clear (P, 3);
      Set_Cost (P, 1, 1, 100); Set_Cost (P, 1, 2, 1); Set_Cost (P, 1, 3, 100);
      Set_Cost (P, 2, 1, 100); Set_Cost (P, 2, 2, 100); Set_Cost (P, 2, 3, 1);
      Set_Cost (P, 3, 1, 1); Set_Cost (P, 3, 2, 100); Set_Cost (P, 3, 3, 100);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 3, "path3 cost 3");
      Check (R.Assignment (1) = 2 and then R.Assignment (2) = 3
             and then R.Assignment (3) = 1, "path3 mapping");
   end;

   ---------------------------------------------------------------------
   Section ("13. Larger educational sizes (no brute)");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Fill_Identity (P, 16, 0);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "n=16 identity min 0");
      Check (Is_Permutation (R.Assignment, 16), "n=16 permutation");
      for I in 1 .. 16 loop
         if R.Assignment (I) /= I then
            Check (False, "n=16 identity map");
            goto After_16;
         end if;
      end loop;
      Check (True, "n=16 identity map");
      <<After_16>>

      Fill_Identity (P, 32, 1);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 32, "n=32 diag ones");
      Check (Is_Permutation (R.Assignment, 32), "n=32 permutation");

      --  Max_N capacity path: Clear + solve identity-like
      Clear (P, Max_N);
      for I in 1 .. Max_N loop
         for J in 1 .. Max_N loop
            if I = J then
               Set_Cost (P, Index (I), Index (J), 0);
            else
               Set_Cost (P, Index (I), Index (J), 1);
            end if;
         end loop;
      end loop;
      Solve_Minimize (P, R);
      Check (R.N = Max_N and then R.Total_Cost = 0, "Max_N identity 0");
      Check (Is_Permutation (R.Assignment, Max_N), "Max_N permutation");
      Check (not Clear_Raises (Nat (Max_N)), "Clear Max_N ok");
   end;

   ---------------------------------------------------------------------
   Section ("14. Maximize via negation identity");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      Rmin, Rmax : Solution;
      M : constant Cost_Matrix (1 .. 3, 1 .. 3) :=
        [[8, 4, 7],
         [5, 2, 3],
         [9, 4, 8]];
   begin
      Load_Matrix (P, M);
      Solve_Maximize (P, Rmax);
      --  Negate and minimize should match -Rmax
      declare
         Neg : Cost_Matrix (1 .. 3, 1 .. 3);
         Pn  : Problem;
      begin
         for I in 1 .. 3 loop
            for J in 1 .. 3 loop
               Neg (I, J) := -M (I, J);
            end loop;
         end loop;
         Load_Matrix (Pn, Neg);
         Solve_Minimize (Pn, Rmin);
         Check (Rmin.Total_Cost = -Rmax.Total_Cost,
                "max = -min(-C)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Permutation / cost helpers");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      Id : constant Assignment_Array (1 .. 4) := [1, 2, 3, 4];
      Rev : constant Assignment_Array (1 .. 4) := [4, 3, 2, 1];
      Bad : constant Assignment_Array (1 .. 4) := [1, 2, 2, 4];
      Off : constant Assignment_Array (2 .. 5) := [1, 2, 3, 4];
   begin
      Fill_Identity (P, 4, 0);
      Check (Is_Permutation (Id, 4), "Id perm");
      Check (Is_Permutation (Rev, 4), "Rev perm");
      Check (not Is_Permutation (Bad, 4), "Bad perm");
      Check (not Is_Permutation (Off, 4), "Off First/=1");
      Check (Assignment_Cost (P, Id) = 0, "cost Id");
      Check (Assignment_Cost (P, Rev) = 400, "cost Rev off-diag");
      Check (Assignment_Cost_Raises (P, Bad), "cost Bad raises");
      Check (Assignment_Cost_Raises (P, Off), "cost Off raises");
   end;

   ---------------------------------------------------------------------
   Section ("16. Extra small instances (batch)");
   ---------------------------------------------------------------------
   declare
      type Mat2 is array (1 .. 2, 1 .. 2) of Integer;
      type Mat3 is array (1 .. 3, 1 .. 3) of Integer;
      type Mat4 is array (1 .. 4, 1 .. 4) of Integer;
      M2s : constant array (1 .. 5) of Mat2 :=
        [[[0, 1], [1, 0]],
         [[3, 3], [1, 2]],
         [[9, 1], [8, 2]],
         [[-1, -2], [-3, -4]],
         [[50, 50], [50, 50]]];
      Exp2_Min : constant array (1 .. 5) of Integer :=
        [0, 4, 9, -5, 100];
      M3s : constant array (1 .. 5) of Mat3 :=
        [[[8, 7, 9], [4, 2, 6], [5, 3, 1]],
         [[11, 12, 13], [14, 15, 16], [17, 18, 10]],
         [[0, 0, 0], [0, 0, 0], [0, 0, 0]],
         [[4, 1, 3], [2, 0, 5], [3, 2, 2]],
         [[100, 1, 100], [100, 100, 1], [1, 100, 100]]];
      Exp3_Min : constant array (1 .. 5) of Integer :=
        [11, 36, 0, 5, 3];
      M4s : constant array (1 .. 3) of Mat4 :=
        [[[1, 2, 3, 4],
          [2, 1, 4, 3],
          [3, 4, 1, 2],
          [4, 3, 2, 1]],
         [[100, 1, 100, 100],
          [100, 100, 1, 100],
          [100, 100, 100, 1],
          [1, 100, 100, 100]],
         [[5, 5, 5, 5],
          [5, 5, 5, 5],
          [5, 5, 5, 5],
          [5, 5, 5, 5]]];
      Exp4_Min : constant array (1 .. 3) of Integer :=
        [4, 4, 20];
      P : Problem;
      R : Solution;
   begin
      for K in M2s'Range loop
         Clear (P, 2);
         for I in 1 .. 2 loop
            for J in 1 .. 2 loop
               Set_Cost (P, Index (I), Index (J), M2s (K) (I, J));
            end loop;
         end loop;
         Solve_Minimize (P, R);
         Check (R.Total_Cost = Cost_Of (Exp2_Min (K)),
                "batch2#" & Integer'Image (K));
         Check (Agree_Min (P), "batch2b#" & Integer'Image (K));
         Check (Agree_Max (P), "batch2x#" & Integer'Image (K));
      end loop;
      for K in M3s'Range loop
         Clear (P, 3);
         for I in 1 .. 3 loop
            for J in 1 .. 3 loop
               Set_Cost (P, Index (I), Index (J), M3s (K) (I, J));
            end loop;
         end loop;
         Solve_Minimize (P, R);
         Check (R.Total_Cost = Cost_Of (Exp3_Min (K)),
                "batch3#" & Integer'Image (K));
         Check (Agree_Min (P), "batch3b#" & Integer'Image (K));
         Check (Agree_Max (P), "batch3x#" & Integer'Image (K));
      end loop;
      for K in M4s'Range loop
         Clear (P, 4);
         for I in 1 .. 4 loop
            for J in 1 .. 4 loop
               Set_Cost (P, Index (I), Index (J), M4s (K) (I, J));
            end loop;
         end loop;
         Solve_Minimize (P, R);
         Check (R.Total_Cost = Cost_Of (Exp4_Min (K)),
                "batch4#" & Integer'Image (K));
         Check (Agree_Min (P), "batch4b#" & Integer'Image (K));
         Check (Agree_Max (P), "batch4x#" & Integer'Image (K));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("17. N=5..8 brute agreement grid");
   ---------------------------------------------------------------------
   declare
      P : Problem;
   begin
      for N in 5 .. 8 loop
         Clear (P, N);
         for I in 1 .. N loop
            for J in 1 .. N loop
               Set_Cost
                 (P, Index (I), Index (J),
                  Integer ((I * 17 + J * 13) mod 41));
            end loop;
         end loop;
         Check (Agree_Min (P), "grid min N=" & Natural'Image (N));
         Check (Agree_Max (P), "grid max N=" & Natural'Image (N));
      end loop;

      --  Another family
      for N in 2 .. 7 loop
         Clear (P, N);
         for I in 1 .. N loop
            for J in 1 .. N loop
               Set_Cost
                 (P, Index (I), Index (J),
                  Integer (abs (I - J) * 3 + I));
            end loop;
         end loop;
         Check (Agree_Min (P), "abs min N=" & Natural'Image (N));
         Check (Agree_Max (P), "abs max N=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("18. Clear resets costs");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Clear (P, 3);
      Set_Cost (P, 1, 1, 99);
      Clear (P, 3);
      Check (Get_Cost (P, 1, 1) = 0, "Clear zeros costs");
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "cleared zeros solve");
      Clear (P, 1);
      Check (Size (P) = 1, "Clear resize to 1");
      Clear (P, 0);
      Check (Size (P) = 0, "Clear resize to 0");
   end;

   ---------------------------------------------------------------------
   Section ("19. Tie-breaking still optimal");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      --  Two optimal mins of cost 2
      Clear (P, 2);
      Set_Cost (P, 1, 1, 1); Set_Cost (P, 1, 2, 1);
      Set_Cost (P, 2, 1, 1); Set_Cost (P, 2, 2, 1);
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 2, "ties min 2");
      Check (Is_Permutation (R.Assignment, 2), "ties permutation");
      Check (Agree_Min (P), "ties agree");
   end;

   ---------------------------------------------------------------------
   Section ("20. Large sparse preference");
   ---------------------------------------------------------------------
   declare
      P : Problem;
      R : Solution;
   begin
      Clear (P, 10);
      for I in 1 .. 10 loop
         for J in 1 .. 10 loop
            Set_Cost (P, Index (I), Index (J), 1000);
         end loop;
      end loop;
      for I in 1 .. 10 loop
         Set_Cost (P, Index (I), Index (I), 0);
      end loop;
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "sparse10 identity");
      Check (Is_Permutation (R.Assignment, 10), "sparse10 perm");
      --  Shift diagonal
      Clear (P, 10);
      for I in 1 .. 10 loop
         for J in 1 .. 10 loop
            Set_Cost (P, Index (I), Index (J), 1000);
         end loop;
      end loop;
      for I in 1 .. 10 loop
         declare
            J : constant Natural := (if I < 10 then I + 1 else 1);
         begin
            Set_Cost (P, Index (I), Index (J), 0);
         end;
      end loop;
      Solve_Minimize (P, R);
      Check (R.Total_Cost = 0, "sparse10 cycle");
      Check (Is_Permutation (R.Assignment, 10), "sparse10 cycle perm");
      --  N=10 > Max_Brute_N so just check cost via Assignment_Cost
      Check (Assignment_Cost (P, R.Assignment) = 0, "sparse10 cost");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("==============================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count)
      & " PASS," & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 and then Pass_Count >= 150 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILED OR TOO FEW");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
