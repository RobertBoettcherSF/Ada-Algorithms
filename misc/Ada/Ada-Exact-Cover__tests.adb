--  Standalone test suite for Exact_Cover (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Exact_Cover; use Exact_Cover;
with Interfaces;
use type Exact_Cover.Bit_Set;

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

   function Sorted_Sel (Sel : Selection) return Selection is
      R   : Selection := Sel;
      Tmp : Subset_Id;
   begin
      for I in 1 .. R.Length loop
         for J in I + 1 .. R.Length loop
            if R.Ids (J) < R.Ids (I) then
               Tmp := R.Ids (I);
               R.Ids (I) := R.Ids (J);
               R.Ids (J) := Tmp;
            end if;
         end loop;
      end loop;
      return R;
   end Sorted_Sel;

   function Same_Sel (A, B : Selection) return Boolean is
      SA : constant Selection := Sorted_Sel (A);
      SB : constant Selection := Sorted_Sel (B);
   begin
      if SA.Length /= SB.Length then
         return False;
      end if;
      for I in 1 .. SA.Length loop
         if SA.Ids (I) /= SB.Ids (I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Sel;

   function Has_Sorted
     (Arr   : Selection_Array;
      Count : Natural;
      Want  : Selection) return Boolean
   is
      W : constant Selection := Sorted_Sel (Want);
   begin
      for I in 1 .. Count loop
         if Same_Sel (Arr (I), W) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Sorted;

begin
   Put_Line ("Exact_Cover test suite");
   Put_Line ("======================");

   ---------------------------------------------------------------------
   Section ("1. Caps, bits, Clear");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      U    : Bit_Set;
      B1, B2, B3, S1, M0, M1, M3, Mall, P0, P7 : Bit_Set;
      N0, N7, Nh : Natural;
   begin
      B1 := Element_Bit (1);
      B2 := Element_Bit (2);
      B3 := Element_Bit (3);
      S1 := Subset_Bit (1);
      M0 := Universe_Mask (0);
      M1 := Universe_Mask (1);
      M3 := Universe_Mask (3);
      Mall := Universe_Mask (Max_Universe_Size);
      P0 := 0;
      P7 := 7;
      N0 := Popcount (P0);
      N7 := Popcount (P7);
      Nh := Popcount (Interfaces.Shift_Left (Bit_Set'(1), 63));
      Check (B1 = 1, "Element_Bit(1) = 1");
      Check (B2 = 2, "Element_Bit(2) = 2");
      Check (B3 = 4, "Element_Bit(3) = 4");
      Check (S1 = 1, "Subset_Bit(1) = 1");
      Check (M0 = 0, "Universe_Mask(0) = 0");
      Check (M1 = 1, "Universe_Mask(1) = 1");
      Check (M3 = 7, "Universe_Mask(3) = 7");
      Check (Mall = Bit_Set'Last, "Universe_Mask(64) = all");
      Check (N0 = 0, "Popcount(0) = 0");
      Check (N7 = 3, "Popcount(7) = 3");
      Check (Nh = 1, "Popcount high bit");
      Check (Bit_Is_Set (7, 1) and Bit_Is_Set (7, 2) and Bit_Is_Set (7, 3),
             "Bit_Is_Set on 7");
      Check (not Bit_Is_Set (7, 4), "Bit_Is_Set 4 not in 7");
      Clear (Inst);
      Check (Inst.Num_Elements = 0, "Clear Num_Elements 0");
      Check (Inst.Num_Subsets = 0, "Clear Num_Subsets 0");
      U := Universe_Mask (Inst.Num_Elements);
      Check (U = 0, "Clear universe mask 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Empty universe");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Found : Selection;
      Ok    : Boolean;
      Arr   : Selection_Array;
      Count : Natural;
   begin
      Clear (Inst);
      Check (Count_Covers (Inst) = 1, "empty Count_Covers = 1");
      Solve_Backtrack (Inst, Found, Ok);
      Check (Ok, "empty Solve Success");
      Check (Found.Length = 0, "empty solution length 0");
      Check (Is_Exact_Cover (Inst, Found), "empty is exact cover");
      Check (Is_Partial_Cover (Inst, Found), "empty is partial cover");
      Solve_All (Inst, Arr, Count, 5);
      Check (Count = 1 and then Arr (1).Length = 0, "empty Solve_All");
      --  Empty universe with one empty subset → 2 covers: {} and {1}.
      Set_Universe (Inst, 0);
      Add_Subset (Inst, 0);
      Check (Inst.Num_Subsets = 1, "empty+∅ Num_Subsets 1");
      Check (Count_Covers (Inst) = 2, "empty+∅ Count_Covers = 2");
   end;

   ---------------------------------------------------------------------
   Section ("3. Unsatisfiable");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Found : Selection;
      Ok    : Boolean;
      M0    : constant Bool_Matrix (1 .. 1, 1 .. 1) := [[False]];
      M1    : constant Bool_Matrix (1 .. 1, 1 .. 2) := [[True, False]];
   begin
      From_Incidence_Matrix (Inst, M0);
      Check (Inst.Num_Elements = 1, "unsat empty-row cols=1");
      Check (Inst.Num_Subsets = 1, "unsat empty-row subsets=1");
      Check (Inst.Rows (1) = 0, "unsat empty-row mask 0");
      Check (Count_Covers (Inst) = 0, "unsat empty-row 0 covers");
      Solve_Backtrack (Inst, Found, Ok);
      Check (not Ok, "unsat empty-row Solve fails");

      From_Incidence_Matrix (Inst, M1);
      Check (Count_Covers (Inst) = 0, "partial matrix 0 covers");
      Solve_Backtrack (Inst, Found, Ok);
      Check (not Ok, "partial matrix Solve fails");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tiny exact covers / verification");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Id2  : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, False], [False, True]];
      One  : constant Bool_Matrix (1 .. 1, 1 .. 1) := [[True]];
      Dup  : constant Bool_Matrix (1 .. 2, 1 .. 1) := [[True], [True]];
      Full : constant Bool_Matrix (1 .. 2, 1 .. 2) :=
        [[True, True], [True, True]];
      Found : Selection;
      Ok    : Boolean;
      Sel   : Selection;
   begin
      From_Incidence_Matrix (Inst, One);
      Check (Count_Covers (Inst) = 1, "1x1 identity 1 cover");
      Solve_Backtrack (Inst, Found, Ok);
      Check (Ok and Found.Length = 1 and Found.Ids (1) = 1, "1x1 sol {1}");
      Check (Is_Exact_Cover (Inst, Found), "1x1 Is_Exact_Cover");

      From_Incidence_Matrix (Inst, Id2);
      Check (Count_Covers (Inst) = 1, "2x2 identity 1 cover");
      Solve_Backtrack (Inst, Found, Ok);
      Check (Ok and Found.Length = 2, "2x2 length 2");
      Check (Is_Exact_Cover (Inst, Found), "2x2 exact");
      Sel := (Length => 1, Ids => [1, others => 1]);
      Check (Is_Partial_Cover (Inst, Sel), "2x2 {1} partial");
      Check (not Is_Exact_Cover (Inst, Sel), "2x2 {1} not exact");
      Check (Cover_Count_Of (Inst, Found, 1) = 1, "2x2 cover count el1");
      Check (Cover_Count_Of (Inst, Found, 2) = 1, "2x2 cover count el2");

      From_Incidence_Matrix (Inst, Dup);
      Check (Count_Covers (Inst) = 2, "dup col two singleton covers");
      --  Either row alone is an exact cover of {1}.

      From_Incidence_Matrix (Inst, Full);
      Check (Count_Covers (Inst) = 2, "full 2x2 two singleton-row covers");
      Sel := (Length => 2, Ids => [1, 2, others => 1]);
      Check (Conflicts (Inst.Rows (1), Inst.Rows (2)), "full rows conflict");
      Check (not Is_Partial_Cover (Inst, Sel), "full both not partial");
   end;

   ---------------------------------------------------------------------
   Section ("5. Knuth textbook example");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Found : Selection;
      Ok    : Boolean;
      Arr   : Selection_Array;
      Count : Natural;
      Want  : Selection;
   begin
      Build_Knuth_Example (Inst);
      Check (Inst.Num_Elements = 7, "Knuth |X|=7");
      Check (Inst.Num_Subsets = 6, "Knuth |S|=6");
      Check (Popcount (Inst.Rows (1)) = 3, "Knuth A size 3");
      Check (Popcount (Inst.Rows (2)) = 2, "Knuth B size 2");
      Check (Popcount (Inst.Rows (6)) = 2, "Knuth F size 2");
      Check (Knuth_Example_Cover_Count = 1, "Knuth cover count wrapper=1");
      Check (Count_Covers (Inst) = 1, "Knuth Count_Covers=1");
      Check (Count_Covers (Inst, Use_MRV => False) = 1,
             "Knuth Count without MRV=1");
      Solve_Backtrack (Inst, Found, Ok);
      Check (Ok, "Knuth Solve ok");
      Want := (Length => 3, Ids => [2, 4, 6, others => 1]);
      Check (Same_Sel (Found, Want), "Knuth solution {2,4,6}");
      Check (Is_Exact_Cover (Inst, Found), "Knuth Is_Exact_Cover");
      Check (Is_Exact_Cover (Inst, Want), "Knuth Want exact");
      --  {A,D} = {1,4} not exact (misses 2).
      Want := (Length => 2, Ids => [1, 4, others => 1]);
      Check (Is_Partial_Cover (Inst, Want), "Knuth {A,D} partial");
      Check (not Is_Exact_Cover (Inst, Want), "Knuth {A,D} not exact");
      Want := (Length => 2, Ids => [1, 2, others => 1]);
      Check (not Is_Partial_Cover (Inst, Want), "Knuth {A,B} conflict");
      Solve_All (Inst, Arr, Count);
      Check (Count = 1, "Knuth Solve_All count 1");
      Want := (Length => 3, Ids => [2, 4, 6, others => 1]);
      Check (Has_Sorted (Arr, Count, Want), "Knuth Solve_All has {B,D,F}");
      for E in Element_Id range 1 .. 7 loop
         Check (Cover_Count_Of (Inst, Arr (1), E) = 1,
                "Knuth each element once #" & E'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. NOPE Wikipedia basic example");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Arr   : Selection_Array;
      Count : Natural;
      OE    : Selection;
      NOE   : Selection;
   begin
      Build_NOPE_Example (Inst);
      Check (Inst.Num_Elements = 4, "NOPE |X|=4");
      Check (Inst.Num_Subsets = 4, "NOPE |S|=4");
      Check (Inst.Rows (1) = 0, "NOPE N empty");
      Check (NOPE_Example_Cover_Count = 2, "NOPE wrapper count=2");
      Check (Count_Covers (Inst) = 2, "NOPE Count_Covers=2");
      Solve_All (Inst, Arr, Count);
      Check (Count = 2, "NOPE Solve_All=2");
      OE  := (Length => 2, Ids => [2, 4, others => 1]);  -- O,E
      NOE := (Length => 3, Ids => [1, 2, 4, others => 1]);  -- N,O,E
      Check (Has_Sorted (Arr, Count, OE), "NOPE has {O,E}");
      Check (Has_Sorted (Arr, Count, NOE), "NOPE has {N,O,E}");
      Check (Is_Exact_Cover (Inst, OE), "NOPE {O,E} exact");
      Check (Is_Exact_Cover (Inst, NOE), "NOPE {N,O,E} exact");
      declare
         PE : constant Selection :=
           (Length => 2, Ids => [3, 4, others => 1]);
      begin
         Check (not Is_Partial_Cover (Inst, PE), "NOPE {P,E} conflict");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Partition toy (Bell number B3=5)");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Arr   : Selection_Array;
      Count : Natural;
      Found : Selection;
      Ok    : Boolean;
   begin
      Build_Partition_Toy (Inst);
      Check (Inst.Num_Elements = 3, "partition |X|=3");
      Check (Inst.Num_Subsets = 7, "partition |S|=7");
      Check (Count_Covers (Inst) = 5, "partition B3=5 covers");
      Check (Count_Covers (Inst, Use_MRV => False) = 5,
             "partition without MRV=5");
      Solve_All (Inst, Arr, Count);
      Check (Count = 5, "partition Solve_All=5");
      Check (Has_Sorted (Arr, Count,
             (Length => 3, Ids => [1, 2, 3, others => 1])),
            "partition {{1}{2}{3}}");
      Check (Has_Sorted (Arr, Count,
             (Length => 2, Ids => [3, 4, others => 1])),
            "partition {{1,2}{3}}");
      Check (Has_Sorted (Arr, Count,
             (Length => 2, Ids => [2, 5, others => 1])),
            "partition {{1,3}{2}}");
      Check (Has_Sorted (Arr, Count,
             (Length => 2, Ids => [1, 6, others => 1])),
            "partition {{1}{2,3}}");
      Check (Has_Sorted (Arr, Count,
             (Length => 1, Ids => [7, others => 1])),
            "partition {{1,2,3}}");
      Solve_Backtrack (Inst, Found, Ok);
      Check (Ok and Is_Exact_Cover (Inst, Found), "partition one exact");
   end;

   ---------------------------------------------------------------------
   Section ("8. From_Incidence_Matrix / Add_Subset builders");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      M    : constant Bool_Matrix (1 .. 3, 1 .. 3) :=
        [[True, False, False],
         [False, True, False],
         [False, False, True]];
      Found : Selection;
      Ok    : Boolean;
   begin
      From_Incidence_Matrix (Inst, M);
      Check (Inst.Num_Elements = 3 and Inst.Num_Subsets = 3,
             "builder dims 3x3");
      Check (Count_Covers (Inst) = 1, "identity-3 one cover");
      Set_Universe (Inst, 2);
      Add_Subset (Inst, Element_Bit (1));
      Add_Subset (Inst, Element_Bit (2));
      Check (Inst.Num_Subsets = 2, "Add_Subset count 2");
      Check (Count_Covers (Inst) = 1, "manual build one cover");
      Solve_Backtrack (Inst, Found, Ok);
      Check (Ok and Found.Length = 2, "manual solve length 2");
      --  Clips bits outside universe.
      Set_Universe (Inst, 2);
      Add_Subset (Inst, Element_Bit (1) or Element_Bit (3));
      Check (Inst.Rows (1) = Element_Bit (1), "Add_Subset clips bit 3");
   end;

   ---------------------------------------------------------------------
   Section ("9. Conflicts / Covered_Elements / Selection_Mask");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Sel  : Selection;
      M    : Bit_Set;
   begin
      Build_Knuth_Example (Inst);
      Check (Conflicts (Inst.Rows (1), Inst.Rows (2)), "A conflicts B");
      Check (not Conflicts (Inst.Rows (2), Inst.Rows (4)),
             "B no conflict D");
      Check (not Conflicts (Inst.Rows (2), Inst.Rows (6)),
             "B no conflict F");
      Check (not Conflicts (0, Inst.Rows (1)), "∅ no conflict");
      Sel := (Length => 3, Ids => [2, 4, 6, others => 1]);
      Check (Covered_Elements (Inst, Sel) = Universe_Mask (7),
             "Knuth cover full universe");
      M := Selection_Mask (Inst, Sel);
      Check (Bit_Is_Set (M, 2) and Bit_Is_Set (M, 4) and Bit_Is_Set (M, 6),
             "Selection_Mask bits 2,4,6");
      Check (Popcount (M) = 3, "Selection_Mask popcount 3");
   end;

   ---------------------------------------------------------------------
   Section ("10. Method taxonomy");
   ---------------------------------------------------------------------
   declare
      Info : Method_Info;
   begin
      Check (Method_Count = 4, "Method_Count = 4");
      Check (Method_Name (Naive_Backtrack) = "Naive_Backtrack",
             "name Naive_Backtrack");
      Check (Method_Name (Algorithm_X) = "Algorithm_X", "name Algorithm_X");
      Check (Method_Name (Dancing_Links) = "Dancing_Links",
             "name Dancing_Links");
      Check (Method_Name (Integer_LP) = "Integer_LP", "name Integer_LP");
      Check (Implemented (Naive_Backtrack), "Naive implemented");
      Check (not Implemented (Algorithm_X), "Algorithm_X not here");
      Check (not Implemented (Dancing_Links), "DLX not here");
      Check (not Implemented (Integer_LP), "ILP not here");
      Check (not Forthcoming (Naive_Backtrack), "Naive not forthcoming");
      Check (Forthcoming (Algorithm_X), "Algorithm_X forthcoming");
      Check (Forthcoming (Dancing_Links), "DLX forthcoming");
      Check (Forthcoming (Integer_LP), "ILP forthcoming");
      Info := Classify (Naive_Backtrack);
      Check (Info.Kind = Naive_Backtrack and Info.Status = Implemented
             and Info.Implemented,
             "Classify Naive");
      Info := Classify (Dancing_Links);
      Check (Info.Kind = Dancing_Links and Info.Status = Forthcoming
             and not Info.Implemented,
             "Classify DLX");
   end;

   ---------------------------------------------------------------------
   Section ("11. Cap / Solve_All limits / MRV parity");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Arr   : Selection_Array;
      Count : Natural;
      Found : Selection;
      Ok    : Boolean;
   begin
      Build_Partition_Toy (Inst);
      Solve_All (Inst, Arr, Count, Cap => 2);
      Check (Count = 2, "Solve_All Cap=2 stops at 2");
      Check (Count_Covers (Inst, Cap => 3) = 3, "Count_Covers Cap=3");
      Solve_Backtrack (Inst, Found, Ok, Use_MRV => False);
      Check (Ok and Is_Exact_Cover (Inst, Found), "no-MRV solve ok");
      --  Two identical singleton covers of one element.
      declare
         Dup : constant Bool_Matrix (1 .. 3, 1 .. 1) :=
           [[True], [True], [True]];
      begin
         From_Incidence_Matrix (Inst, Dup);
         Check (Count_Covers (Inst) = 3, "three singleton covers");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Exceptions / edge");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Raised : Boolean;
   begin
      Clear (Inst);
      Raised := False;
      begin
         Add_Subset (Inst, Element_Bit (1));
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Add_Subset on empty univ with bits raises");

      Set_Universe (Inst, 1);
      for I in 1 .. Max_Subset_Count loop
         Add_Subset (Inst, Element_Bit (1));
      end loop;
      Raised := False;
      begin
         Add_Subset (Inst, Element_Bit (1));
      exception
         when Capacity_Exceeded => Raised := True;
      end;
      Check (Raised, "Add_Subset past capacity raises");
      Check (Cover_Count_Of (Inst,
             (Length => 0, Ids => [others => 1]), 1) = 0,
             "Cover_Count_Of empty sel = 0");
      Check (Cover_Count_Of (Inst,
             (Length => 1, Ids => [1, others => 1]), 2) = 0,
             "Cover_Count_Of out-of-range element = 0");
   end;

   New_Line;
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
