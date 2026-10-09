pragma Ada_2022;
--  Own checks for Ugly-Number-II (see tests/SOURCES.txt).
--  No expected value comes from the program:
--  * an own enumeration of every 2 ** a * 3 ** b * 5 ** c up to
--    8_062_156_800, sorted (insertion sort), against First_Ugly (Max_N);
--  * the exponents of every entry against an own factorization of the
--    enumerated value (count the factors 2, 3, 5; then trial division by
--    every number from 7 up finds no other factor);
--  * Lemma_Complete run for every exponent triple whose value is at most
--    the last entry of First_Ugly (300) (assertions on, so the ghost code
--    executes).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Ugly_Number_II; use Ugly_Number_II;

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
      Name : constant String := "Ada-SPARK-Ugly-Number-II";
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

   subtype LLI is Long_Long_Integer;
   type LLI_3 is array (1 .. 3) of LLI;
   Top : constant LLI := 8_062_156_800;

   --  Own enumeration: every 2 ** a * 3 ** b * 5 ** c <= Top, then sorted.
   Enum  : array (1 .. 4_000) of LLI := [others => 0];
   Count : Natural := 0;

   procedure Enumerate is
      P5 : LLI := 1;
   begin
      while P5 <= Top loop
         declare
            P3 : LLI := P5;
         begin
            while P3 <= Top loop
               declare
                  P2 : LLI := P3;
               begin
                  while P2 <= Top loop
                     Count := Count + 1;
                     Enum (Count) := P2;
                     P2 := P2 * 2;
                  end loop;
               end;
               P3 := P3 * 3;
            end loop;
         end;
         P5 := P5 * 5;
      end loop;
      for I in 2 .. Count loop
         declare
            X : constant LLI := Enum (I);
            J : Natural := I - 1;
         begin
            while J >= 1 and then Enum (J) > X loop
               Enum (J + 1) := Enum (J);
               J := J - 1;
            end loop;
            Enum (J + 1) := X;
         end;
      end loop;
   end Enumerate;

   --  Own factorization: the number of factors P in V.
   function Mult (V, P : LLI) return Natural is
      M : LLI := V;
      R : Natural := 0;
   begin
      while M mod P = 0 loop
         M := M / P;
         R := R + 1;
      end loop;
      return R;
   end Mult;

   --  Own trial division: V has no prime factor above 5.
   function Trial (V : LLI) return Boolean is
      M : LLI := V;
      D : LLI := 7;
   begin
      for P of LLI_3'(2, 3, 5) loop
         while M mod P = 0 loop
            M := M / P;
         end loop;
      end loop;
      while D * D <= M loop
         if M mod D = 0 then
            return False;
         end if;
         D := D + 1;
      end loop;
      return M = 1;
   end Trial;

   function BL (V : LLI) return Big_Integer is (From_String (V'Image));
begin
   Enumerate;
   Report (Count >= Max_N, "enumeration has at least Max_N values");
   Report (Enum (1_691) = 2_125_764_000 and then Enum (1_692) = 2_147_483_648
           and then Enum (Max_N) = Top, "enumeration at 1691, 1692, 2000");

   --  First_Ugly (Max_N) entry by entry (one call, about 2.3 s).
   declare
      L : constant Ugly_List := First_Ugly (Max_N);
   begin
      Report (L'First = 1 and then L'Last = Max_N, "First_Ugly bounds");
      for K in 1 .. Max_N loop
         Report (L (K).Value = BL (Enum (K)), "First_Ugly entry" & K'Image);
         Report (Trial (Enum (K)) and then L (K).Two = Mult (Enum (K), 2)
                 and then L (K).Three = Mult (Enum (K), 3) and then L (K).Five = Mult (Enum (K), 5),
                 "exponents of entry" & K'Image);
      end loop;
   end;

   --  Every First_Ugly (N) for N <= 60 and Nth_Ugly at 40 seeded N <= 600.
   for N in 1 .. 60 loop
      declare
         L : constant Ugly_List := First_Ugly (N);
         Ok : Boolean := L'First = 1 and then L'Last = N;
      begin
         for K in 1 .. N loop
            Ok := Ok and then L (K).Value = BL (Enum (K));
         end loop;
         Report (Ok, "First_Ugly" & N'Image);
      end;
   end loop;
   for R in 1 .. 40 loop
      declare
         N : constant N_Index := 1 + Next mod 600;
      begin
         Report (Nth_Ugly (N) = BL (Enum (N)), "Nth_Ugly" & N'Image);
      end;
   end loop;

   --  Lemma_Complete for every triple (A, B, C) whose value is at most the
   --  last of First_Ugly (300), and the number of such triples is 300.
   declare
      L    : constant Ugly_List := First_Ugly (300);
      Last : constant LLI := Enum (300);
      Seen : Natural := 0;
      P5   : LLI := 1;
      C    : Natural := 0;
   begin
      while P5 <= Last loop
         declare
            P3 : LLI := P5;
            B  : Natural := 0;
         begin
            while P3 <= Last loop
               declare
                  P2 : LLI := P3;
                  A  : Natural := 0;
               begin
                  while P2 <= Last loop
                     Lemma_Complete (L, A, B, C);
                     Seen := Seen + 1;
                     P2 := P2 * 2;
                     A := A + 1;
                  end loop;
               end;
               P3 := P3 * 3;
               B := B + 1;
            end loop;
         end;
         P5 := P5 * 5;
         C := C + 1;
      end loop;
      Report (Seen = 300, "Lemma_Complete ran for the 300 triples");
   end;

   --  Seeded random N: Nth_Ugly (N) and the exponents of its last entry.
   for R in 1 .. 20 loop
      declare
         N : constant N_Index := 1 + Next mod 400;
         L : constant Ugly_List := First_Ugly (N);
      begin
         Report (L (N).Two = Mult (Enum (N), 2) and then L (N).Three = Mult (Enum (N), 3)
                 and then L (N).Five = Mult (Enum (N), 5), "exponents, N =" & N'Image);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error;
   end if;
end Own_Checks;
