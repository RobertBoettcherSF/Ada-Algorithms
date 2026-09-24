--  Standalone test suite for SSS_Star (main program).

pragma Ada_2022;

with Ada.Text_IO;
with SSS_Star; use SSS_Star;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   procedure Check_Both
     (G        : Game_Tree;
      Expected : Integer;
      Label    : String)
   is
      Ev : Integer;
      Mm : Integer;
   begin
      Ev := Evaluate (G);
      Mm := Minimax (G);
      Check (Mm = Expected, Label & " Minimax=" & Integer'Image (Mm));
      Check (Ev = Expected, Label & " Evaluate=" & Integer'Image (Ev));
      Check (Ev = Mm, Label & " Evaluate=Minimax");
   end Check_Both;

begin
   Ada.Text_IO.Put_Line ("SSS* test suite");
   Ada.Text_IO.Put_Line ("===============");

   ---------------------------------------------------------------------
   Section ("1. Build API / queries");
   ---------------------------------------------------------------------
   declare
      G  : Game_Tree;
      L1 : Valid_Node;
      L2 : Valid_Node;
      M  : Valid_Node;
   begin
      Clear (G);
      Check (Node_Count (G) = 0, "Clear => count 0");
      Check (Root_Of (G) = 0, "Clear => root unset");
      L1 := Add_Leaf (G, 7);
      L2 := Add_Leaf (G, -3);
      Check (L1 = 1, "first leaf id 1");
      Check (L2 = 2, "second leaf id 2");
      Check (Kind_Of (G, L1) = Leaf, "Kind leaf");
      Check (Leaf_Value (G, L1) = 7, "Leaf_Value 7");
      Check (Leaf_Value (G, L2) = -3, "Leaf_Value -3");
      Check (Child_Count_Of (G, L1) = 0, "leaf children 0");
      M := Add_Internal (G, Max_Node, [L1, L2]);
      Check (Kind_Of (G, M) = Max_Node, "Kind Max");
      Check (Child_Count_Of (G, M) = 2, "Max children 2");
      Check (Child_Of (G, M, 1) = L1, "child 1");
      Check (Child_Of (G, M, 2) = L2, "child 2");
      Check (Child_Of (G, M, 3) = 0, "missing child => 0");
      Set_Root (G, M);
      Check (Root_Of (G) = M, "Set_Root");
      Check (Node_Count (G) = 3, "count 3");
   end;

   ---------------------------------------------------------------------
   Section ("2. Single leaf root");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      L : Valid_Node;
   begin
      Clear (G);
      L := Add_Leaf (G, 42);
      Set_Root (G, L);
      Check_Both (G, 42, "leaf 42");
      Clear (G);
      L := Add_Leaf (G, 0);
      Set_Root (G, L);
      Check_Both (G, 0, "leaf 0");
      Clear (G);
      L := Add_Leaf (G, -99);
      Set_Root (G, L);
      Check_Both (G, -99, "leaf -99");
   end;

   ---------------------------------------------------------------------
   Section ("3. Shallow Max of leaves");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      A, B, C, R : Valid_Node;
   begin
      Clear (G);
      A := Add_Leaf (G, 3);
      B := Add_Leaf (G, 5);
      C := Add_Leaf (G, 2);
      R := Add_Internal (G, Max_Node, [A, B, C]);
      Set_Root (G, R);
      Check_Both (G, 5, "max(3,5,2)");

      Clear (G);
      A := Add_Leaf (G, -10);
      B := Add_Leaf (G, -1);
      R := Add_Internal (G, Max_Node, [A, B]);
      Set_Root (G, R);
      Check_Both (G, -1, "max(-10,-1)");

      Clear (G);
      A := Add_Leaf (G, 7);
      R := Add_Internal (G, Max_Node, [A]);
      Set_Root (G, R);
      Check_Both (G, 7, "max singleton");
   end;

   ---------------------------------------------------------------------
   Section ("4. Shallow Min of leaves");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      A, B, C, R : Valid_Node;
   begin
      Clear (G);
      A := Add_Leaf (G, 3);
      B := Add_Leaf (G, 5);
      C := Add_Leaf (G, 2);
      R := Add_Internal (G, Min_Node, [A, B, C]);
      Set_Root (G, R);
      Check_Both (G, 2, "min(3,5,2)");

      Clear (G);
      A := Add_Leaf (G, 10);
      B := Add_Leaf (G, -4);
      R := Add_Internal (G, Min_Node, [A, B]);
      Set_Root (G, R);
      Check_Both (G, -4, "min(10,-4)");

      Clear (G);
      A := Add_Leaf (G, 8);
      R := Add_Internal (G, Min_Node, [A]);
      Set_Root (G, R);
      Check_Both (G, 8, "min singleton");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia-style max(min(3,5), min(2,9)) = 3");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      L3, L5, L2, L9, MinL, MinR, Root : Valid_Node;
   begin
      Clear (G);
      L3 := Add_Leaf (G, 3);
      L5 := Add_Leaf (G, 5);
      L2 := Add_Leaf (G, 2);
      L9 := Add_Leaf (G, 9);
      MinL := Add_Internal (G, Min_Node, [L3, L5]);
      MinR := Add_Internal (G, Min_Node, [L2, L9]);
      Root := Add_Internal (G, Max_Node, [MinL, MinR]);
      Set_Root (G, Root);
      Check_Both (G, 3, "wiki shallow");
   end;

   ---------------------------------------------------------------------
   Section ("6. max(min(1,2,3), min(8,0), min(4,4))");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      A, B, C, D, E, F, M1, M2, M3, R : Valid_Node;
   begin
      Clear (G);
      A := Add_Leaf (G, 1);
      B := Add_Leaf (G, 2);
      C := Add_Leaf (G, 3);
      D := Add_Leaf (G, 8);
      E := Add_Leaf (G, 0);
      F := Add_Leaf (G, 4);
      --  second 4
      declare
         F2 : Valid_Node;
      begin
         F2 := Add_Leaf (G, 4);
         M1 := Add_Internal (G, Min_Node, [A, B, C]);
         M2 := Add_Internal (G, Min_Node, [D, E]);
         M3 := Add_Internal (G, Min_Node, [F, F2]);
         R := Add_Internal (G, Max_Node, [M1, M2, M3]);
         Set_Root (G, R);
         --  max(min(1,2,3), min(8,0), min(4,4)) = max(1,0,4) = 4
         Check_Both (G, 4, "asymmetric three mins");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Deeper alternating trees");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      --  max( min( max(1,8), max(3,2) ), min( max(9,0), max(4,5) ) )
      --  = max( min(8,3), min(9,5) ) = max(3,5) = 5
      L1, L8, L3, L2, L9, L0, L4, L5 : Valid_Node;
      X1, X2, X3, X4, N1, N2, R : Valid_Node;
   begin
      Clear (G);
      L1 := Add_Leaf (G, 1);
      L8 := Add_Leaf (G, 8);
      L3 := Add_Leaf (G, 3);
      L2 := Add_Leaf (G, 2);
      L9 := Add_Leaf (G, 9);
      L0 := Add_Leaf (G, 0);
      L4 := Add_Leaf (G, 4);
      L5 := Add_Leaf (G, 5);
      X1 := Add_Internal (G, Max_Node, [L1, L8]);
      X2 := Add_Internal (G, Max_Node, [L3, L2]);
      X3 := Add_Internal (G, Max_Node, [L9, L0]);
      X4 := Add_Internal (G, Max_Node, [L4, L5]);
      N1 := Add_Internal (G, Min_Node, [X1, X2]);
      N2 := Add_Internal (G, Min_Node, [X3, X4]);
      R  := Add_Internal (G, Max_Node, [N1, N2]);
      Set_Root (G, R);
      Check_Both (G, 5, "depth-3 alternating = 5");
   end;

   ---------------------------------------------------------------------
   Section ("8. Min root over Max children");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      A, B, C, D, X1, X2, R : Valid_Node;
   begin
      Clear (G);
      A := Add_Leaf (G, 2);
      B := Add_Leaf (G, 9);
      C := Add_Leaf (G, 4);
      D := Add_Leaf (G, 1);
      X1 := Add_Internal (G, Max_Node, [A, B]);  -- 9
      X2 := Add_Internal (G, Max_Node, [C, D]);  -- 4
      R := Add_Internal (G, Min_Node, [X1, X2]); -- min(9,4)=4
      Set_Root (G, R);
      Check_Both (G, 4, "min(max,max)=4");
   end;

   ---------------------------------------------------------------------
   Section ("9. Identical Evaluate/Minimax batch");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      Ls : array (1 .. 8) of Valid_Node;
      R  : Valid_Node;
      type Int_Vec is array (Positive range <>) of Integer;
      Data : constant Int_Vec :=
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
         -5, -2, 0, 100, -100, 17, 23, 42, 11, 13];
   begin
      --  Max of prefixes of Data
      for Len in 1 .. 8 loop
         Clear (G);
         for I in 1 .. Len loop
            Ls (I) := Add_Leaf (G, Data (I));
         end loop;
         declare
            Kids : Node_List (1 .. Len);
            Exp  : Integer := Data (1);
         begin
            for I in 1 .. Len loop
               Kids (I) := Ls (I);
               if Data (I) > Exp then
                  Exp := Data (I);
               end if;
            end loop;
            R := Add_Internal (G, Max_Node, Kids);
            Set_Root (G, R);
            Check_Both
              (G, Exp, "max prefix len" & Integer'Image (Len));
         end;
      end loop;

      --  Min of prefixes
      for Len in 1 .. 8 loop
         Clear (G);
         for I in 1 .. Len loop
            Ls (I) := Add_Leaf (G, Data (I));
         end loop;
         declare
            Kids : Node_List (1 .. Len);
            Exp  : Integer := Data (1);
         begin
            for I in 1 .. Len loop
               Kids (I) := Ls (I);
               if Data (I) < Exp then
                  Exp := Data (I);
               end if;
            end loop;
            R := Add_Internal (G, Min_Node, Kids);
            Set_Root (G, R);
            Check_Both
              (G, Exp, "min prefix len" & Integer'Image (Len));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Pairwise max(min) matrices");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      --  For pairs (a,b) / (c,d): max(min(a,b), min(c,d))
      procedure Pair
        (A, B, C, D : Integer; Label : String)
      is
         La, Lb, Lc, Ld, M1, M2, R : Valid_Node;
         Exp : Integer;
         Mleft, Mright : Integer;
      begin
         Clear (G);
         La := Add_Leaf (G, A);
         Lb := Add_Leaf (G, B);
         Lc := Add_Leaf (G, C);
         Ld := Add_Leaf (G, D);
         M1 := Add_Internal (G, Min_Node, [La, Lb]);
         M2 := Add_Internal (G, Min_Node, [Lc, Ld]);
         R  := Add_Internal (G, Max_Node, [M1, M2]);
         Set_Root (G, R);
         Mleft := Integer'Min (A, B);
         Mright := Integer'Min (C, D);
         Exp := Integer'Max (Mleft, Mright);
         Check_Both (G, Exp, Label);
      end Pair;
   begin
      Pair (3, 5, 2, 9, "wiki again");
      Pair (1, 1, 1, 1, "all ones");
      Pair (10, 0, 5, 5, "max(0,5)=5");
      Pair (-1, -2, -3, -4, "negatives");
      Pair (100, 50, 60, 70, "max(50,60)=60");
      Pair (0, 8, 0, 8, "ties");
      Pair (7, 3, 7, 2, "max(3,2)=3");
      Pair (4, 4, 5, 1, "max(4,1)=4");
      Pair (9, 1, 8, 2, "max(1,2)=2");
      Pair (6, 6, 6, 0, "max(6,0)=6");
      Pair (-5, 5, -5, 5, "max(-5,-5)=-5");
      Pair (2, 8, 3, 7, "max(2,3)=3");
      Pair (15, 14, 13, 12, "max(14,12)=14");
      Pair (1, 100, 2, 3, "max(1,2)=2");
      Pair (50, 40, 30, 60, "max(40,30)=40");
   end;

   ---------------------------------------------------------------------
   Section ("11. min(max) dual pairs");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      procedure Pair
        (A, B, C, D : Integer; Label : String)
      is
         La, Lb, Lc, Ld, X1, X2, R : Valid_Node;
         Exp : Integer;
      begin
         Clear (G);
         La := Add_Leaf (G, A);
         Lb := Add_Leaf (G, B);
         Lc := Add_Leaf (G, C);
         Ld := Add_Leaf (G, D);
         X1 := Add_Internal (G, Max_Node, [La, Lb]);
         X2 := Add_Internal (G, Max_Node, [Lc, Ld]);
         R  := Add_Internal (G, Min_Node, [X1, X2]);
         Set_Root (G, R);
         Exp := Integer'Min (Integer'Max (A, B), Integer'Max (C, D));
         Check_Both (G, Exp, Label);
      end Pair;
   begin
      Pair (1, 8, 3, 2, "min(8,3)=3");
      Pair (0, 0, 0, 0, "zeros");
      Pair (-1, 5, 4, -2, "min(5,4)=4");
      Pair (10, 20, 15, 5, "min(20,15)=15");
      Pair (9, 1, 2, 8, "min(9,8)=8");
      Pair (3, 3, 3, 3, "flat");
      Pair (-10, -3, -8, -1, "min(-3,-1)=-3");
      Pair (100, -100, 50, 50, "min(100,50)=50");
      Pair (7, 2, 7, 9, "min(7,9)=7");
      Pair (4, 5, 6, 1, "min(5,6)=5");
   end;

   ---------------------------------------------------------------------
   Section ("12. Left-biased vs right-biased values");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      procedure Build_Max_Mins
        (Left_Min, Right_Min : Integer; Exp : Integer; Label : String)
      is
         --  max( min(Left_Min, Left_Min+10), min(Right_Min, Right_Min+10) )
         A, B, C, D, M1, M2, R : Valid_Node;
      begin
         Clear (G);
         A := Add_Leaf (G, Left_Min);
         B := Add_Leaf (G, Left_Min + 10);
         C := Add_Leaf (G, Right_Min);
         D := Add_Leaf (G, Right_Min + 10);
         M1 := Add_Internal (G, Min_Node, [A, B]);
         M2 := Add_Internal (G, Min_Node, [C, D]);
         R := Add_Internal (G, Max_Node, [M1, M2]);
         Set_Root (G, R);
         Check_Both (G, Exp, Label);
      end Build_Max_Mins;
   begin
      Build_Max_Mins (1, 5, 5, "right better");
      Build_Max_Mins (8, 2, 8, "left better");
      Build_Max_Mins (4, 4, 4, "equal branches");
      Build_Max_Mins (-3, 0, 0, "neg vs zero");
      Build_Max_Mins (12, 11, 12, "close left");
      Build_Max_Mins (11, 12, 12, "close right");
   end;

   ---------------------------------------------------------------------
   Section ("13. Wide MAX / MIN");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      Kids : Node_List (1 .. 10);
      R : Valid_Node;
      Exp_Max : Integer;
      Exp_Min : Integer;
   begin
      Clear (G);
      Exp_Max := Integer'First;
      Exp_Min := Integer'Last;
      for I in 1 .. 10 loop
         declare
            V : constant Integer := I * 3 - 11;  -- -8,-5,...,19
         begin
            Kids (I) := Add_Leaf (G, V);
            if V > Exp_Max then
               Exp_Max := V;
            end if;
            if V < Exp_Min then
               Exp_Min := V;
            end if;
         end;
      end loop;
      R := Add_Internal (G, Max_Node, Kids);
      Set_Root (G, R);
      Check_Both (G, Exp_Max, "wide max 10");

      Clear (G);
      for I in 1 .. 10 loop
         Kids (I) := Add_Leaf (G, I * 3 - 11);
      end loop;
      R := Add_Internal (G, Min_Node, Kids);
      Set_Root (G, R);
      Check_Both (G, Exp_Min, "wide min 10");
   end;

   ---------------------------------------------------------------------
   Section ("14. Chain Max-Min-Max-Min");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      --  Root Max with one Min child with one Max child with two leaves
      L1, L2, X, N, R : Valid_Node;
   begin
      Clear (G);
      L1 := Add_Leaf (G, 6);
      L2 := Add_Leaf (G, 4);
      X := Add_Internal (G, Max_Node, [L1, L2]);  -- 6
      N := Add_Internal (G, Min_Node, [X]);       -- 6
      R := Add_Internal (G, Max_Node, [N]);       -- 6
      Set_Root (G, R);
      Check_Both (G, 6, "unary chain 6");

      Clear (G);
      L1 := Add_Leaf (G, -2);
      L2 := Add_Leaf (G, 9);
      X := Add_Internal (G, Max_Node, [L1, L2]);
      N := Add_Internal (G, Min_Node, [X]);
      R := Add_Internal (G, Max_Node, [N]);
      Set_Root (G, R);
      Check_Both (G, 9, "unary chain 9");
   end;

   ---------------------------------------------------------------------
   Section ("15. Invalid_Argument cases");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      L : Valid_Node;
      U : Integer;
      N : Valid_Node;
      Empty : Node_List (1 .. 0);
   begin
      begin
         Clear (G);
         U := Evaluate (G);
         Check (False, "Evaluate empty (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "Evaluate empty");
      end;

      begin
         Clear (G);
         L := Add_Leaf (G, 1);
         U := Evaluate (G);
         Check (False, "Evaluate no root (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "Evaluate no root");
      end;

      begin
         Clear (G);
         L := Add_Leaf (G, 1);
         N := Add_Internal (G, Leaf, [L]);
         Check (False, "Add_Internal Leaf kind (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "Add_Internal Leaf kind");
      end;

      begin
         Clear (G);
         N := Add_Internal (G, Max_Node, Empty);
         Check (False, "Add_Internal empty kids (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "Add_Internal empty kids");
      end;

      begin
         Clear (G);
         L := Add_Leaf (G, 1);
         N := Add_Internal (G, Max_Node, [L]);
         N := Add_Internal (G, Min_Node, [L]);
         Check (False, "child already linked (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "child already linked");
      end;

      begin
         Clear (G);
         L := Add_Leaf (G, 1);
         N := Add_Internal (G, Max_Node, [L, L]);
         Check (False, "duplicate child (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "duplicate child");
      end;

      begin
         Clear (G);
         Set_Root (G, 1);
         Check (False, "Set_Root unknown (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "Set_Root unknown");
      end;

      begin
         Clear (G);
         U := Minimax (G);
         Check (False, "Minimax empty (no exception)");
      exception
         when Invalid_Argument =>
            Check (True, "Minimax empty");
      end;

      pragma Unreferenced (U, N);
   end;

   ---------------------------------------------------------------------
   Section ("16. More random-ish fixed fixtures");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      type Int_Vec is array (Positive range <>) of Integer;

      --  Explicit trees: max of several mins of two leaves each
      procedure Max_Of_Pair_Mins
        (Pairs    : Int_Vec;  -- flattened a,b,a,b,...
         Expected : Integer;
         Label    : String)
      is
         N_Pairs : constant Natural := Pairs'Length / 2;
         Mins : Node_List (1 .. N_Pairs);
         R : Valid_Node;
         Idx : Natural := Pairs'First;
      begin
         Clear (G);
         for P in 1 .. N_Pairs loop
            declare
               A : constant Valid_Node := Add_Leaf (G, Pairs (Idx));
               B : constant Valid_Node := Add_Leaf (G, Pairs (Idx + 1));
            begin
               Mins (P) := Add_Internal (G, Min_Node, [A, B]);
               Idx := Idx + 2;
            end;
         end loop;
         R := Add_Internal (G, Max_Node, Mins);
         Set_Root (G, R);
         Check_Both (G, Expected, Label);
      end Max_Of_Pair_Mins;
   begin
      Max_Of_Pair_Mins ([3, 5, 2, 9], 3, "fix wiki");
      Max_Of_Pair_Mins ([1, 2, 3, 4, 5, 0], 3, "three pairs -> 3");
      Max_Of_Pair_Mins ([10, 10, 9, 8], 10, "ten wins");
      Max_Of_Pair_Mins ([0, 1, 0, 2, 0, 3], 0, "all mins 0");
      Max_Of_Pair_Mins ([-1, 5, -2, 4, -3, 3], -1, "neg mins");
      Max_Of_Pair_Mins ([8, 1, 7, 2, 6, 3, 5, 4], 4, "four pairs -> 4");
      Max_Of_Pair_Mins ([20, 0, 15, 15], 15, "20/0 vs 15");
      Max_Of_Pair_Mins ([4, 4], 4, "single pair");
      Max_Of_Pair_Mins ([100, -100, -50, -25], -50, "wide swing");
      Max_Of_Pair_Mins ([2, 2, 2, 2, 2, 2], 2, "flat twos");
   end;

   ---------------------------------------------------------------------
   Section ("17. Negamax-shaped deeper tree");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      --  Root Min; two Max; each Max has Min of leaves
      --  min( max(min(1,4), min(5,0)), max(min(3,3), min(2,9)) )
      --  = min( max(1,0), max(3,2) ) = min(1,3) = 1
      procedure Build is
         L1, L4, L5, L0, L3, L3b, L2, L9 : Valid_Node;
         N1, N2, N3, N4, X1, X2, R : Valid_Node;
      begin
         Clear (G);
         L1 := Add_Leaf (G, 1);
         L4 := Add_Leaf (G, 4);
         L5 := Add_Leaf (G, 5);
         L0 := Add_Leaf (G, 0);
         L3 := Add_Leaf (G, 3);
         L3b := Add_Leaf (G, 3);
         L2 := Add_Leaf (G, 2);
         L9 := Add_Leaf (G, 9);
         N1 := Add_Internal (G, Min_Node, [L1, L4]);
         N2 := Add_Internal (G, Min_Node, [L5, L0]);
         N3 := Add_Internal (G, Min_Node, [L3, L3b]);
         N4 := Add_Internal (G, Min_Node, [L2, L9]);
         X1 := Add_Internal (G, Max_Node, [N1, N2]);
         X2 := Add_Internal (G, Max_Node, [N3, N4]);
         R  := Add_Internal (G, Min_Node, [X1, X2]);
         Set_Root (G, R);
         Check_Both (G, 1, "deep min root = 1");
      end Build;
   begin
      Build;
   end;

   ---------------------------------------------------------------------
   Section ("18. Capacity / wide fan-out");
   ---------------------------------------------------------------------
   --  Fill many leaves under one max
   declare
      G : Game_Tree;
      Kids : Node_List (1 .. 16);
      R : Valid_Node;
   begin
      Clear (G);
      for I in 1 .. 16 loop
         Kids (I) := Add_Leaf (G, I);
      end loop;
      R := Add_Internal (G, Max_Node, Kids);
      Set_Root (G, R);
      Check_Both (G, 16, "max of 1..16");
      Clear (G);
      for I in 1 .. 16 loop
         Kids (I) := Add_Leaf (G, I);
      end loop;
      R := Add_Internal (G, Min_Node, Kids);
      Set_Root (G, R);
      Check_Both (G, 1, "min of 1..16");
   end;

   ---------------------------------------------------------------------
   Section ("19. Equal-merit leftmost / pruning-ish");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      --  max(min(5,5), min(5,6), min(4,9)) = max(5,5,4) = 5
      A, B, C, D, E, F, M1, M2, M3, R : Valid_Node;
   begin
      Clear (G);
      A := Add_Leaf (G, 5);
      B := Add_Leaf (G, 5);
      C := Add_Leaf (G, 5);
      D := Add_Leaf (G, 6);
      E := Add_Leaf (G, 4);
      F := Add_Leaf (G, 9);
      M1 := Add_Internal (G, Min_Node, [A, B]);
      M2 := Add_Internal (G, Min_Node, [C, D]);
      M3 := Add_Internal (G, Min_Node, [E, F]);
      R := Add_Internal (G, Max_Node, [M1, M2, M3]);
      Set_Root (G, R);
      Check_Both (G, 5, "equal branch merits");
   end;

   ---------------------------------------------------------------------
   Section ("20. Clear resets for reuse");
   ---------------------------------------------------------------------
   declare
      G : Game_Tree;
      L, R : Valid_Node;
   begin
      Clear (G);
      L := Add_Leaf (G, 1);
      R := Add_Internal (G, Max_Node, [L]);
      Set_Root (G, R);
      Check_Both (G, 1, "before clear");
      Clear (G);
      Check (Node_Count (G) = 0, "after clear count");
      L := Add_Leaf (G, 99);
      Set_Root (G, L);
      Check_Both (G, 99, "after rebuild");
   end;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
      raise Program_Error with "test failures";
   else
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   end if;
end Tests;
