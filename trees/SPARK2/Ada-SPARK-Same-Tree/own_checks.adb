--  Own tests for Same_Tree (see tests/SOURCES.txt).
--  Are_Same is True exactly when both trees have the same shape and values,
--  whatever node numbers they use.
pragma Ada_2022;
with Ada.Text_IO;
with Same_Tree; use Same_Tree;

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

   L2, R2 : Kids;
   V2 : Vals_T;
   function Ref_Same (A, B : Natural) return Boolean is
     (if A = 0 or else B = 0 then A = B
      else Vals (A) = V2 (B) and then Ref_Same (Lefts (A), L2 (B)) and then Ref_Same (Rights (A), R2 (B)));
begin
   for K in 1 .. 4_000 loop
      Random_Tree (Next (1, Max_Nodes), -2, 2);
      declare
         First : constant Tree := Build;
         Perm  : array (0 .. Max_Nodes) of Natural := [others => 0];
         Root2 : Natural;
         Second : Tree := Empty;
      begin
         --  renumber the nodes with a random permutation
         for I in 1 .. Cnt loop
            Perm (I) := I;
         end loop;
         for I in reverse 2 .. Cnt loop
            declare
               J : constant Positive := Next (1, I);
               X : constant Natural := Perm (I);
            begin
               Perm (I) := Perm (J); Perm (J) := X;
            end;
         end loop;
         L2 := [others => 0]; R2 := [others => 0]; V2 := [others => 0];
         for I in 1 .. Cnt loop
            L2 (Perm (I)) := Perm (Lefts (I));
            R2 (Perm (I)) := Perm (Rights (I));
            V2 (Perm (I)) := Vals (I);
         end loop;
         case K mod 3 is
            when 0 => null;                                              --  same tree
            when 1 => V2 (Perm (Next (1, Cnt))) := Next (-2, 2);         --  maybe one value changed
            when others =>                                               --  maybe one subtree moved
               declare
                  N : constant Positive := Perm (Next (1, Cnt));
                  X : constant Natural := L2 (N);
               begin
                  L2 (N) := R2 (N); R2 (N) := X;
               end;
         end case;
         Root2 := Perm (1);
         for I in 1 .. Cnt loop
            Set_Node (Second, I, V2 (I), L2 (I), R2 (I));
         end loop;
         Report (Are_Same (First, Second, 1, Root2) = Ref_Same (1, Root2), "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive comparison reference)");
end Own_Checks;
