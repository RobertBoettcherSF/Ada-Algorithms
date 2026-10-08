--  Own tests for Binary_Tree_Preorder (see tests/SOURCES.txt).
--  Preorder_Sum must return the sum of all values reachable from Root (0 for Root = 0).
pragma Ada_2022;
with Ada.Text_IO;
with Binary_Tree_Preorder; use Binary_Tree_Preorder;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;


   Max_Nodes : constant := 15;
   type Kids is array (0 .. Max_Nodes) of Natural;
   type Vals_T is array (0 .. Max_Nodes) of Integer;
   Lefts, Rights : Kids;
   Vals : Vals_T;
   Cnt : Natural;

   --  Random tree shape with Cnt nodes rooted at node 1: node I is attached below
   --  a random earlier node with a free slot. Values random in Lo .. Hi.
   procedure Random_Tree (N : Positive; Lo, Hi : Integer) is
   begin
      Cnt := N;
      Lefts := [others => 0];
      Rights := [others => 0];
      Vals := [others => 0];
      for I in 1 .. N loop
         Vals (I) := Next (Lo, Hi);
      end loop;
      for I in 2 .. N loop
         loop
            declare
               P : constant Positive := Next (1, I - 1);
            begin
               if Next (0, 1) = 0 then
                  if Lefts (P) = 0 then Lefts (P) := I; exit; end if;
               else
                  if Rights (P) = 0 then Rights (P) := I; exit; end if;
               end if;
            end;
         end loop;
      end loop;
   end Random_Tree;

   function Build return Tree is
      R : Tree := Empty;
   begin
      for I in 1 .. Cnt loop
         Set_Node (R, I, Vals (I), Lefts (I), Rights (I));
      end loop;
      return R;
   end Build;

   --  own references
   function Ref_Sum (N : Natural) return Long_Long_Integer is
     (if N = 0 then 0 else Long_Long_Integer (Vals (N)) + Ref_Sum (Lefts (N)) + Ref_Sum (Rights (N)));
begin
   Report (Preorder_Sum (Empty, 0) = 0, "empty tree");
   for K in 1 .. 4_000 loop
      Random_Tree (Next (1, Max_Nodes), -100, 100);
      Report (Preorder_Sum (Build, 1) = Ref_Sum (1), "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive subtree-sum reference)");
end Own_Checks;
