pragma Ada_2022;
--  Own checks for Get-Maximum-In-Generated-Array (see tests/SOURCES.txt).
--  No expected value comes from the program:
--  * an own simulation of the problem statement (fill nums by the two
--    rules "2 <= 2 i <= n" and "2 <= 2 i + 1 <= n", i ascending);
--  * an own second method for nums (I): the binary-digit walk (a, b)
--    over the bits of I (Dijkstra's fusc), no array;
--  * an own closed form for powers of two: the largest value up to
--    2 ** K is the Fibonacci number F (K + 1) (Lucas);
--  * the ghost Nums checked against both, and Lemma_Rules run for every
--    index (assertions on).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Get_Maximum_In_Generated_Array; use Get_Maximum_In_Generated_Array;

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
      Name : constant String := "Ada-SPARK-Get-Maximum-In-Generated-Array";
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

   --  The problem statement, literally.
   Sim : array (0 .. Max_N) of Natural := [others => 0];

   --  Binary-digit walk: start (a, b) = (1, 0); for each bit of I from the
   --  lowest, a bit 1 adds a to b and a bit 0 adds b to a; nums (I) = b.
   function Walk (I : Natural) return Natural is
      A : Natural := 1;
      B : Natural := 0;
      M : Natural := I;
   begin
      while M > 0 loop
         if M mod 2 = 1 then
            B := A + B;
         else
            A := A + B;
         end if;
         M := M / 2;
      end loop;
      return B;
   end Walk;

   function Running_Max (N : Natural) return Natural is
      R : Natural := 0;
   begin
      for I in 0 .. N loop
         R := Natural'Max (R, Sim (I));
      end loop;
      return R;
   end Running_Max;

   procedure Check_N (N : N_Value) is
      G : constant Value_Array := Generate (N);
      Same : Boolean := G'First = 0 and then G'Last = N;
   begin
      if Same then
         for I in 0 .. N loop
            Same := Same and then G (I) = Sim (I);
         end loop;
      end if;
      Report (Same, "Generate" & N'Image);
      Report (Maximum (N) = Running_Max (N), "Maximum" & N'Image);
   end Check_N;

   F : array (0 .. 12) of Natural := [others => 0];
   K : Natural := 0;
begin
   --  (2 <= 2 i and 2 <= 2 i + 1 hold for every i >= 1.)
   Sim (1) := 1;
   for I in 1 .. Max_N loop
      if 2 * I <= Max_N then
         Sim (2 * I) := Sim (I);
      end if;
      if 2 * I + 1 <= Max_N then
         Sim (2 * I + 1) := Sim (I) + Sim (I + 1);
      end if;
   end loop;

   --  Two own methods agree; the ghost Nums agrees; the rules hold.
   for I in 0 .. Max_N loop
      Report (Walk (I) = Sim (I), "walk" & I'Image);
      pragma Assert (Nums (I) = Sim (I));
      Lemma_Rules (I);
   end loop;

   --  Every N up to 200, 60 seeded random N above, and the limit.
   for N in 0 .. 200 loop
      Check_N (N);
   end loop;
   for T in 1 .. 60 loop
      Check_N (201 + Next mod (Max_N - 200));
   end loop;
   Check_N (Max_N);

   --  Powers of two: Maximum (2 ** K) = F (K + 1), F (1) = F (2) = 1.
   F (1) := 1;
   F (2) := 1;
   for J in 3 .. F'Last loop
      F (J) := F (J - 1) + F (J - 2);
   end loop;
   while 2 ** K <= Max_N loop
      Report (Maximum (2 ** K) = F (K + 1), "power of two" & K'Image);
      K := K + 1;
   end loop;

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image & " checks");
   else
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;
