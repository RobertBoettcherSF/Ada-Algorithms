--  Own tests for Lowest_Common_Ancestor_Of_BST (see tests/SOURCES.txt).
--  For two different values present in the BST, the result is the node that is
--  the deepest common ancestor of both.
pragma Ada_2022;
with Ada.Text_IO;
with Lowest_Common_Ancestor_Of_BST; use Lowest_Common_Ancestor_Of_BST;

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

   Parent : Kids;
   procedure In_Order_Assign (N : Natural; V : in out Integer) is
   begin
      if N /= 0 then
         In_Order_Assign (Lefts (N), V);
         V := V + Next (1, 5);
         Vals (N) := V;
         In_Order_Assign (Rights (N), V);
      end if;
   end In_Order_Assign;
   function Depth_Of (N : Natural) return Natural is (if N = 1 then 0 else 1 + Depth_Of (Parent (N)));
begin
   for K in 1 .. 4_000 loop
      Random_Tree (Next (2, Max_Nodes), 0, 0);
      declare
         V : Integer := -100;
      begin
         In_Order_Assign (1, V);       --  distinct increasing in-order values: a BST
      end;
      Parent := [others => 0];
      for I in 1 .. Cnt loop
         if Lefts (I) /= 0 then Parent (Lefts (I)) := I; end if;
         if Rights (I) /= 0 then Parent (Rights (I)) := I; end if;
      end loop;
      declare
         NA : constant Positive := Next (1, Cnt);
         NB : Positive := Next (1, Cnt);
         X, Y : Natural;
      begin
         if NB = NA then
            NB := (if NA = Cnt then 1 else NA + 1);
         end if;
         --  own reference: climb from the deeper node until both meet (uses parent links only)
         X := NA; Y := NB;
         while X /= Y loop
            if Depth_Of (X) >= Depth_Of (Y) then X := Parent (X); else Y := Parent (Y); end if;
         end loop;
         Report (Lowest_Common_Ancestor (Build, 1, Vals (NA), Vals (NB)) = X, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own parent-climbing reference)");
end Own_Checks;
