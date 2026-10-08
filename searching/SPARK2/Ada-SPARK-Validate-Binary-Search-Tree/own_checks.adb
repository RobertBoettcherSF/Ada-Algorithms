--  Own tests for Validate_Binary_Search_Tree (see tests/SOURCES.txt).
--  Is_Valid_BST is True exactly when every node is greater than all values in its
--  left subtree and smaller than all values in its right subtree.
pragma Ada_2022;
with Ada.Text_IO;
with Validate_Binary_Search_Tree; use Validate_Binary_Search_Tree;

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

   Lefts, Rights : array (Node_Index) of Index;
   Vals : array (Node_Index) of Value;
   Cnt : Natural;

   --  Own reference: check every node against every node of its subtrees.
   function All_In (N : Index; Lo, Hi : Integer) return Boolean is
     (N = 0 or else (Vals (N) > Lo and then Vals (N) < Hi
                     and then All_In (Lefts (N), Lo, Hi) and then All_In (Rights (N), Lo, Hi)));
   function Ref (N : Index) return Boolean is
     (N = 0 or else (All_In (Lefts (N), Integer'First, Vals (N))
                     and then All_In (Rights (N), Vals (N), Integer'Last)
                     and then Ref (Lefts (N)) and then Ref (Rights (N))));

   procedure In_Order_Assign (N : Index; Next_V : in out Integer; Gap : Positive) is
   begin
      if N /= 0 then
         In_Order_Assign (Lefts (N), Next_V, Gap);
         Vals (N) := Next_V;
         Next_V := Next_V + Gap;
         In_Order_Assign (Rights (N), Next_V, Gap);
      end if;
   end In_Order_Assign;
begin
   for K in 1 .. 4_000 loop
      Cnt := Next (1, 15);
      Lefts := [others => 0];
      Rights := [others => 0];
      --  random shape: attach node I below a random earlier node with a free slot
      for I in 2 .. Cnt loop
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
      declare
         V : Integer := -90;
      begin
         In_Order_Assign (1, V, 12);       --  a valid BST with distinct values
      end;
      case K mod 3 is
         when 0 => null;                                          --  keep valid
         when 1 => Vals (Next (1, Cnt)) := 2 * Next (-50, 49) + 1;  --  perturb one node (odd: never equal to another)
         when others =>
            for I in 1 .. Cnt loop
               Vals (I) := -100 + 13 * I;      --  distinct values, random shape
            end loop;
            for I in reverse 2 .. Cnt loop
               declare
                  J : constant Positive := Next (1, I);
                  X : constant Value := Vals (I);
               begin
                  Vals (I) := Vals (J); Vals (J) := X;
               end;
            end loop;
      end case;
      declare
         T : Tree := Empty;
      begin
         for I in 1 .. Cnt loop
            Set_Node (T, I, Vals (I), Lefts (I), Rights (I));
         end loop;
         Report (Is_Valid_BST (T, 1) = Ref (1), "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-pairs subtree reference)");
end Own_Checks;
