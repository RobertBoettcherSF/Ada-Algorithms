--  Own tests for Symmetric_Tree (see tests/SOURCES.txt).
--  Is_Symmetric is True exactly when the tree equals its mirror image.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Symmetric_Tree; use Symmetric_Tree;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
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
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
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

   function Mirror (A, B : Natural) return Boolean is
     (if A = 0 or else B = 0 then A = B
      else Vals (A) = Vals (B) and then Mirror (Lefts (A), Rights (B)) and then Mirror (Rights (A), Lefts (B)));
   --  copy the subtree at Src mirrored to fresh nodes; returns the new root
   function Copy_Mirror (Src : Natural) return Natural is
      N : Natural;
   begin
      if Src = 0 then
         return 0;
      end if;
      Cnt := Cnt + 1;
      N := Cnt;
      Vals (N) := Vals (Src);
      Lefts (N) := Copy_Mirror (Rights (Src));
      Rights (N) := Copy_Mirror (Lefts (Src));
      return N;
   end Copy_Mirror;
begin
   for K in 1 .. 4_000 loop
      if K mod 2 = 0 then
         --  symmetric: root 1, left subtree random (nodes 2 .. k + 1), right = its mirror
         declare
            Half : constant Natural := Next (0, 7);
         begin
            Random_Tree (Half + 1, -3, 3);
            --  make node 2 the left child of node 1 and keep the rest of the shape below it
            declare
               L1 : constant Natural := Lefts (1);
               R1 : constant Natural := Rights (1);
            begin
               --  the random shape below node 1 becomes the left subtree via a fresh root copy
               Lefts (1) := (if Half = 0 then 0 else (if L1 /= 0 then L1 else R1));
               if Half > 0 and then L1 /= 0 and then R1 /= 0 then
                  --  hang the right part below the leftmost free slot of the left part
                  declare
                     P : Natural := L1;
                  begin
                     while Lefts (P) /= 0 loop
                        P := Lefts (P);
                     end loop;
                     Lefts (P) := R1;
                  end;
               end if;
               Rights (1) := Copy_Mirror (Lefts (1));
               if K mod 4 = 0 and then Cnt > 1 then
                  Vals (Next (2, Cnt)) := 50;       --  break the symmetry (unless the mirror image also has 50)
               end if;
            end;
         end;
      else
         Random_Tree (Next (1, Max_Nodes), -1, 1);
      end if;
      Report (Is_Symmetric (Build, 1) = Mirror (Lefts (1), Rights (1)), "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own mirror-comparison reference)");
end Own_Checks;
