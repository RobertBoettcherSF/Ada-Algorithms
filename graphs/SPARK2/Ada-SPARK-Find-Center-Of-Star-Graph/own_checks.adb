pragma Ada_2022;
--  Own checks for Find-Center-Of-Star-Graph (V&V sweep, agent A3,
--  2026-10-09; see tests/SOURCES.txt). Reference: a vertex is the centre
--  when it is an endpoint of every edge (checked edge by edge, no degree
--  count); for a simple graph with 15 edges at most one vertex can be.
--  Inputs (all simple graphs: no self-loop, no repeated edge):
--  * every centre 1 .. 16 with its 15 spokes in 300 seeded random orders
--    and orientations each (4,800 stars);
--  * 800 near-stars: a star with one spoke replaced by an edge between
--    two other leaves (the old centre then touches 14 edges; answer 0);
--  * 5,000 seeded random simple graphs with 15 edges (almost never stars).
--  Seeded: Park-Miller minimal standard generator; default seed = FNV-1a
--  (32-bit) of the folder name folded into 1 .. 2 ** 31 - 2, printed;
--  AA_SEED=<n> overrides it.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Find_Center_Of_Star_Graph; use Find_Center_Of_Star_Graph;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Find-Center-Of-Star-Graph";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Reference (E : Edge_List) return Answer is
   begin
      for V in Vertex loop
         if (for all I in E'Range => E (I).From = V or else E (I).To = V) then
            return V;
         end if;
      end loop;
      return 0;
   end Reference;

   procedure Shuffle (E : in out Edge_List) is
   begin
      for I in reverse E'First + 1 .. E'Last loop
         declare
            J : constant Positive := E'First + Next mod (I - E'First + 1);
            T : constant Edge := E (I);
         begin
            E (I) := E (J);
            E (J) := T;
         end;
         if Next mod 2 = 0 then
            E (I) := (From => E (I).To, To => E (I).From);
         end if;
      end loop;
   end Shuffle;

   function Star (C : Vertex) return Edge_List is
      E : Edge_List;
      K : Positive := E'First;
   begin
      for V in Vertex loop
         if V /= C then
            E (K) := (From => C, To => V);
            K := K + 1;
         end if;
      end loop;
      return E;
   end Star;

   procedure One (E : Edge_List; Label : String) is
      R : constant Answer := Reference (E);
   begin
      Report (Find_Center (E) = R, Label & ": expected" & R'Image);
   end One;
begin
   for C in Vertex loop
      for T in 1 .. 300 loop
         declare
            E : Edge_List := Star (C);
         begin
            Shuffle (E);
            Report (Reference (E) = C, "reference sees the star");
            One (E, "star, centre" & C'Image);
         end;
      end loop;
      --  Near-stars: spoke (C, L1) replaced by (L2, L3) for leaves L1, L2,
      --  L3 (L1 then has no edge, L2 and L3 two each); no centre.
      for T in 1 .. 50 loop
         declare
            E  : Edge_List := Star (C);
            K  : constant Positive := E'First + Next mod E'Length;
            K2 : Positive;
            K3 : Positive;
         begin
            loop
               K2 := E'First + Next mod E'Length;
               K3 := E'First + Next mod E'Length;
               exit when K2 /= K and then K3 /= K and then K2 /= K3;
            end loop;
            E (K) := (From => E (K2).To, To => E (K3).To);
            Shuffle (E);
            Report (Reference (E) = 0, "reference: near-star has no centre");
            One (E, "near-star, old centre" & C'Image);
         end;
      end loop;
   end loop;

   --  Random simple graphs with 15 edges.
   for T in 1 .. 5_000 loop
      declare
         Used : array (Vertex, Vertex) of Boolean := [others => [others => False]];
         E    : Edge_List;
         A, B : Vertex;
      begin
         for I in E'Range loop
            loop
               A := 1 + Next mod 16;
               B := 1 + Next mod 16;
               exit when A /= B and then not Used (A, B);
            end loop;
            Used (A, B) := True;
            Used (B, A) := True;
            E (I) := (From => A, To => B);
         end loop;
         One (E, "random simple graph");
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
