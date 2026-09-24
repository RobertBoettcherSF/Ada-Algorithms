--  Standalone test suite for Tarjans_Off_Line_Lowest_Common_Ancestors.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Tarjans_Off_Line_Lowest_Common_Ancestors;
use Tarjans_Off_Line_Lowest_Common_Ancestors;

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
   function Pos (X : Positive) return Positive is (X);

   function Clear_Raises
     (Vertex_Count : Natural; Root : Vertex_Id) return Boolean
   is
      T : Tree;
   begin
      Clear (T, Vertex_Count, Root);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Set_Parent_Raises
     (T : in out Tree; Child, Parent : Vertex_Id) return Boolean
   is
   begin
      Set_Parent (T, Child, Parent);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Parent_Raises;

   function Add_Child_Raises
     (T : in out Tree; Parent, Child : Vertex_Id) return Boolean
   is
   begin
      Add_Child (T, Parent, Child);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Child_Raises;

   function Add_Query_Raises
     (T : in out Tree; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Query (T, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Query_Raises;

   function Compute_Raises (T : in out Tree) return Boolean is
   begin
      Compute (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Compute_Raises;

   function Answer_Raises
     (T : Tree; Query_Index : Positive) return Boolean
   is
      A : Vertex_Id;
   begin
      A := Answer (T, Query_Index);
      pragma Unreferenced (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Answer_Raises;

   function Naive_Raises
     (T : Tree; U, V : Vertex_Id) return Boolean
   is
      A : Vertex_Id;
   begin
      A := Naive_LCA (T, U, V);
      pragma Unreferenced (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Naive_Raises;

   function Root_Raises (T : Tree) return Boolean is
      R : Vertex_Id;
   begin
      R := Root (T);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Root_Raises;

   function Parent_Raises (T : Tree; V : Vertex_Id) return Boolean is
      P : Natural;
   begin
      P := Parent_Of (T, V);
      pragma Unreferenced (P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Parent_Raises;

   T : Tree;

   procedure Agree_Pair
     (Label : String; QIdx : Positive; U, V, Expect : Vertex_Id)
   is
      A, N : Vertex_Id;
   begin
      A := Answer (T, QIdx);
      N := Naive_LCA (T, U, V);
      Check (A = Expect, Label & " tarjan");
      Check (N = Expect, Label & " naive");
      Check (A = N, Label & " agree");
   end Agree_Pair;

   procedure Build_Line (N : Positive; Root_At : Vertex_Id := 1) is
   begin
      Clear (T, N, Root_At);
      if Root_At = 1 then
         for I in 2 .. N loop
            Add_Child (T, Vertex_Id (I - 1), Vertex_Id (I));
         end loop;
      else
         --  Root in the middle: parents point toward Root_At along the line
         for I in reverse 1 .. Natural (Root_At) - 1 loop
            Add_Child (T, Vertex_Id (I + 1), Vertex_Id (I));
         end loop;
         for I in Natural (Root_At) + 1 .. N loop
            Add_Child (T, Vertex_Id (I - 1), Vertex_Id (I));
         end loop;
      end if;
   end Build_Line;

   procedure Build_Binary (N : Positive) is
      --  Parent of k is k/2 for k = 2 .. N; root = 1
   begin
      Clear (T, N, 1);
      for I in 2 .. N loop
         Add_Child (T, Vertex_Id (I / 2), Vertex_Id (I));
      end loop;
   end Build_Binary;

   procedure Build_Star (N : Positive) is
   begin
      Clear (T, N, 1);
      for I in 2 .. N loop
         Add_Child (T, 1, Vertex_Id (I));
      end loop;
   end Build_Star;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single");
   ------------------------------------------------------------------
   Clear (T, 0);
   Check (Vertex_Count (T) = 0, "empty vertex count");
   Check (Query_Count (T) = 0, "empty query count");
   Check (not Computed (T), "empty not computed");
   Check (Root_Raises (T), "empty Root raises");
   Compute (T);
   Check (Computed (T), "empty Compute ok");
   Check (Answer_Raises (T, 1), "empty Answer raises");

   Clear (T, 1, 1);
   Check (Vertex_Count (T) = 1, "single vertex count");
   Check (Root (T) = 1, "single root");
   Check (Parent_Of (T, 1) = 0, "single parent 0");
   Add_Query (T, 1, 1);
   Check (Query_Count (T) = 1, "single one query");
   Compute (T);
   Check (Answer (T, 1) = 1, "single LCA(1,1)=1");
   Check (Naive_LCA (T, 1, 1) = 1, "single naive LCA");

   ------------------------------------------------------------------
   Section ("2. Two-vertex tree");
   ------------------------------------------------------------------
   Clear (T, 2, 1);
   Add_Child (T, 1, 2);
   Check (Parent_Of (T, 2) = 1, "two parent of 2");
   Check (Parent_Of (T, 1) = 0, "two parent of 1");
   Add_Query (T, 1, 2);
   Add_Query (T, 2, 1);
   Add_Query (T, 2, 2);
   Compute (T);
   Agree_Pair ("two 1-2", 1, 1, 2, 1);
   Agree_Pair ("two 2-1", 2, 2, 1, 1);
   Agree_Pair ("two 2-2", 3, 2, 2, 2);

   Clear (T, 2, 2);
   Set_Parent (T, 1, 2);
   Add_Query (T, 1, 2);
   Compute (T);
   Agree_Pair ("root2", 1, 1, 2, 2);

   ------------------------------------------------------------------
   Section ("3. Small branching tree");
   ------------------------------------------------------------------
   --        1
   --       / \
   --      2   3
   --     / \
   --    4   5
   Clear (T, 5, 1);
   Add_Child (T, 1, 2);
   Add_Child (T, 1, 3);
   Add_Child (T, 2, 4);
   Add_Child (T, 2, 5);
   Add_Query (T, 4, 5);
   Add_Query (T, 4, 3);
   Add_Query (T, 4, 2);
   Add_Query (T, 4, 1);
   Add_Query (T, 5, 3);
   Add_Query (T, 2, 3);
   Add_Query (T, 1, 1);
   Add_Query (T, 3, 3);
   Compute (T);
   Agree_Pair ("branch 4-5", 1, 4, 5, 2);
   Agree_Pair ("branch 4-3", 2, 4, 3, 1);
   Agree_Pair ("branch 4-2", 3, 4, 2, 2);
   Agree_Pair ("branch 4-1", 4, 4, 1, 1);
   Agree_Pair ("branch 5-3", 5, 5, 3, 1);
   Agree_Pair ("branch 2-3", 6, 2, 3, 1);
   Agree_Pair ("branch 1-1", 7, 1, 1, 1);
   Agree_Pair ("branch 3-3", 8, 3, 3, 3);

   ------------------------------------------------------------------
   Section ("4. Line trees");
   ------------------------------------------------------------------
   Build_Line (8);
   for I in 1 .. 8 loop
      for J in I .. 8 loop
         Add_Query (T, Vertex_Id (I), Vertex_Id (J));
      end loop;
   end loop;
   Compute (T);
   declare
      Idx : Positive := 1;
      Exp : Vertex_Id;
   begin
      for I in 1 .. 8 loop
         for J in I .. 8 loop
            Exp := Vertex_Id (I);  -- on a line rooted at 1, LCA(i,j)=min
            Agree_Pair
              ("line8 " & I'Image & "-" & J'Image,
               Idx, Vertex_Id (I), Vertex_Id (J), Exp);
            Idx := Idx + 1;
         end loop;
      end loop;
   end;

   Build_Line (10, 5);
   --  Line 1-2-...-10 rooted at 5: parents point toward 5
   Add_Query (T, 1, 10);
   Add_Query (T, 3, 4);
   Add_Query (T, 6, 9);
   Add_Query (T, 5, 5);
   Add_Query (T, 1, 5);
   Compute (T);
   Agree_Pair ("midline 1-10", 1, 1, 10, 5);
   Agree_Pair ("midline 3-4", 2, 3, 4, 4);
   Agree_Pair ("midline 6-9", 3, 6, 9, 6);
   Agree_Pair ("midline 5-5", 4, 5, 5, 5);
   Agree_Pair ("midline 1-5", 5, 1, 5, 5);

   ------------------------------------------------------------------
   Section ("5. Binary heap-shaped trees");
   ------------------------------------------------------------------
   Build_Binary (15);
   Add_Query (T, 8, 9);    -- LCA = 4
   Add_Query (T, 8, 10);   -- LCA = 2
   Add_Query (T, 8, 15);   -- LCA = 1
   Add_Query (T, 14, 15);  -- LCA = 7
   Add_Query (T, 11, 10);  -- LCA = 1? 11 under 5, 10 under 5? 10=2*5, 11=2*5+1 under 5
   Add_Query (T, 4, 6);    -- LCA = 1? 4 under 2, 6 under 3 → 1
   Add_Query (T, 4, 5);    -- LCA = 2
   Add_Query (T, 12, 13);  -- under 6 → 6
   Compute (T);
   Agree_Pair ("bin 8-9", 1, 8, 9, 4);
   Agree_Pair ("bin 8-10", 2, 8, 10, 2);
   Agree_Pair ("bin 8-15", 3, 8, 15, 1);
   Agree_Pair ("bin 14-15", 4, 14, 15, 7);
   Agree_Pair ("bin 11-10", 5, 11, 10, 5);
   Agree_Pair ("bin 4-6", 6, 4, 6, 1);
   Agree_Pair ("bin 4-5", 7, 4, 5, 2);
   Agree_Pair ("bin 12-13", 8, 12, 13, 6);

   ------------------------------------------------------------------
   Section ("6. Star trees");
   ------------------------------------------------------------------
   Build_Star (12);
   Add_Query (T, 2, 3);
   Add_Query (T, 7, 12);
   Add_Query (T, 1, 8);
   Add_Query (T, 4, 4);
   Compute (T);
   Agree_Pair ("star 2-3", 1, 2, 3, 1);
   Agree_Pair ("star 7-12", 2, 7, 12, 1);
   Agree_Pair ("star 1-8", 3, 1, 8, 1);
   Agree_Pair ("star 4-4", 4, 4, 4, 4);

   ------------------------------------------------------------------
   Section ("7. Set_Parent vs Add_Child");
   ------------------------------------------------------------------
   Clear (T, 4, 1);
   Set_Parent (T, 2, 1);
   Set_Parent (T, 3, 1);
   Add_Child (T, 2, 4);
   Check (Parent_Of (T, 2) = 1, "sp parent 2");
   Check (Parent_Of (T, 3) = 1, "sp parent 3");
   Check (Parent_Of (T, 4) = 2, "sp parent 4");
   Add_Query (T, 4, 3);
   Compute (T);
   Agree_Pair ("sp 4-3", 1, 4, 3, 1);

   ------------------------------------------------------------------
   Section ("8. Clear / rebuild / Computed flag");
   ------------------------------------------------------------------
   Clear (T, 3, 1);
   Add_Child (T, 1, 2);
   Add_Child (T, 1, 3);
   Add_Query (T, 2, 3);
   Check (not Computed (T), "before compute");
   Compute (T);
   Check (Computed (T), "after compute");
   Check (Answer (T, 1) = 1, "rebuild LCA");
   Add_Query (T, 2, 2);
   Check (not Computed (T), "Add_Query invalidates");
   Check (Answer_Raises (T, 1), "Answer raises after invalidate");
   Compute (T);
   Check (Answer (T, 1) = 1, "recompute q1");
   Check (Answer (T, 2) = 2, "recompute q2");

   Clear (T, 3, 1);
   Check (not Computed (T), "Clear invalidates");
   Check (Query_Count (T) = 0, "Clear drops queries");

   ------------------------------------------------------------------
   Section ("9. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices) + 1, 1), "Clear N overflow");
   Check (Clear_Raises (5, 6), "Clear Root out of range");
   Check (not Clear_Raises (5, 5), "Clear Root = N ok");
   Check (not Clear_Raises (0, 1), "Clear empty ok");

   Clear (T, 3, 1);
   Check (Set_Parent_Raises (T, 1, 2), "Set_Parent root as child");
   Check (Set_Parent_Raises (T, 2, 2), "Set_Parent self");
   Check (Set_Parent_Raises (T, 4, 1), "Set_Parent child OOR");
   Check (Set_Parent_Raises (T, 2, 4), "Set_Parent parent OOR");
   Add_Child (T, 1, 2);
   Check (Set_Parent_Raises (T, 2, 1), "Set_Parent duplicate");
   Check (Add_Child_Raises (T, 1, 2), "Add_Child duplicate");
   Check (Add_Query_Raises (T, 1, 4), "Add_Query OOR");
   Check (Add_Query_Raises (T, 4, 1), "Add_Query OOR 2");
   Check (Parent_Raises (T, 4), "Parent_Of OOR");
   Check (Naive_Raises (T, 1, 4), "Naive OOR");

   Clear (T, 0);
   Check (Add_Query_Raises (T, 1, 1), "Add_Query on empty");
   Check (Naive_Raises (T, 1, 1), "Naive on empty");

   -- Incomplete tree
   Clear (T, 4, 1);
   Add_Child (T, 1, 2);
   Add_Child (T, 1, 3);
   -- vertex 4 missing parent
   Add_Query (T, 2, 3);
   Check (Compute_Raises (T), "incomplete tree Compute");

   -- Cycle / disconnected: 2->3, 3->2 style cannot with Set_Parent once;
   -- build 1-2 and 3-4 as separate (3 parent unset from root)
   Clear (T, 4, 1);
   Add_Child (T, 1, 2);
   Add_Child (T, 3, 4);  -- 3 has no parent; Edge_Count=2 /= 3
   Check (Compute_Raises (T), "disconnected Compute");

   Clear (T, 2, 1);
   Add_Child (T, 1, 2);
   Add_Query (T, 1, 2);
   Check (Answer_Raises (T, 1), "Answer before Compute");
   Compute (T);
   Check (Answer_Raises (T, 2), "Answer index OOR");
   Check (Answer_Raises (T, Pos (100)), "Answer large OOR");

   ------------------------------------------------------------------
   Section ("10. Query capacity near Max_Queries (small tree)");
   ------------------------------------------------------------------
   Build_Star (5);
   for I in 1 .. 50 loop
      Add_Query (T, 2, 3);
      Add_Query (T, 3, 4);
      Add_Query (T, 4, 5);
      Add_Query (T, 2, 5);
      Add_Query (T, 1, 5);
   end loop;
   Check (Query_Count (T) = 250, "250 queries");
   Compute (T);
   Check (Answer (T, 1) = 1, "bulk q1");
   Check (Answer (T, 2) = 1, "bulk q2");
   Check (Answer (T, 5) = 1, "bulk q5");
   Check (Answer (T, 250) = 1, "bulk q250");
   Check (Naive_LCA (T, 2, 5) = 1, "bulk naive");

   ------------------------------------------------------------------
   Section ("11. Larger line vs naive");
   ------------------------------------------------------------------
   Build_Line (64);
   declare
      Idx : Natural := 0;
   begin
      for I in 1 .. 64 loop
         if I mod 7 = 0 then
            for J in I .. 64 loop
               if J mod 5 = 0 or else J = I then
                  Add_Query (T, Vertex_Id (I), Vertex_Id (J));
                  Idx := Idx + 1;
               end if;
            end loop;
         end if;
      end loop;
      Compute (T);
      declare
         K : Positive := 1;
      begin
         for I in 1 .. 64 loop
            if I mod 7 = 0 then
               for J in I .. 64 loop
                  if J mod 5 = 0 or else J = I then
                     Agree_Pair
                       ("L64", K, Vertex_Id (I), Vertex_Id (J), Vertex_Id (I));
                     K := K + 1;
                  end if;
               end loop;
            end if;
         end loop;
      end;
   end;

   ------------------------------------------------------------------
   Section ("12. Larger binary vs naive");
   ------------------------------------------------------------------
   Build_Binary (31);
   declare
      Pairs : constant array (1 .. 12, 1 .. 2) of Vertex_Id :=
        [[1, 1], [2, 3], [4, 5], [8, 9], [16, 17], [16, 31],
         [15, 14], [7, 3], [10, 11], [20, 21], [6, 7], [31, 1]];
   begin
      for I in 1 .. 12 loop
         Add_Query (T, Pairs (I, 1), Pairs (I, 2));
      end loop;
      Compute (T);
      for I in 1 .. 12 loop
         declare
            U : constant Vertex_Id := Pairs (I, 1);
            V : constant Vertex_Id := Pairs (I, 2);
            N : constant Vertex_Id := Naive_LCA (T, U, V);
         begin
            Check (Answer (T, I) = N,
                   "bin31 agree " & U'Image & "-" & V'Image);
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("13. Deepish line (stack-safe iterative DFS)");
   ------------------------------------------------------------------
   Build_Line (200);
   Add_Query (T, 1, 200);
   Add_Query (T, 50, 150);
   Add_Query (T, 199, 200);
   Add_Query (T, 100, 100);
   Compute (T);
   Agree_Pair ("deep 1-200", 1, 1, 200, 1);
   Agree_Pair ("deep 50-150", 2, 50, 150, 50);
   Agree_Pair ("deep 199-200", 3, 199, 200, 199);
   Agree_Pair ("deep 100-100", 4, 100, 100, 100);

   ------------------------------------------------------------------
   Section ("14. API counters / Root variants");
   ------------------------------------------------------------------
   Clear (T, 6, 3);
   Check (Root (T) = 3, "root is 3");
   Check (Vertex_Count (T) = 6, "n=6");
   Add_Child (T, 3, 1);
   Add_Child (T, 3, 2);
   Add_Child (T, 3, 4);
   Add_Child (T, 4, 5);
   Add_Child (T, 4, 6);
   Check (Parent_Of (T, 1) = 3, "p1");
   Check (Parent_Of (T, 5) = 4, "p5");
   Add_Query (T, 1, 2);
   Add_Query (T, 5, 6);
   Add_Query (T, 1, 6);
   Add_Query (T, 5, 2);
   Compute (T);
   Agree_Pair ("r3 1-2", 1, 1, 2, 3);
   Agree_Pair ("r3 5-6", 2, 5, 6, 4);
   Agree_Pair ("r3 1-6", 3, 1, 6, 3);
   Agree_Pair ("r3 5-2", 4, 5, 2, 3);

   ------------------------------------------------------------------
   Section ("15. Many self-queries");
   ------------------------------------------------------------------
   Build_Binary (16);
   for I in 1 .. 16 loop
      Add_Query (T, Vertex_Id (I), Vertex_Id (I));
   end loop;
   Compute (T);
   for I in 1 .. 16 loop
      Check (Answer (T, I) = Vertex_Id (I),
             "self " & I'Image);
      Check (Naive_LCA (T, Vertex_Id (I), Vertex_Id (I)) = Vertex_Id (I),
             "self naive " & I'Image);
   end loop;

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
