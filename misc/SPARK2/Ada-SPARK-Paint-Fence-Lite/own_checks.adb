pragma Ada_2022;
--  Own checks for Paint_Fence_Lite.Count (see tests/SOURCES.txt). No
--  expected value comes from the program:
--  * brute force: every colouring of N posts with K colours (K ** N <= 2 ** 16),
--    counted when no three adjacent posts share a colour;
--  * the run formula: a colouring is a sequence of B runs of length 1 or 2,
--    C (B, N - B) ways to place the runs and K (K - 1) ** (B - 1) ways to
--    colour them, so T (N) = sum over B of C (B, N - B) K (K - 1) ** (B - 1),
--    mod M, on seeded random N <= 1_000, K and M;
--  * the result is the same for K and K + M (only K mod M matters).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Paint_Fence_Lite; use Paint_Fence_Lite;

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
      Name : constant String := "Ada-SPARK-Paint-Fence-Lite";
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

   function Img (N, K, M : Natural) return String is (N'Image & K'Image & M'Image);

   --  1. Brute force.
   function Brute (N, K : Positive) return Natural is
      Col   : array (1 .. N) of Natural := [others => 0];
      Total : Natural := 0;
      Ok    : Boolean;
   begin
      loop
         Ok := True;
         for I in 3 .. N loop
            if Col (I) = Col (I - 1) and then Col (I - 1) = Col (I - 2) then
               Ok := False;
            end if;
         end loop;
         if Ok then
            Total := Total + 1;
         end if;
         --  Next colouring (base-K counter).
         declare
            I : Natural := N;
         begin
            while I > 0 and then Col (I) = K - 1 loop
               Col (I) := 0;
               I := I - 1;
            end loop;
            exit when I = 0;
            Col (I) := Col (I) + 1;
         end;
      end loop;
      return Total;
   end Brute;

   --  2. The run formula mod M, with Pascal's triangle mod M.
   Max_N : constant := 1_000;
   type Row is array (0 .. Max_N) of Long_Long_Integer;
   type Row_Access is access Row;
   function Run_Formula (N, K, M : Positive) return Natural is
      MM    : constant Long_Long_Integer := Long_Long_Integer (M);
      Prev  : constant Row_Access := new Row'(others => 0);
      Cur   : constant Row_Access := new Row'(others => 0);
      Binom : array (0 .. N) of Long_Long_Integer := [others => 0];   --  C (B, N - B)
      Pow   : Long_Long_Integer := Long_Long_Integer (K) mod MM;      --  K (K - 1) ** (B - 1)
      Sum   : Long_Long_Integer := 0;
   begin
      --  Row B of Pascal's triangle, for B = 0 .. N; keep C (B, N - B).
      Prev (0) := 1 mod MM;
      Binom (0) := 0;    --  C (0, N) = 0 for N >= 1
      for B in 1 .. N loop
         Cur.all := [others => 0];
         Cur (0) := 1 mod MM;
         for J in 1 .. B loop
            Cur (J) := (Prev (J - 1) + Prev (J)) mod MM;
         end loop;
         if N - B <= B then
            Binom (B) := Cur (N - B);
         end if;
         Prev.all := Cur.all;
      end loop;
      for B in 1 .. N loop
         Sum := (Sum + Binom (B) * Pow) mod MM;
         Pow := Pow * (Long_Long_Integer (K - 1) mod MM) mod MM;
      end loop;
      return Natural (Sum);
   end Run_Formula;
begin
   for K in 1 .. 6 loop
      for N in 1 .. 16 loop
         exit when Long_Long_Integer (K) ** N > 2 ** 16;
         Report (Count (N, K, 2_147_483_647) = Brute (N, K), "brute force" & Img (N, K, 0));
      end loop;
   end loop;

   for T in 1 .. 30 loop
      declare
         N : constant Positive := 1 + Next mod Max_N;
         K : constant Positive := (if T mod 2 = 0 then 1 + Next mod 10 else 1 + Next);
         M : constant Positive := (if T mod 3 = 0 then 1 + Next mod 100 else 1 + Next);
      begin
         Report (Count (N, K, M) = Run_Formula (N, K, M), "run formula" & Img (N, K, M));
         if K <= Positive'Last - M then
            Report (Count (N, K, M) = Count (N, K + M, M), "K mod M" & Img (N, K, M));
         end if;
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
