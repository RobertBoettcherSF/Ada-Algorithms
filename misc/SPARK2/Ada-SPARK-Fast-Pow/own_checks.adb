pragma Ada_2022;
--  Own checks for Fast_Pow.Power_Mod (see tests/SOURCES.txt). No expected
--  value comes from the program:
--  * repeated multiplication (E multiplications mod M) for E <= 300;
--  * exponent laws on random operands: B ** (E1 + E2) = B ** E1 * B ** E2
--    and B ** (E1 * E2) = (B ** E1) ** E2, mod M;
--  * Fermat's little theorem for the primes 2 ** 31 - 1 and 1_000_000_007;
--  * Steps = 31 on every call.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Fast_Pow; use Fast_Pow;

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
      Name : constant String := "Ada-SPARK-Fast-Pow";
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

   function Mul (A, B : Natural; M : Positive) return Natural is
     (Natural ((Long_Long_Integer (A) * Long_Long_Integer (B)) mod Long_Long_Integer (M)));

   function P (B, E : Natural; M : Positive) return Natural is
      R : constant Pow_Result := Power_Mod (B, E, M);
   begin
      Report (R.Steps = 31, "steps for" & B'Image & E'Image & M'Image);
      return R.Value;
   end P;

   function Img (B, E, M : Natural) return String is (B'Image & " **" & E'Image & " mod" & M'Image);
begin
   --  1. Repeated multiplication, small and large moduli.
   for T in 1 .. 60 loop
      declare
         B   : constant Natural := Next;
         M   : constant Positive := (if T mod 3 = 0 then Next else 1 + Next mod 1_000);
         Ref : Natural := 1 mod M;
      begin
         for E in 0 .. 300 loop
            Report (P (B, E, M) = Ref, "repeated multiplication" & Img (B, E, M));
            Ref := Mul (Ref, B mod M, M);
         end loop;
      end;
   end loop;

   --  2. Exponent laws, 2,000 random cases over the whole range.
   for T in 1 .. 2_000 loop
      declare
         B  : constant Natural := Next;
         M  : constant Positive := Next;
         E1 : constant Natural := Next / 2;
         E2 : constant Natural := Next / 2;
         F1 : constant Natural := Next mod 50_000;
         F2 : constant Natural := Next mod 40_000;
      begin
         Report (P (B, E1 + E2, M) = Mul (P (B, E1, M), P (B, E2, M), M), "sum law" & Img (B, E1, M));
         Report (P (B, F1 * F2, M) = P (P (B, F1, M), F2, M), "product law" & Img (B, F1, M));
      end;
   end loop;

   --  3. Fermat: a ** (p - 1) = 1 mod p for a prime p not dividing a.
   for T in 1 .. 500 loop
      declare
         A : constant Natural := Next;
      begin
         Report (P (A, 2_147_483_646, 2_147_483_647) = 1, "Fermat 2 ** 31 - 1 a =" & A'Image);
         if A mod 1_000_000_007 /= 0 then
            Report (P (A, 1_000_000_006, 1_000_000_007) = 1, "Fermat 1e9+7 a =" & A'Image);
         end if;
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
