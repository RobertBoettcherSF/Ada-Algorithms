--  Own tests for Subtree_Of_Another_Tree (see tests/SOURCES.txt).
--  Is_Subtree: some node of T has a subtree identical (shape and values) to Pattern.
pragma Ada_2022;
with Ada.Text_IO;
with Subtree_Of_Another_Tree; use Subtree_Of_Another_Tree;

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

   PL, PR : Kids;
   PV : Vals_T;
   PCnt : Natural;
   function Copy (Src : Natural) return Natural is
      N : Natural;
   begin
      if Src = 0 then
         return 0;
      end if;
      PCnt := PCnt + 1;
      N := PCnt;
      PV (N) := Vals (Src);
      PL (N) := Copy (Lefts (Src));
      PR (N) := Copy (Rights (Src));
      return N;
   end Copy;
   function Ident (A, B : Natural) return Boolean is
     (if A = 0 or else B = 0 then A = B
      else Vals (A) = PV (B) and then Ident (Lefts (A), PL (B)) and then Ident (Rights (A), PR (B)));
   function Prefix (A, B : Natural) return Boolean is    --  pattern B fits on top of the subtree at A
     (if B = 0 then True elsif A = 0 then False
      else Vals (A) = PV (B) and then Prefix (Lefts (A), PL (B)) and then Prefix (Rights (A), PR (B)));
begin
   for K in 1 .. 5_000 loop
      Random_Tree (Next (1, Max_Nodes), 0, 1);
      PL := [others => 0]; PR := [others => 0]; PV := [others => 0]; PCnt := 0;
      if K mod 2 = 0 then
         declare R : constant Natural := Copy (Next (1, Cnt)); begin pragma Assert (R = 1); end;
         if K mod 4 = 0 then
            PV (Next (1, PCnt)) := 5;      --  a value that never occurs in T
         end if;
      else
         --  a small random pattern: chain or cherry with values 0 .. 1
         PCnt := Next (1, 3);
         for I in 1 .. PCnt loop
            PV (I) := Next (0, 1);
         end loop;
         if PCnt >= 2 then PL (1) := 2; end if;
         if PCnt = 3 then
            if Next (0, 1) = 0 then PR (1) := 3; else PL (2) := 3; end if;
         end if;
      end if;
      declare
         P : Tree := Empty;
         Any_Ident, Any_Prefix : Boolean := False;
      begin
         for I in 1 .. PCnt loop
            Set_Node (P, I, PV (I), PL (I), PR (I));
         end loop;
         for N in 1 .. Cnt loop
            Any_Ident := Any_Ident or else Ident (N, 1);
            Any_Prefix := Any_Prefix or else Prefix (N, 1);
         end loop;
         if Any_Ident then
            Report (Is_Subtree (Build, 1, P, 1), "copied subtree" & K'Image);
         elsif not Any_Prefix then
            Report (not Is_Subtree (Build, 1, P, 1), "absent" & K'Image);
         end if;
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own identical-subtree reference)");
end Own_Checks;
