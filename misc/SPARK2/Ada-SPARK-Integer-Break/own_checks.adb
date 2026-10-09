pragma Ada_2022;
--  Own checks for Integer-Break (see tests/SOURCES.txt). No expected value
--  comes from the program:
--  * an own exhaustive enumeration of every partition of N (parts in
--    non-increasing order, at least two parts) for N in 2 .. 58;
--  * an own closed form (threes, with a 4 or a 2 for the remainder);
--  * the ghost tables Best and Arg regenerated from the enumeration;
--  * Best_Split checked against the rule its comment states, built from
--    the enumerated values;
--  * the ghost lemma Lemma_Optimal run (assertions on) on seeded random
--    splits.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Integer_Break; use Integer_Break;

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
      Name : constant String := "Ada-SPARK-Integer-Break";
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

   --  Own exhaustive enumeration: the largest product over all partitions
   --  of N into at least two parts (Brute (1) = 0: no such partition).
   Brute     : array (1 .. Max_N) of Long_Long_Integer := [others => 0];
   Leaves    : Long_Long_Integer := 0;

   procedure Enum (Left, Max_Part, Parts : Natural; Prod : Long_Long_Integer; Top : in out Long_Long_Integer) is
   begin
      if Left = 0 then
         Leaves := Leaves + 1;
         if Parts >= 2 and then Prod > Top then
            Top := Prod;
         end if;
         return;
      end if;
      for P in reverse 1 .. Natural'Min (Left, Max_Part) loop
         Enum (Left - P, P, Parts + 1, Prod * Long_Long_Integer (P), Top);
      end loop;
   end Enum;

   --  Own closed form: as many threes as possible, a 4 (two 2s) for
   --  remainder 1 and a 2 for remainder 2; N <= 4 by hand.
   function Closed (N : Positive) return Long_Long_Integer is
      R : Long_Long_Integer := 1;
      M : Natural := N;
   begin
      case N is
         when 1 => return 0;
         when 2 => return 1;
         when 3 => return 2;
         when 4 => return 4;
         when others => null;
      end case;
      if N mod 3 = 1 then
         R := 4;
         M := N - 4;
      elsif N mod 3 = 2 then
         R := 2;
         M := N - 2;
      end if;
      for I in 1 .. M / 3 loop
         R := R * 3;
      end loop;
      return R;
   end Closed;

   function Whole_Or (M : Positive) return Long_Long_Integer is
     (Long_Long_Integer'Max (Long_Long_Integer (M), Brute (M)));

   --  The smallest first part reaching Brute (M), from enumerated values.
   function Own_Arg (M : Number) return Positive is
   begin
      for K in 1 .. M - 1 loop
         if Long_Long_Integer (K) * Whole_Or (M - K) = Brute (M) then
            return K;
         end if;
      end loop;
      raise Program_Error;
   end Own_Arg;

   Ghost_Checked : Natural := 0;
begin
   for N in 2 .. Max_N loop
      declare
         B : Long_Long_Integer := 0;
      begin
         Enum (N, N, 0, 1, B);
         Brute (N) := B;
      end;
   end loop;

   --  The closed form and the enumeration agree, and the limit is real.
   for N in 1 .. Max_N loop
      Report (Closed (N) = Brute (N), "closed form" & N'Image);
   end loop;
   Report (Brute (58) <= Long_Long_Integer (Natural'Last), "58 fits Natural");
   Report (Closed (59) > Long_Long_Integer (Natural'Last), "59 does not fit Natural");

   for N in Number loop
      --  Maximum against the enumeration.
      Report (Long_Long_Integer (Maximum (N)) = Brute (N), "Maximum" & N'Image);

      --  The ghost tables regenerated (assertions on).
      pragma Assert (Best (N) = Brute (N));
      pragma Assert (Arg (N) = Own_Arg (N));
      pragma Assert (Row (N));
      Ghost_Checked := Ghost_Checked + 3;

      --  Best_Split: at least two parts, sum N, product Brute (N), and the
      --  stated rule: the smallest best first part, then the rest kept
      --  whole when that is at least as good as splitting it.
      declare
         S    : constant Part_List := Best_Split (N);
         Sum  : Natural := 0;
         Prod : Long_Long_Integer := 1;
         Want : Part_List (1 .. N);
         Len  : Natural := 1;
         M    : Natural;
      begin
         for P of S loop
            Sum := Sum + P;
            Prod := Prod * Long_Long_Integer (P);
         end loop;
         Report (S'First = 1 and then S'Length >= 2 and then Sum = N and then Prod = Brute (N),
                 "Best_Split properties" & N'Image);
         Want (1) := Own_Arg (N);
         M := N - Want (1);
         while M >= 2 and then Brute (M) > Long_Long_Integer (M) loop
            Len := Len + 1;
            Want (Len) := Own_Arg (M);
            M := M - Want (Len);
         end loop;
         Len := Len + 1;
         Want (Len) := M;
         Report (S'Length = Len and then S = Want (1 .. Len), "Best_Split rule" & N'Image);
      end;
   end loop;
   pragma Assert (Best (1) = 0);
   Ghost_Checked := Ghost_Checked + 1;

   --  Seeded random splits: never better than Maximum; Lemma_Optimal runs
   --  with its contracts checked.
   for Trial in 1 .. 3_000 loop
      declare
         N    : constant Number := 2 + Next mod (Max_N - 1);
         P    : Part_List (1 .. N);
         Len  : Natural := 0;
         Left  : Natural := N;
         Prod : Long_Long_Integer := 1;
      begin
         while Left > 0 loop
            declare
               --  Small parts are more common so that products stay near
               --  the best; the first part is below N so that there are at
               --  least two parts.
               Cap : constant Positive := (if Len = 0 then N - 1 else Left);
               Q   : constant Positive :=
                 (if Next mod 4 = 0 then 1 + Next mod Cap else 1 + Next mod Positive'Min (Cap, 4));
            begin
               Len := Len + 1;
               P (Len) := Q;
               Left := Left - Q;
               Prod := Prod * Long_Long_Integer (Q);
            end;
         end loop;
         Report (Len >= 2 and then Prod <= Brute (N), "random split" & Trial'Image);
         Lemma_Optimal (N, P (1 .. Len));
      end;
   end loop;

   Ada.Text_IO.Put_Line ("partitions enumerated:" & Leaves'Image & "; ghost table asserts:" & Ghost_Checked'Image);
   if Failures = 0 then
      Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image & " checks");
   else
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;
