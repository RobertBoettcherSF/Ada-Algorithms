--  Own tests for Merge_Two_Binary_Trees (see tests/SOURCES.txt).
--  Merge (A, B) must be the overlay of A and B: a node exists where it exists in
--  either tree, with the sum of the values present. Inputs use the heap layout
--  (children of K at 2K, 2K + 1); the result is walked from its node 1, so its
--  own node numbering does not matter.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Merge_Two_Binary_Trees; use Merge_Two_Binary_Trees;

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

   type Pres is array (1 .. 15) of Boolean;
   type Vals is array (1 .. 15) of Integer;
   PA, PB : Pres;
   VA, VB : Vals;
   A, B, M : Tree;
   Ok : Boolean;
   procedure Random_Heap (P : in out Pres; V : out Vals) is
      Lim : constant Natural := Next (0, 15);
   begin
      for K in 1 .. 15 loop
         P (K) := K <= Lim and then (K = 1 or else P (K / 2)) and then Next (0, 3) > 0;
         V (K) := Next (-500, 500);
      end loop;
   end Random_Heap;
   function Make (P : Pres; V : Vals) return Tree is
      R : Tree := Empty;
      function Kid (K : Positive) return Natural is (if K <= 15 and then P (K) then K else 0);
   begin
      for K in 1 .. 15 loop
         if P (K) then
            Set_Node (R, K, V (K), Kid (2 * K), Kid (2 * K + 1));
         end if;
      end loop;
      return R;
   end Make;
   function Present (K : Positive) return Boolean is (K <= 15 and then (PA (K) or else PB (K)));
   procedure Walk (N : Natural; K : Positive) is
      Want : Integer;
   begin
      if not Present (K) then
         if N /= 0 then Ok := False; end if;
         return;
      end if;
      if N = 0 then Ok := False; return; end if;
      Want := (if PA (K) then VA (K) else 0) + (if PB (K) then VB (K) else 0);
      if Value_At (M, N) /= Want then Ok := False; end if;
      Walk (Left_Child (M, N), 2 * K);
      Walk (Right_Child (M, N), 2 * K + 1);
   end Walk;
begin
   for Iter in 1 .. 4_000 loop
      Random_Heap (PA, VA);
      Random_Heap (PB, VB);
      if PA (1) or else PB (1) then
         A := Make (PA, VA);
         B := Make (PB, VB);
         M := Merge (A, B);
         Ok := True;
         Walk (1, 1);
         Report (Ok, "random" & Iter'Image);
      end if;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own overlay reference walked from the root)");
end Own_Checks;
