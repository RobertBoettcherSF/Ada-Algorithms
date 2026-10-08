pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Range_Sum_BST; use Range_Sum_BST;
procedure Tests is
   --  Own tests (tests/SOURCES.txt): Range_Sum (T, Root, Low, High) = sum of the values in Low .. High
   --  over all nodes of the binary search tree at Root. Reference: own full traversal (no pruning).
   T : Tree := Empty;
   Seed : Long_Long_Integer := 99_001;
   function Next (Bound : Natural) return Natural is
   begin
      Seed := (Seed * 48271) mod 2147483647;   --  Park-Miller
      return Natural (Seed mod Long_Long_Integer (Bound + 1));
   end Next;
   function Ref_Sum (T : Tree; N : Index; Low, High : Value) return Integer is
   begin
      if N = 0 then
         return 0;
      end if;
      return (if Node_Value (T, N) in Low .. High then Node_Value (T, N) else 0)
        + Ref_Sum (T, Left_Child (T, N), Low, High) + Ref_Sum (T, Right_Child (T, N), Low, High);
   end Ref_Sum;
   procedure Expect (T : Tree; Root : Index; Low, High : Value; S : Integer; What : String) is
   begin
      if Range_Sum (T, Root, Low, High) /= S then
         Put_Line ("FAIL " & What & ": got" & Range_Sum (T, Root, Low, High)'Image & ", expected" & S'Image);
         raise Program_Error;
      end if;
   end Expect;
   Cases : Natural := 0;
begin
   Set_Node (T, 1, 8, 2, 3); Set_Node (T, 2, 3, 0, 0); Set_Node (T, 3, 10, 0, 0);
   Expect (T, 1, 4, 9, 8, "original case");
   --  hand case: 10 (5 (3, 7), 15 (-, 18)), range 7 .. 15 -> 7 + 10 + 15 = 32
   T := Empty;
   Set_Node (T, 1, 10, 2, 3); Set_Node (T, 2, 5, 4, 5); Set_Node (T, 3, 15, 0, 6);
   Set_Node (T, 4, 3, 0, 0); Set_Node (T, 5, 7, 0, 0); Set_Node (T, 6, 18, 0, 0);
   Expect (T, 1, 7, 15, 32, "hand case 7 .. 15");
   Expect (T, 1, 6, 10, 17, "hand case 6 .. 10");
   Expect (T, 1, -1000, 1000, 58, "whole tree");
   Expect (T, 1, 11, 14, 0, "empty range");
   Expect (Empty, 0, -5, 5, 0, "empty tree");
   --  31 nodes of value 1000 in a right chain: 31,000 = Sum'Last
   T := Empty;
   for K in 1 .. 31 loop
      Set_Node (T, K, 1000, 0, (if K < 31 then K + 1 else 0));
   end loop;
   Expect (T, 1, -1000, 1000, 31_000, "31 x 1000");
   --  random BSTs by insertion (equal values go right), random ranges
   for C in 1 .. 20_000 loop
      declare
         N : constant Node_Index := 1 + Next (30);
         V : Tree := Empty;
         Vals : array (Node_Index) of Value := [others => 0];
         L, R : array (Node_Index) of Index := [others => 0];
         Spread : constant Natural := (if Next (1) = 0 then 20 else 2000);
         Lo, Hi : Value;
      begin
         for K in 1 .. N loop
            Vals (K) := Next (Spread) - Spread / 2;
            if K > 1 then
               declare
                  P : Node_Index := 1;
               begin
                  loop
                     if Vals (K) < Vals (P) then
                        exit when L (P) = 0;
                        P := L (P);
                     else
                        exit when R (P) = 0;
                        P := R (P);
                     end if;
                  end loop;
                  if Vals (K) < Vals (P) then L (P) := K; else R (P) := K; end if;
               end;
            end if;
         end loop;
         for K in 1 .. N loop
            Set_Node (V, K, Vals (K), L (K), R (K));
         end loop;
         Lo := Next (Spread) - Spread / 2;
         Hi := Next (Spread) - Spread / 2;
         if Lo > Hi then
            declare X : constant Value := Lo; begin Lo := Hi; Hi := X; end;
         end if;
         Expect (V, 1, Lo, Hi, Ref_Sum (V, 1, Lo, Hi), "random case" & C'Image);
         Cases := Cases + 1;
      end;
   end loop;
   Put_Line ("BST range sum: PASS (" & Natural'Image (Cases + 7) & " cases, own full-traversal reference)");
end Tests;
