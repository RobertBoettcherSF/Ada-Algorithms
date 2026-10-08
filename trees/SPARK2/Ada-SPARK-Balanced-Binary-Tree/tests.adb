pragma Ada_2022;
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
