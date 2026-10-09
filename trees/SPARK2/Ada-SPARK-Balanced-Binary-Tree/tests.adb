pragma Ada_2022;
with Ada.Assertions;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Balanced_Binary_Tree; use Balanced_Binary_Tree;
procedure Tests is
   --  Own tests (tests/SOURCES.txt): a tree is balanced when at every node the heights of the two
   --  subtrees differ by at most 1. Reference: own recursive height computation below.
   T : Tree := Empty;
   U : Tree := Empty;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (4242);
   function Next (Bound : Natural) return Natural is
   begin
      Seed := (Seed * 48271) mod 2147483647;   --  Park-Miller
      return Natural (Seed mod Long_Long_Integer (Bound + 1));
   end Next;
   Unbalanced : constant Integer := -1;
   function Ref_Height (T : Tree; N : Index) return Integer is   --  -1 = some subtree unbalanced
   begin
      if N = 0 then
         return 0;
      end if;
      declare
         L : constant Integer := Ref_Height (T, Left_Child (T, N));
         R : constant Integer := Ref_Height (T, Right_Child (T, N));
      begin
         if L = Unbalanced or else R = Unbalanced or else abs (L - R) > 1 then
            return Unbalanced;
         end if;
         return 1 + Integer'Max (L, R);
      end;
   end Ref_Height;
   procedure Expect (T : Tree; Root : Index; B : Boolean; What : String) is
   begin
      if Is_Balanced (T, Root) /= B then
         Put_Line ("FAIL " & What);
         raise Program_Error;
      end if;
   end Expect;
   Cases, Balanced_Seen : Natural := 0;
   --  Own tree reference for arbitrary link structures: depth-first walk from Root with a visited set.
   --  A node reached a second time (two links into it, or a cycle) means the links are not a tree.
   function Ref_Is_Tree (T : Tree; Root : Index) return Boolean is
      Seen : array (Node_Index) of Boolean := [others => False];
      function Visit (N : Index) return Boolean is
      begin
         if N = 0 then
            return True;
         elsif Seen (N) then
            return False;
         end if;
         Seen (N) := True;
         return Visit (Left_Child (T, N)) and then Visit (Right_Child (T, N));
      end Visit;
   begin
      return Root = 0 or else not Used (T, Root) or else Visit (Root);
   end Ref_Is_Tree;
   Shared_Rejected, Built, Exhaustive : Natural := 0;
