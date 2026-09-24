--  Standalone test suite for Hopcroft_Karp_Algorithm.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Hopcroft_Karp_Algorithm; use Hopcroft_Karp_Algorithm;

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
   function L_Id (X : Positive) return Left_Id is (Left_Id (X));
   function R_Id (X : Positive) return Right_Id is (Right_Id (X));

   function Clear_Raises (L, R : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, L, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; Left : Left_Id; Right : Right_Id) return Boolean
   is
   begin
      Add_Edge (G, Left, Right);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Oracle_Raises (G : Graph) return Boolean is
      R : Matching_Result;
   begin
      Matching_Oracle_DFS (G, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Oracle_Raises;

   function Edge_Query_Raises (G : Graph; Index : Positive) return Boolean is
      A : Left_Id;
      B : Right_Id;
   begin
      A := Edge_Left (G, Index);
      B := Edge_Right (G, Index);
      pragma Unreferenced (A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Edge_Query_Raises;

   procedure Agree_HK_Oracle (G : Graph; Label : String) is
      R1, R2 : Matching_Result;
   begin
      Maximum_Matching (G, R1);
      Matching_Oracle_DFS (G, R2);
      Check (R1.Size = R2.Size, Label & " size agree");
      Check (Is_Valid_Matching (G, R1), Label & " HK valid");
      Check (Is_Valid_Matching (G, R2), Label & " oracle valid");
   end Agree_HK_Oracle;

   procedure Expect_Size (G : Graph; Expected : Natural; Label : String) is
      R : Matching_Result;
   begin
      Maximum_Matching (G, R);
      Check (R.Size = Expected, Label & " size");
      Check (Is_Valid_Matching (G, R), Label & " valid");
      Check (R.Left_N = Left_Count (G), Label & " Left_N");
      Check (R.Right_N = Right_Count (G), Label & " Right_N");
   end Expect_Size;

   G : Graph;
   R : Matching_Result;

begin
   Put_Line ("Hopcroft_Karp_Algorithm test suite");
   Put_Line ("==================================");

   ---------------------------------------------------------------------
   Section ("1. Empty / trivial sides");
   ---------------------------------------------------------------------
   Clear (G, Nat (0), Nat (0));
   Check (Left_Count (G) = 0, "L=0");
   Check (Right_Count (G) = 0, "R=0");
   Check (Edge_Count (G) = 0, "M=0");
   Maximum_Matching (G, R);
   Check (R.Size = 0, "empty matching 0");
   Check (Is_Valid_Matching (G, R), "empty valid");
   Matching_Oracle_DFS (G, R);
   Check (R.Size = 0, "oracle empty 0");

   Clear (G, Nat (3), Nat (0));
   Maximum_Matching (G, R);
   Check (R.Size = 0, "R=0 matching 0");
   Check (R.Left_N = 3, "R=0 Left_N");

   Clear (G, Nat (0), Nat (4));
   Maximum_Matching (G, R);
   Check (R.Size = 0, "L=0 matching 0");
   Check (R.Right_N = 4, "L=0 Right_N");

   Clear (G, Nat (1), Nat (1));
   Maximum_Matching (G, R);
   Check (R.Size = 0, "no-edge 1x1 size 0");
   Add_Edge (G, 1, 1);
   Expect_Size (G, Nat (1), "single edge");
   Agree_HK_Oracle (G, "single");

   ---------------------------------------------------------------------
   Section ("2. Perfect matchings");
   ---------------------------------------------------------------------
   Clear (G, 3, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 3, 3);
   Expect_Size (G, Nat (3), "identity 3");
   Agree_HK_Oracle (G, "id3");

   Clear (G, 3, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Expect_Size (G, Nat (3), "cycle 3");
   Agree_HK_Oracle (G, "cyc3");

   Clear (G, 4, 4);
   for I in 1 .. 4 loop
      Add_Edge (G, L_Id (I), R_Id (I));
      if I < 4 then
         Add_Edge (G, L_Id (I), R_Id (I + 1));
      end if;
   end loop;
   Expect_Size (G, Nat (4), "path-ish 4");
   Agree_HK_Oracle (G, "path4");

   Clear (G, 5, 5);
   for I in 1 .. 5 loop
      for J in 1 .. 5 loop
         Add_Edge (G, L_Id (I), R_Id (J));
      end loop;
   end loop;
   Expect_Size (G, Nat (5), "K5,5");
   Agree_HK_Oracle (G, "K55");

   ---------------------------------------------------------------------
   Section ("3. Non-perfect matchings");
   ---------------------------------------------------------------------
   Clear (G, 3, 2);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 2);
   Expect_Size (G, Nat (2), "3L2R max2");
   Agree_HK_Oracle (G, "3L2R");

   Clear (G, 2, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 2);
   Expect_Size (G, Nat (2), "2L3R max2");
   Agree_HK_Oracle (G, "2L3R");

   Clear (G, 4, 4);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 2);
   Add_Edge (G, 4, 2);
   Expect_Size (G, Nat (2), "bottleneck 2");
   Agree_HK_Oracle (G, "bottle");

   Clear (G, 4, 4);
   --  No edges incident to left 4 or right 4
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 3, 3);
   Expect_Size (G, Nat (3), "isolated vertex");
   Agree_HK_Oracle (G, "isol");

   ---------------------------------------------------------------------
   Section ("4. Classic Wikipedia-style examples");
   ---------------------------------------------------------------------
   --  Two augmenting phases often needed: free lefts share neighbors.
   Clear (G, 4, 4);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 2);
   Add_Edge (G, 3, 3);
   Add_Edge (G, 4, 3);
   Add_Edge (G, 4, 4);
   Expect_Size (G, Nat (4), "wiki-ish perfect");
   Agree_HK_Oracle (G, "wikiish");

   Clear (G, 3, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 3, 3);
   Expect_Size (G, Nat (3), "simple perfect");
   Maximum_Matching (G, R);
   Check (R.Pair_U (3) = 3, "left3->right3");
   Check (R.Pair_V (3) = 3, "right3->left3");

   ---------------------------------------------------------------------
   Section ("5. Parallel edges / duplicates");
   ---------------------------------------------------------------------
   Clear (G, 2, 2);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Check (Edge_Count (G) = 4, "parallel count");
   Expect_Size (G, Nat (2), "parallel perfect");
   Agree_HK_Oracle (G, "parallel");

   ---------------------------------------------------------------------
   Section ("6. Mate arrays consistency");
   ---------------------------------------------------------------------
   Clear (G, 4, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 3, 3);
   Add_Edge (G, 4, 1);
   Maximum_Matching (G, R);
   Check (R.Size = 3, "4x3 size 3");
   for U in 1 .. 4 loop
      if R.Pair_U (U) /= 0 then
         Check (R.Pair_V (R.Pair_U (U)) = U, "mutual mate L");
      end if;
   end loop;
   for V in 1 .. 3 loop
      if R.Pair_V (V) /= 0 then
         Check (R.Pair_U (R.Pair_V (V)) = V, "mutual mate R");
      end if;
   end loop;
   Check (Is_Valid_Matching (G, R), "4x3 valid");

   ---------------------------------------------------------------------
   Section ("7. Oracle agreement batch");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      Clear (G, N, N);
      for I in 1 .. N loop
         Add_Edge (G, L_Id (I), R_Id (I));
      end loop;
      Agree_HK_Oracle (G, "diag" & Natural'Image (N));
   end loop;

   for N in 2 .. 6 loop
      Clear (G, N, N);
      for I in 1 .. N loop
         for J in 1 .. N loop
            if (I + J) mod 2 = 0 then
               Add_Edge (G, L_Id (I), R_Id (J));
            end if;
         end loop;
      end loop;
      Agree_HK_Oracle (G, "parity" & Natural'Image (N));
   end loop;

   for N in 3 .. 7 loop
      Clear (G, N, N - 1);
      for I in 1 .. N - 1 loop
         Add_Edge (G, L_Id (I), R_Id (I));
         Add_Edge (G, L_Id (I + 1), R_Id (I));
      end loop;
      Agree_HK_Oracle (G, "chain" & Natural'Image (N));
   end loop;

   ---------------------------------------------------------------------
   Section ("8. Larger HK-only graphs");
   ---------------------------------------------------------------------
   Clear (G, 32, 32);
   for I in 1 .. 32 loop
      Add_Edge (G, L_Id (I), R_Id (I));
      Add_Edge (G, L_Id (I), R_Id (1 + (I mod 32)));
   end loop;
   Expect_Size (G, Nat (32), "n=32 perfect");

   Clear (G, 64, 64);
   for I in 1 .. 64 loop
      Add_Edge (G, L_Id (I), R_Id (I));
   end loop;
   Expect_Size (G, Nat (64), "n=64 identity");
   --  Oracle allowed at Max_Oracle_Side = 64
   Agree_HK_Oracle (G, "n64");

   Clear (G, 100, 100);
   for I in 1 .. 100 loop
      Add_Edge (G, L_Id (I), R_Id (I));
      if I < 100 then
         Add_Edge (G, L_Id (I), R_Id (I + 1));
      end if;
   end loop;
   Expect_Size (G, Nat (100), "n=100 path");

   Clear (G, 200, 150);
   for I in 1 .. 150 loop
      Add_Edge (G, L_Id (I), R_Id (I));
      Add_Edge (G, L_Id (I + 50), R_Id (I));
   end loop;
   Expect_Size (G, Nat (150), "200x150 max150");

   ---------------------------------------------------------------------
   Section ("9. Edge inspectors");
   ---------------------------------------------------------------------
   Clear (G, 3, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 1);
   Check (Edge_Left (G, 1) = 1, "e1 left");
   Check (Edge_Right (G, 1) = 2, "e1 right");
   Check (Edge_Left (G, 2) = 3, "e2 left");
   Check (Edge_Right (G, 2) = 1, "e2 right");
   Check (Edge_Query_Raises (G, Nat (3)), "edge 3 raises");
   Check (Edge_Query_Raises (G, Nat (99)), "edge 99 raises");

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument");
   ---------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Left + 1), Nat (1)), "Clear L overflow");
   Check (Clear_Raises (Nat (1), Nat (Max_Right + 1)), "Clear R overflow");
   Check (not Clear_Raises (Nat (Max_Left), Nat (Max_Right)),
          "Clear max ok");

   Clear (G, 2, 2);
   Check (Add_Raises (G, L_Id (3), R_Id (1)), "Add left OOB");
   Check (Add_Raises (G, L_Id (1), R_Id (3)), "Add right OOB");

   Clear (G, Max_Oracle_Side + 1, 1);
   Check (Oracle_Raises (G), "oracle L overflow");
   Clear (G, 1, Max_Oracle_Side + 1);
   Check (Oracle_Raises (G), "oracle R overflow");
   Clear (G, Max_Oracle_Side, Max_Oracle_Side);
   Check (not Oracle_Raises (G), "oracle at cap ok");

   --  Is_Valid_Matching rejects mismatched dimensions
   Clear (G, 2, 2);
   Add_Edge (G, 1, 1);
   Maximum_Matching (G, R);
   R.Left_N := 1;
   Check (not Is_Valid_Matching (G, R), "bad Left_N rejected");

   ---------------------------------------------------------------------
   Section ("11. Max_Edges overflow");
   ---------------------------------------------------------------------
   declare
      Tiny : Graph;
      Raised : Boolean := False;
   begin
      Clear (Tiny, 2, 2);
      begin
         for K in 1 .. Max_Edges loop
            Add_Edge (Tiny, 1, 1);
         end loop;
         Check (Edge_Count (Tiny) = Max_Edges, "filled Max_Edges");
         begin
            Add_Edge (Tiny, 1, 2);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Add beyond Max_Edges");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Unbalanced / sparse families");
   ---------------------------------------------------------------------
   for A in 1 .. 5 loop
      for B in 1 .. 5 loop
         Clear (G, A, B);
         for I in 1 .. A loop
            for J in 1 .. B loop
               if I = J or else I + J = A + 1 then
                  Add_Edge (G, L_Id (I), R_Id (J));
               end if;
            end loop;
         end loop;
         Agree_HK_Oracle
           (G, "grid" & Natural'Image (A) & "x" & Natural'Image (B));
      end loop;
   end loop;

   ---------------------------------------------------------------------
   Section ("13. Forced augmenting path length > 1");
   ---------------------------------------------------------------------
   --  Greedy single edge matching may need length-3 augmenting path.
   Clear (G, 3, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 3, 2);
   Expect_Size (G, Nat (2), "need augment");
   Agree_HK_Oracle (G, "augpath");

   Clear (G, 5, 5);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 3, 2);
   Add_Edge (G, 3, 3);
   Add_Edge (G, 4, 3);
   Add_Edge (G, 4, 4);
   Add_Edge (G, 5, 4);
   Add_Edge (G, 5, 5);
   Expect_Size (G, Nat (5), "long chain perfect");
   Agree_HK_Oracle (G, "longchain");

   ---------------------------------------------------------------------
   Section ("14. Disconnected components");
   ---------------------------------------------------------------------
   Clear (G, 6, 6);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 4, 4);
   Add_Edge (G, 5, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 6);
   Expect_Size (G, Nat (5), "two comps + isol");
   Agree_HK_Oracle (G, "comps");

   ---------------------------------------------------------------------
   Section ("15. Clear resets edges");
   ---------------------------------------------------------------------
   Clear (G, 3, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 2, 2);
   Clear (G, 2, 2);
   Check (Edge_Count (G) = 0, "cleared edges");
   Check (Left_Count (G) = 2, "cleared L");
   Maximum_Matching (G, R);
   Check (R.Size = 0, "cleared matching 0");
   Add_Edge (G, 1, 2);
   Expect_Size (G, Nat (1), "after clear add");

   ---------------------------------------------------------------------
   Section ("16. Complete bipartite K(n,m) sizes");
   ---------------------------------------------------------------------
   for N in 1 .. 6 loop
      for M in 1 .. 6 loop
         Clear (G, N, M);
         for I in 1 .. N loop
            for J in 1 .. M loop
               Add_Edge (G, L_Id (I), R_Id (J));
            end loop;
         end loop;
         declare
            Exp : constant Natural := Natural'Min (N, M);
         begin
            Expect_Size
              (G, Exp,
               "K" & Natural'Image (N) & "," & Natural'Image (M));
         end;
      end loop;
   end loop;

   ---------------------------------------------------------------------
   Section ("17. Star graphs");
   ---------------------------------------------------------------------
   Clear (G, 1, 8);
   for J in 1 .. 8 loop
      Add_Edge (G, 1, R_Id (J));
   end loop;
   Expect_Size (G, Nat (1), "left star");
   Agree_HK_Oracle (G, "Lstar");

   Clear (G, 8, 1);
   for I in 1 .. 8 loop
      Add_Edge (G, L_Id (I), 1);
   end loop;
   Expect_Size (G, Nat (1), "right star");
   Agree_HK_Oracle (G, "Rstar");

   ---------------------------------------------------------------------
   Section ("18. Random-ish deterministic families");
   ---------------------------------------------------------------------
   for Seed in 1 .. 12 loop
      declare
         N : constant Natural := 4 + (Seed mod 5);
         M : constant Natural := 4 + ((Seed * 3) mod 5);
      begin
         Clear (G, N, M);
         for I in 1 .. N loop
            for J in 1 .. M loop
               if ((I * 17 + J * 13 + Seed * 7) mod 5) < 2 then
                  Add_Edge (G, L_Id (I), R_Id (J));
               end if;
            end loop;
         end loop;
         Agree_HK_Oracle (G, "rand" & Natural'Image (Seed));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("19. Cap Max_Left / Max_Right smoke");
   ---------------------------------------------------------------------
   Clear (G, Max_Left, 1);
   Check (Left_Count (G) = Max_Left, "Max_Left ok");
   Add_Edge (G, Left_Id (Max_Left), 1);
   Expect_Size (G, Nat (1), "Max_Left edge");

   Clear (G, 1, Max_Right);
   Add_Edge (G, 1, Right_Id (Max_Right));
   Expect_Size (G, Nat (1), "Max_Right edge");

   ---------------------------------------------------------------------
   Section ("20. Matching size vs Konig bound checks");
   ---------------------------------------------------------------------
   Clear (G, 5, 5);
   --  Vertex cover of size 2: all edges touch left {1,2} or right empty
   for J in 1 .. 5 loop
      Add_Edge (G, 1, R_Id (J));
      Add_Edge (G, 2, R_Id (J));
   end loop;
   Expect_Size (G, Nat (2), "cover2 => match2");
   Agree_HK_Oracle (G, "cover2");

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("==================================");
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
