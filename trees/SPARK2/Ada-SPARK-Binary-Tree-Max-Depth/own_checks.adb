--  Own tests for Binary_Tree_Max_Depth (see tests/SOURCES.txt).
--  Max_Depth must match the own maximum depth reference (counting convention fixed by the one-node tree).
pragma Ada_2022;
with Ada.Text_IO;
with Binary_Tree_Max_Depth; use Binary_Tree_Max_Depth;

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
   pragma Warnings (Off, Next);

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

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);

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
   function Ref_Height (N : Natural) return Natural is      --  nodes on the longest downward path
     (if N = 0 then 0 else 1 + Natural'Max (Ref_Height (Lefts (N)), Ref_Height (Rights (N))));
   function Ref_Min (N : Natural) return Natural is         --  nodes on the shortest root-to-leaf path
     (if Lefts (N) = 0 and then Rights (N) = 0 then 1
      elsif Lefts (N) = 0 then 1 + Ref_Min (Rights (N))
      elsif Rights (N) = 0 then 1 + Ref_Min (Lefts (N))
      else 1 + Natural'Min (Ref_Min (Lefts (N)), Ref_Min (Rights (N))));
   function Ref_Diam_Edges (N : Natural) return Natural is  --  edges on the longest path between two nodes
     (if N = 0 then 0
      else Natural'Max (Ref_Height (Lefts (N)) + Ref_Height (Rights (N)),
                        Natural'Max (Ref_Diam_Edges (Lefts (N)), Ref_Diam_Edges (Rights (N)))));
   pragma Warnings (Off, Ref_Sum);
   pragma Warnings (Off, Ref_Height);
   pragma Warnings (Off, Ref_Min);
   pragma Warnings (Off, Ref_Diam_Edges);
begin
   declare
      One : Natural;
      Off : Integer;
   begin
      Random_Tree (1, 0, 0);
      One := Max_Depth (Build, 1);
      Off := One - Ref_Height (1);   --  0 if nodes are counted, -1 if edges are counted
      Report (Off in -1 .. 0, "one-node tree gives 0 or 1");
      for K in 1 .. 4_000 loop
         Random_Tree (Next (1, Max_Nodes), -100, 100);
         Report (Max_Depth (Build, 1) = Ref_Height (1) + Off, "random" & K'Image);
      end loop;
   end;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive maximum depth reference)");
end Own_Checks;
