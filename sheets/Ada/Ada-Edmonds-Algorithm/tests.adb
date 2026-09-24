--  Standalone test suite for Edmonds_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Edmonds_Algorithm; use Edmonds_Algorithm;

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

   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; From, To : Vertex_Id; W : Integer) return Boolean
   is
   begin
      Add_Edge (G, From, To, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Arb_Raises_Invalid
     (G : Graph; Root : Vertex_Id; Buf_Last : Natural) return Boolean
   is
      Tree : Edge_List (1 .. Positive'Max (1, Buf_Last));
      C    : Natural;
      W    : Weight_Sum;
      St   : Run_Status;
   begin
      if Buf_Last = 0 then
         declare
            Empty_Buf : Edge_List (1 .. 0);
         begin
            Minimum_Arborescence (G, Root, Empty_Buf, C, W, St);
         end;
      else
         Minimum_Arborescence (G, Root, Tree (1 .. Buf_Last), C, W, St);
      end if;
      pragma Unreferenced (C, W, St);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Arb_Raises_Invalid;

   function Arb_Raises_Bad_First (G : Graph; Root : Vertex_Id) return Boolean is
      Tree : Edge_List (2 .. Max_Vertices + 1);
      C    : Natural;
      W    : Weight_Sum;
      St   : Run_Status;
   begin
      Minimum_Arborescence (G, Root, Tree, C, W, St);
      pragma Unreferenced (C, W, St);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Arb_Raises_Bad_First;

   function Raising_Impossible (G : Graph; Root : Vertex_Id) return Boolean is
      Tree : Edge_List (1 .. Max_Vertices);
      C    : Natural;
      W    : Weight_Sum;
   begin
      Minimum_Arborescence (G, Root, Tree, C, W);
      pragma Unreferenced (C, W);
      return False;
   exception
      when Impossible_Arborescence =>
         return True;
   end Raising_Impossible;

   function Edge_In_Tree
     (Tree : Edge_List; Count : Natural;
      A, B : Vertex_Id; Wt : Weight_Type) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Tree (I).From = A and then Tree (I).To = B
           and then Tree (I).Weight = Wt
         then
            return True;
         end if;
      end loop;
      return False;
   end Edge_In_Tree;

   function Is_Arborescence
     (G : Graph; Root : Vertex_Id; Tree : Edge_List; Count : Natural)
      return Boolean
   is
      N : constant Natural := Vertex_Count (G);
      R : constant Natural := Natural (Root);
      Indeg : array (1 .. Max_Vertices) of Natural := [others => 0];
      Par   : array (1 .. Max_Vertices) of Natural := [others => 0];
   begin
      if N = 0 then
         return False;
      end if;
      if Count /= N - 1 then
         return False;
      end if;
      for I in 1 .. Count loop
         declare
            U : constant Natural := Natural (Tree (I).From);
            V : constant Natural := Natural (Tree (I).To);
         begin
            if U < 1 or else U > N or else V < 1 or else V > N then
               return False;
            end if;
            if V = R then
               return False;
            end if;
            Indeg (V) := Indeg (V) + 1;
            Par (V) := U;
         end;
      end loop;
      if Indeg (R) /= 0 then
         return False;
      end if;
      for V in 1 .. N loop
         if V /= R and then Indeg (V) /= 1 then
            return False;
         end if;
      end loop;
      for V in 1 .. N loop
         if V /= R then
            declare
               Seen : array (1 .. Max_Vertices) of Boolean := [others => False];
               U : Natural := V;
               Steps : Natural := 0;
            begin
               while U /= R loop
                  if Seen (U) or else Par (U) = 0 then
                     return False;
                  end if;
                  Seen (U) := True;
                  U := Par (U);
                  Steps := Steps + 1;
                  if Steps > N then
                     return False;
                  end if;
               end loop;
            end;
         end if;
      end loop;
      return True;
   end Is_Arborescence;

   procedure Agree_With_Brute (G : Graph; Root : Vertex_Id; Label : String) is
      Tree, Tree_B : Edge_List (1 .. Max_Vertices);
      C, CB : Natural;
      W, WB : Weight_Sum;
      St, StB : Run_Status;
   begin
      if Vertex_Count (G) > Brute_Max_Vertices then
         return;
      end if;
      Minimum_Arborescence (G, Root, Tree, C, W, St);
      Brute_Minimum_Arborescence (G, Root, Tree_B, CB, WB, StB);
      Check (St = StB, Label & " status agree");
      if St = Success then
         Check (C = CB, Label & " count agree");
         Check (W = WB, Label & " weight agree");
         Check (Is_Arborescence (G, Root, Tree, C), Label & " is arb");
      else
         Check (C = 0 and then W = 0, Label & " impossible cleared");
      end if;
   end Agree_With_Brute;

   G, G2 : Graph;
   Tree  : Edge_List (1 .. Max_Vertices);
   C     : Natural;
   W     : Weight_Sum;
   St    : Run_Status;

begin
   ------------------------------------------------------------------
   Section ("1. Single vertex / trivial");
   ------------------------------------------------------------------
   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single N=1");
   Check (Edge_Count (G) = 0, "single M=0");
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "single Success");
   Check (C = 0 and then W = 0, "single empty arb");
   Edmonds (G, 1, Tree, C, W, St);
   Check (St = Success and then C = 0, "alias Edmonds single");
   Agree_With_Brute (G, 1, "single");

   ------------------------------------------------------------------
   Section ("2. Two vertices");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 7);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "two-vert Success");
   Check (C = 1 and then W = 7, "two-vert weight 7");
   Check (Edge_In_Tree (Tree, C, 1, 2, 7), "two-vert edge");
   Check (Is_Arborescence (G, 1, Tree, C), "two-vert arb");
   Agree_With_Brute (G, 1, "two-vert");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 0);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = 0, "zero-weight");
   Agree_With_Brute (G, 1, "zero-wt");

   Clear (G, 2);
   Add_Edge (G, 2, 1, 5);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Impossible, "two-vert wrong direction Impossible");
   Check (Raising_Impossible (G, 1), "two-vert raises Impossible");

   ------------------------------------------------------------------
   Section ("3. Star from root");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 1, 4, 3);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "star Success");
   Check (C = 3 and then W = 6, "star total 6");
   Check (Is_Arborescence (G, 1, Tree, C), "star arb");
   Agree_With_Brute (G, 1, "star");

   ------------------------------------------------------------------
   Section ("4. Cycle contraction textbook");
   ------------------------------------------------------------------
   --  Root=1; edges force a 2-cycle between 2 and 3 then expand.
   --  Expected min weight 9: (1,2):3 + (2,3):2 + (3,4):4
   Clear (G, 4);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 10);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 4);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "contract Success");
   Check (C = 3, "contract count 3");
   Check (W = 9, "contract weight 9");
   Check (Is_Arborescence (G, 1, Tree, C), "contract arb");
   Agree_With_Brute (G, 1, "contract");

   ------------------------------------------------------------------
   Section ("5. Negative weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, -5);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 1, 3, 10);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "neg Success");
   Check (W = -4, "neg total -4");
   Check (Is_Arborescence (G, 1, Tree, C), "neg arb");
   Agree_With_Brute (G, 1, "neg");

   Clear (G, 3);
   Add_Edge (G, 1, 2, -10);
   Add_Edge (G, 1, 3, -3);
   Add_Edge (G, 2, 3, 100);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = -13, "all-neg prefers root outs");
   Agree_With_Brute (G, 1, "all-neg");

   ------------------------------------------------------------------
   Section ("6. Impossible graphs");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   --  vertex 3 has no incoming
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Impossible, "missing in Impossible");
   Check (C = 0 and then W = 0, "missing cleared");
   Check (Raising_Impossible (G, 1), "missing raises");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 2, 1);
   --  4 unreachable
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Impossible, "unreachable-4 Impossible");
   Agree_With_Brute (G, 1, "unreachable-4");

   Clear (G, 3);
   --  edgeless multi-vertex: Impossible for root 1
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Impossible, "edgeless Impossible");

   ------------------------------------------------------------------
   Section ("7. Self-loops ignored");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 1, 9);
   Add_Edge (G, 2, 2, 8);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 4);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = 7, "self-loop ignored weight");
   Check (not Edge_In_Tree (Tree, C, 1, 1, 9), "no self-loop in tree");
   Agree_With_Brute (G, 1, "self-loop");

   ------------------------------------------------------------------
   Section ("8. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 9);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, 1);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "parallel Success");
   Check (W = 3, "parallel prefers cheap 1->2 and 2->3");
   Agree_With_Brute (G, 1, "parallel");

   ------------------------------------------------------------------
   Section ("9. Path / chain");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then C = 4 and then W = 4, "path weight 4");
   Check (Is_Arborescence (G, 1, Tree, C), "path arb");
   Agree_With_Brute (G, 1, "path");

   ------------------------------------------------------------------
   Section ("10. Alternate root");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 1);
   Minimum_Arborescence (G, 2, Tree, C, W, St);
   Check (St = Success and then W = 2, "root2 weight 2");
   Check (Is_Arborescence (G, 2, Tree, C), "root2 arb");
   Agree_With_Brute (G, 2, "root2");
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = 2, "root1 weight 2");
   Agree_With_Brute (G, 1, "root1");

   ------------------------------------------------------------------
   Section ("11. Complete digraph K3 tournament");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 2, 3);
   Add_Edge (G, 2, 1, 9);
   Add_Edge (G, 3, 1, 8);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = 3, "K3 weight 3");
   Agree_With_Brute (G, 1, "K3");

   ------------------------------------------------------------------
   Section ("12. Deeper nested contraction");
   ------------------------------------------------------------------
   --  Two interlocking cycles needing successive contractions
   Clear (G, 5);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 10);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 4, 2, 1);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 5, 3, 1);
   Add_Edge (G, 4, 5, 5);
   Add_Edge (G, 5, 4, 5);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "nested Success");
   Check (C = 4, "nested count 4");
   Check (Is_Arborescence (G, 1, Tree, C), "nested arb");
   Agree_With_Brute (G, 1, "nested");

   ------------------------------------------------------------------
   Section ("13. Edges into root discarded");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 2, 1, 0);  -- into root: ignored for selection
   Add_Edge (G, 3, 1, 0);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 5);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = 9, "into-root discarded");
   Check (not Edge_In_Tree (Tree, C, 2, 1, 0), "no edge into root");
   Agree_With_Brute (G, 1, "into-root");

   ------------------------------------------------------------------
   Section ("14. Clear / rebuild API counters");
   ------------------------------------------------------------------
   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "clear N=4");
   Check (Edge_Count (G) = 0, "clear M=0");
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 1);
   Check (Edge_Count (G) = 3, "after add M=3");
   Clear (G, 2);
   Check (Vertex_Count (G) = 2 and then Edge_Count (G) = 0, "rebuild empty");
   Add_Edge (G, 1, 2, 11);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then W = 11, "rebuild works");

   ------------------------------------------------------------------
   Section ("15. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Clear (G, 3);
   Check (Add_Raises (G, 1, 4, 1), "Add bad To");
   Check (Add_Raises (G, 4, 1, 1), "Add bad From");
   --  Weight outside Weight_Type
   Check (Add_Raises (G, 1, 2, Int (Integer'First)), "Add weight too small");
   Clear (G, 0);
   Check (Arb_Raises_Invalid (G, 1, 10), "N=0 search raises");
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Check (Arb_Raises_Invalid (G, 4, 10), "bad Root raises");
   Check (Arb_Raises_Invalid (G, 1, 1), "tiny buffer raises");  -- need 2
   Check (Arb_Raises_Bad_First (G, 1), "bad First raises");

   --  Empty graph Clear(0) ok
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty N=0");

   ------------------------------------------------------------------
   Section ("16. Raising overload success");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 3);
   declare
      Tw : Weight_Sum;
      Tc : Natural;
   begin
      Minimum_Arborescence (G, 1, Tree, Tc, Tw);
      Check (Tc = 1 and then Tw = 3, "raising success");
   end;

   ------------------------------------------------------------------
   Section ("17. Dense small random-like hand cases");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 1, 4, 5);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 2, 1);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "dense4 Success");
   Check (Is_Arborescence (G, 1, Tree, C), "dense4 arb");
   Agree_With_Brute (G, 1, "dense4");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 100);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 3, 1);
   Add_Edge (G, 1, 4, 100);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "dual-cycle Success");
   Check (C = 3, "dual-cycle count");
   Agree_With_Brute (G, 1, "dual-cycle");

   ------------------------------------------------------------------
   Section ("18. Larger path N=20");
   ------------------------------------------------------------------
   Clear (G, 20);
   for I in 1 .. 19 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then C = 19 and then W = 19, "path20");
   Check (Is_Arborescence (G, 1, Tree, C), "path20 arb");

   ------------------------------------------------------------------
   Section ("19. Star N=30");
   ------------------------------------------------------------------
   Clear (G, 30);
   for I in 2 .. 30 loop
      Add_Edge (G, 1, Vertex_Id (I), I);
   end loop;
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then C = 29, "star30 count");
   declare
      Expect : Weight_Sum := 0;
   begin
      for I in 2 .. 30 loop
         Expect := Expect + Weight_Sum (I);
      end loop;
      Check (W = Expect, "star30 weight");
   end;
   Check (Is_Arborescence (G, 1, Tree, C), "star30 arb");

   ------------------------------------------------------------------
   Section ("20. Brute agreement battery");
   ------------------------------------------------------------------
   --  Many small graphs
   for N in 2 .. 6 loop
      Clear (G, N);
      --  root outs + a reverse cycle among non-roots
      for I in 2 .. N loop
         Add_Edge (G, 1, Vertex_Id (I), 10 + I);
      end loop;
      for I in 2 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
      end loop;
      if N >= 3 then
         Add_Edge (G, Vertex_Id (N), 2, 1);
      end if;
      Agree_With_Brute (G, 1, "batt-N" & Integer'Image (N));
   end loop;

   for Seed in 1 .. 12 loop
      Clear (G, 5);
      --  deterministic pseudo edges
      for U in 1 .. 5 loop
         for V in 1 .. 5 loop
            if U /= V then
               declare
                  Wt : constant Integer :=
                    ((U * 17 + V * 13 + Seed * 7) mod 23) - 5;
               begin
                  Add_Edge (G, Vertex_Id (U), Vertex_Id (V), Wt);
               end;
            end if;
         end loop;
      end loop;
      Agree_With_Brute (G, Vertex_Id (1 + (Seed mod 5)),
                        "rand5-s" & Integer'Image (Seed));
   end loop;

   ------------------------------------------------------------------
   Section ("21. Alias Edmonds matches");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 1, 4, 2);
   declare
      C2 : Natural;
      W2 : Weight_Sum;
      St2 : Run_Status;
      Tree2 : Edge_List (1 .. Max_Vertices);
   begin
      Minimum_Arborescence (G, 1, Tree, C, W, St);
      Edmonds (G, 1, Tree2, C2, W2, St2);
      Check (St = St2 and then C = C2 and then W = W2, "alias match");
   end;

   ------------------------------------------------------------------
   Section ("22. G2 independent graph object");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Clear (G2, 2);
   Add_Edge (G2, 1, 2, 99);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (W = 2, "G independent");
   Minimum_Arborescence (G2, 1, Tree, C, W, St);
   Check (W = 99, "G2 independent");

   ------------------------------------------------------------------
   Section ("23. Prefer cheaper among ties via contraction");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 3, 2, 0);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "tie-cycle Success");
   --  Optimal: one root edge (5) + the 0-edge between 2 and 3 = 5
   Check (W = 5, "tie-cycle weight 5");
   Agree_With_Brute (G, 1, "tie-cycle");

   ------------------------------------------------------------------
   Section ("24. More impossible / boundary");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 2, 1);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Impossible, "no root outs Impossible");

   Clear (G, 1);
   Add_Edge (G, 1, 1, 5);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success and then C = 0, "single with self-loop");

   ------------------------------------------------------------------
   Section ("25. Weight extremes in range");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, Integer (Weight_Type'First));
   Add_Edge (G, 1, 3, Integer (Weight_Type'Last));
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "extremes Success");
   Check (W = Weight_Sum (Weight_Type'First) + Weight_Sum (Weight_Type'Last),
          "extremes sum");

   ------------------------------------------------------------------
   Section ("26. Extra hand graphs for PASS volume");
   ------------------------------------------------------------------
   for K in 1 .. 20 loop
      Clear (G, 4);
      Add_Edge (G, 1, 2, K);
      Add_Edge (G, 1, 3, K + 1);
      Add_Edge (G, 1, 4, K + 2);
      Add_Edge (G, 2, 3, 1);
      Add_Edge (G, 3, 4, 1);
      Minimum_Arborescence (G, 1, Tree, C, W, St);
      Check (St = Success and then Is_Arborescence (G, 1, Tree, C),
             "vol4-k" & Integer'Image (K));
      if K <= 8 then
         Agree_With_Brute (G, 1, "vol4b-k" & Integer'Image (K));
      end if;
   end loop;

   for K in 1 .. 15 loop
      Clear (G, 3);
      Add_Edge (G, 1, 2, K);
      Add_Edge (G, 2, 3, K);
      Add_Edge (G, 1, 3, 3 * K);
      Minimum_Arborescence (G, 1, Tree, C, W, St);
      Check (St = Success and then W = Weight_Sum (2 * K),
             "path3-k" & Integer'Image (K));
   end loop;

   ------------------------------------------------------------------
   Section ("27. Disconnected components aside from root tree");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 6, 4, 1);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Impossible, "side component Impossible");

   --  Connect side via one bridge
   Add_Edge (G, 3, 4, 2);
   Minimum_Arborescence (G, 1, Tree, C, W, St);
   Check (St = Success, "bridge Success");
   Check (C = 5, "bridge count 5");
   Check (Is_Arborescence (G, 1, Tree, C), "bridge arb");
   Agree_With_Brute (G, 1, "bridge");

   ------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