begin
   Set_Node (T, 1, 1, 2, 3); Set_Node (T, 2, 2, 4, 0); Set_Node (T, 3, 3, 0, 0); Set_Node (T, 4, 4, 0, 0);
   Expect (T, 1, True, "original balanced case");
   Set_Node (U, 1, 1, 2, 4); Set_Node (U, 2, 2, 3, 0); Set_Node (U, 3, 3, 5, 0); Set_Node (U, 4, 4, 0, 0);
   Set_Node (U, 5, 5, 0, 0);
   Expect (U, 1, False, "original unbalanced case");
   --  hand cases
   U := Empty;
   Set_Node (U, 1, 1, 2, 0); Set_Node (U, 2, 2, 3, 0); Set_Node (U, 3, 3, 0, 0);
   Expect (U, 1, False, "chain of 3 (one leaf, root heights 2 / 0)");
   U := Empty;
   Set_Node (U, 1, 1, 2, 0); Set_Node (U, 2, 2, 0, 0);
   Expect (U, 1, True, "chain of 2");
   Expect (Empty, 0, True, "empty tree");
   U := Empty;
   Set_Node (U, 1, 1, 1, 0);
   Expect (U, 1, False, "cycle: node 1 is its own left child");
   --  Shared children are not a tree: Set_Node must refuse a link into a node that already has a parent
   --  (or Left = Right), so such a structure cannot be built and judged.
   U := Empty;
   begin
      Set_Node (U, 1, 1, 2, 2);
      Set_Node (U, 2, 2, 0, 0);
      Put_Line ("FAIL shared children (links 2 / 2) accepted; Is_Balanced =" & Is_Balanced (U, 1)'Image);
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error => Shared_Rejected := Shared_Rejected + 1;
   end;
   U := Empty;
   Set_Node (U, 1, 1, 2, 3); Set_Node (U, 2, 2, 4, 0);
   begin
      Set_Node (U, 3, 3, 4, 0);   --  node 4 would get a second parent
      Put_Line ("FAIL node 4 shared by nodes 2 and 3 accepted; Is_Balanced =" & Is_Balanced (U, 1)'Image);
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error => Shared_Rejected := Shared_Rejected + 1;
   end;
   --  Every left / right link assignment on 1 .. 4 nodes (0 = no child), built node by node with
   --  Set_Node: it must be refused exactly when some node would get two links into it; a built
   --  structure is judged balanced exactly when it is a tree (own visited-set walk) and the own
   --  height reference says balanced.
   for N in 1 .. 4 loop
      declare
         Links : array (1 .. 8) of Index := [others => 0];
         Total : constant Natural := (N + 1) ** (2 * N);
      begin
         for Code in 0 .. Total - 1 loop
            declare
               C : Natural := Code;
               In_Links : array (Node_Index) of Natural := [others => 0];
               W : Tree := Empty;
               Refused : Boolean := False;
            begin
               for K in 1 .. 2 * N loop
                  Links (K) := C mod (N + 1); C := C / (N + 1);
                  if Links (K) /= 0 then
                     In_Links (Links (K)) := In_Links (Links (K)) + 1;
                  end if;
               end loop;
               begin
                  for K in 1 .. N loop
                     Set_Node (W, K, K, Links (2 * K - 1), Links (2 * K));
                  end loop;
               exception
                  when Ada.Assertions.Assertion_Error => Refused := True;
               end;
               if Refused /= (for some M in Node_Index => In_Links (M) > 1) then
                  Put_Line ("FAIL exhaustive n =" & N'Image & " code =" & Code'Image
                            & " refused =" & Refused'Image);
                  raise Program_Error;
               end if;
               if not Refused then
                  Built := Built + 1;
                  Expect (W, 1, Ref_Is_Tree (W, 1) and then Ref_Height (W, 1) /= Unbalanced,
                          "exhaustive n =" & N'Image & " code =" & Code'Image);
               end if;
               Exhaustive := Exhaustive + 1;
            end;
         end loop;
      end;
   end loop;
   Put_Line ("shared children: PASS (2 hand cases refused;" & Exhaustive'Image & " link assignments on 1 .. 4 nodes,"
             & Built'Image & " buildable and judged)");
   --  random trees: node K > 1 hangs under a random earlier node with a free slot
   for C in 1 .. 20_000 loop
      declare
         N : constant Node_Index := 1 + Next (30);
         V : Tree := Empty;
         L, R : array (Node_Index) of Index := [others => 0];
      begin
         for K in 2 .. N loop
            loop
               declare
                  P : constant Node_Index := 1 + Next (K - 2);
               begin
                  if Next (1) = 0 and then L (P) = 0 then
                     L (P) := K; exit;
                  elsif R (P) = 0 then
                     R (P) := K; exit;
                  end if;
               end;
            end loop;
         end loop;
         for K in 1 .. N loop
            Set_Node (V, K, K, L (K), R (K));
         end loop;
         Expect (V, 1, Ref_Height (V, 1) /= Unbalanced, "random case" & C'Image);
         if Ref_Height (V, 1) /= Unbalanced then
            Balanced_Seen := Balanced_Seen + 1;
         end if;
         Cases := Cases + 1;
      end;
   end loop;
   Put_Line ("balanced tree: PASS (" & Natural'Image (Cases + 6) & " cases," & Balanced_Seen'Image
             & " random balanced; own recursive height reference)");
end Tests;
