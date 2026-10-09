pragma Ada_2022;
--  Own checks for Climbing-Stairs (see tests/SOURCES.txt). No expected
--  value comes from the program:
--  * an own recursive generator lists every climb of N <= 15 stairs in
--    dictionary order (single step tried before double step); Climb (N, K)
--    must be the K-th of them and Count (N) their number;
--  * an own closed count: a climb with D double steps has N - D steps in
--    all, so there are C (N - D, D) of them; the sum over D (binomials in
--    Long_Long_Integer, multiplicative) must equal Count (N) for every
--    N <= 45 and regenerate the ghost table Ways, and for N = 46 it must
--    exceed Natural'Last (the limit);
--  * seeded random N in 16 .. 45 and K (plus K = 0 and K = Count - 1):
--    the climb has steps 1 or 2 summing to N, its own rank (from the own
--    closed count) is K, and climb K comes before climb K + 1.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Climbing_Stairs; use Climbing_Stairs;

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
      Name : constant String := "Ada-SPARK-Climbing-Stairs";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   --  C (A, B), multiplicatively; exact at every step.
   function Binomial (A, B : Natural) return Long_Long_Integer is
      R : Long_Long_Integer := 1;
   begin
      for I in 1 .. B loop
         R := R * Long_Long_Integer (A - B + I) / Long_Long_Integer (I);
      end loop;
      return R;
   end Binomial;

   function Own_Ways (N : Natural) return Long_Long_Integer is
      S : Long_Long_Integer := 0;
   begin
      for D in 0 .. N / 2 loop
         S := S + Binomial (N - D, D);
      end loop;
      return S;
   end Own_Ways;

   function Own_Rank (A : Step_List; N : Natural) return Long_Long_Integer is
      R    : Long_Long_Integer := 0;
      Left : Natural := N;
   begin
      for S of A loop
         if S = 2 then
            R := R + Own_Ways (Left - 1);
         end if;
         Left := Left - S;
      end loop;
      return R;
   end Own_Rank;

   function Sum (A : Step_List) return Natural is
      S : Natural := 0;
   begin
      for X of A loop
         S := S + X;
      end loop;
      return S;
   end Sum;

   function Before (A, B : Step_List) return Boolean is
   begin
      for I in 0 .. Natural'Min (A'Length, B'Length) - 1 loop
         if A (A'First + I) /= B (B'First + I) then
            return A (A'First + I) < B (B'First + I);
         end if;
      end loop;
      return A'Length < B'Length;
   end Before;

   --  Own generator: every climb of the remaining stairs after Prefix.
   Index : Natural;
   procedure Generate (N : Steps; Prefix : Step_List; Left : Natural) is
   begin
      if Left = 0 then
         declare
            Got : constant Step_List := Climb (N, Index);
         begin
            Report (Got'First = 1 and then Got'Length = Prefix'Length
                    and then (Got'Length = 0 or else Got = Prefix), "Climb" & N'Image & Index'Image);
         end;
         Index := Index + 1;
         return;
      end if;
      Generate (N, Prefix & Step'(1), Left - 1);
      if Left >= 2 then
         Generate (N, Prefix & Step'(2), Left - 2);
      end if;
   end Generate;

   procedure Check_Random (N : Steps; K : Natural) is
      A : constant Step_List := Climb (N, K);
   begin
      Report (A'First = 1 and then Sum (A) = N, "sum" & N'Image & K'Image);
      Report (Own_Rank (A, N) = Long_Long_Integer (K), "rank" & N'Image & K'Image);
      if K + 1 < Count (N) then
         Report (Before (A, Climb (N, K + 1)), "order" & N'Image & K'Image);
      end if;
   end Check_Random;

   Empty : constant Step_List (1 .. 0) := [];
begin
   for N in 0 .. 15 loop
      Index := 0;
      Generate (N, Empty, N);
      Report (Index = Count (N), "Count vs generator" & N'Image);
   end loop;

   for N in Steps loop
      Report (Long_Long_Integer (Count (N)) = Own_Ways (N), "Count vs closed count" & N'Image);
   end loop;
   Report (Own_Ways (Max_Stairs + 1) > Long_Long_Integer (Natural'Last), "limit 46 overflows");
   --  The ghost table regenerated entry by entry from the own closed count.
   for N in Steps loop
      pragma Assert (Ways (N) = To_Big_Integer (Integer (Own_Ways (N))));
   end loop;
   Report (Own_Ways (Max_Stairs) <= Long_Long_Integer (Natural'Last), "limit 45 fits");

   for T in 1 .. 1_000 loop
      declare
         N : constant Steps := 16 + Next mod (Max_Stairs - 15);
         C : constant Positive := Count (N);
      begin
         case T mod 4 is
            when 0 => Check_Random (N, 0);
            when 1 => Check_Random (N, C - 1);
            when others => Check_Random (N, Next mod C);
         end case;
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
