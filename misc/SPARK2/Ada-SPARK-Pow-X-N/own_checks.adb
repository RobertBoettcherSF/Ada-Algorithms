pragma Ada_2022;
--  Own checks for Pow_X_N (see tests/SOURCES.txt). No expected value comes
--  from the program. Two references, both written here, and neither by
--  repeated squaring:
--  * naive repeated multiplication in Long_Long_Integer that stops as
--    soon as the product leaves Integer (so it never overflows itself);
--  * naive repeated multiplication in Big_Integer (no overflow at all).
--  The run-time library's Big_Integers."**" is not used: with GNAT 14.2
--  it gives (-2) ** 2 = -4 and (-3) ** 1 = 3.
--  Inputs: every X in -300 .. 300 with N in 0 .. 40; seeded random X over
--  all of Integer with N in 0 .. 40; for every N in 2 .. 31 the largest
--  R with R ** N <= Integer'Last and the most negative -S with (-S) ** N
--  >= Integer'First (found by an own binary search), checked at R - 1,
--  R, R + 1 and -S + 1, -S, -S - 1; bases -1, 0, 1 with random N up to
--  Natural'Last (N <= 5_000 against the references, larger N against the same
--  parity below 2_000); abs X >= 2 with random N >= 32 (must overflow).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;
with Interfaces; use Interfaces;
with Pow_X_N; use Pow_X_N;

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
      Name : constant String := "Ada-SPARK-Pow-X-N";
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

   Lo : constant Long_Long_Integer := Long_Long_Integer (Integer'First);
   Hi : constant Long_Long_Integer := Long_Long_Integer (Integer'Last);

   --  Naive X ** N; Fits is False as soon as a partial product leaves
   --  Integer. Once abs X >= 2 that happens within 32 steps, so the loop
   --  is short except for X in -1 .. 1, where it is only used for N <= 10 ** 6.
   procedure Naive (X : Integer; N : Natural; Value : out Long_Long_Integer; Fits : out Boolean) is
   begin
      Value := 1;
      Fits := True;
      for K in 1 .. N loop
         Value := Value * Long_Long_Integer (X);
         if Value not in Lo .. Hi then
            Fits := False;
            Value := 0;
            return;
         end if;
      end loop;
   end Naive;

   function Big_Naive (X : Integer; N : Natural) return Big_Integer is
      V : Big_Integer := 1;
   begin
      for K in 1 .. N loop
         V := V * To_Big_Integer (X);
      end loop;
      return V;
   end Big_Naive;

   procedure Check (X : Integer; N : Natural) is
      R      : Integer;
      Ok     : Boolean;
      Want   : Long_Long_Integer;
      Fits   : Boolean;
      Lib    : constant Big_Integer := Big_Naive (X, N);
      Lib_Ok : constant Boolean :=
        In_Range (Lib, To_Big_Integer (Integer'First), To_Big_Integer (Integer'Last));
      Label  : constant String := "Power" & X'Image & N'Image;
   begin
      Power (X, N, R, Ok);
      Report (Ok = Lib_Ok and then (if Ok then To_Big_Integer (R) = Lib else R = 0), Label & " vs Big_Integer");
      Naive (X, N, Want, Fits);
      Report (Ok = Fits and then (if Ok then Long_Long_Integer (R) = Want else R = 0), Label & " vs naive");
   end Check;

   --  Own integer root: the largest R >= 1 with R ** N <= Hi (or, for
   --  Bottom, the largest S with (-S) ** N >= Lo), by binary search.
   function Root (N : Positive; Bottom : Boolean) return Integer is
      L : Long_Long_Integer := 1;
      U : Long_Long_Integer := 2 ** 31 + 1;
      function Fits_At (S : Long_Long_Integer) return Boolean is
         V : Long_Long_Integer := 1;
         F : constant Long_Long_Integer := (if Bottom then -S else S);
      begin
         for K in 1 .. N loop
            V := V * F;
            if V not in Lo .. Hi then
               return False;
            end if;
         end loop;
         return True;
      end Fits_At;
   begin
      --  Fits_At (L) holds, Fits_At (U) does not.
      while U - L > 1 loop
         declare
            M : constant Long_Long_Integer := (L + U) / 2;
         begin
            if Fits_At (M) then
               L := M;
            else
               U := M;
            end if;
         end;
      end loop;
      return Integer (L);
   end Root;
begin
   for X in -300 .. 300 loop
      for N in 0 .. 40 loop
         Check (X, N);
      end loop;
   end loop;

   for I in 1 .. 20_000 loop
      declare
         V : constant Natural := Next;
         X : constant Integer := Integer (Long_Long_Integer (V) * 2 - 2 ** 31 + Long_Long_Integer (Next mod 2));
      begin
         Check (X, Next mod 41);
         Check (Integer'Last - V, Next mod 3);
         Check (Integer'First + V, Next mod 3);
      end;
   end loop;

   for N in 2 .. 31 loop
      declare
         R : constant Integer := Root (N, Bottom => False);
         S : constant Integer := Root (N, Bottom => True);
      begin
         for D in -1 .. 1 loop
            Check (R + D, N);
            Check (-S - D, N);
         end loop;
      end;
   end loop;

   for I in 1 .. 300 loop
      for X in -1 .. 1 loop
         Check (X, Next mod 5_001);
         --  Huge N: X ** N = X ** (1_000 + N mod 1_000) for X in -1 .. 1
         --  and N >= 1 (the same parity, and both exponents positive).
         declare
            N   : constant Natural := Natural'Last - Next mod 1_000;
            Res : Integer;
            Ok  : Boolean;
            Want : Long_Long_Integer;
            Fits : Boolean;
         begin
            Power (X, N, Res, Ok);
            Naive (X, 1_000 + N mod 1_000, Want, Fits);
            Report (Ok and then Fits and then Long_Long_Integer (Res) = Want, "Power" & X'Image & N'Image);
         end;
      end loop;
      declare
         V : constant Natural := Next;
         X : constant Integer := (if V mod 2 = 0 then 2 + V / 2 else -2 - V / 2);
         N : constant Natural := 32 + Next mod (Natural'Last - 31);
         Res : Integer;
         Ok  : Boolean;
      begin
         Power (X, N, Res, Ok);
         Report (not Ok and then Res = 0, "Power" & X'Image & N'Image & " must overflow");
         Check (X, 32 + Next mod 9);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
