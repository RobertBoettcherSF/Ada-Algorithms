pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Create_Maximum_Number_Lite; use Create_Maximum_Number_Lite;
--  Own checks (H121): Create Maximum Number. Max_Number (A, M, B, N, K)
--  must be the largest K-digit sequence (lexicographically) that keeps the
--  relative order of the digits taken from A (1 .. M) and from B (1 .. N).
--  Reference: every subsequence of A and of B with sizes adding up to K and
--  every interleaving of the two (brute force). Exhaustive over all digit
--  strings on {0, 1} with M, N <= 3 and every K, plus 3,000 random cases
--  with M, N <= 5 and digits 0 .. 9 or 0 .. 2 (many ties); known cases.
--  Seed 20261009.
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   type Seq is array (1 .. 64) of Integer;

   function Greater (X, Y : Seq; K : Natural) return Boolean is
   begin
      for I in 1 .. K loop
         if X (I) /= Y (I) then
            return X (I) > Y (I);
         end if;
      end loop;
      return False;
   end Greater;

   --  Brute force: best over all choices.
   function Reference (A : Digit_Array; M : Length_Type; B : Digit_Array; N : Length_Type; K : Natural) return Seq is
      Best : Seq := [others => -1];
      SA, SB : Seq;
      LA, LB : Natural;
      Cur : Seq;
      procedure Interleave (I, J, P : Natural) is
      begin
         if P > K then
            if Greater (Cur, Best, K) then
               Best := Cur;
            end if;
            return;
         end if;
         if I < LA then
            Cur (P) := SA (I + 1);
            Interleave (I + 1, J, P + 1);
         end if;
         if J < LB then
            Cur (P) := SB (J + 1);
            Interleave (I, J + 1, P + 1);
         end if;
      end Interleave;
   begin
      for MA in 0 .. 2 ** M - 1 loop
         for MB in 0 .. 2 ** N - 1 loop
            LA := 0;
            for I in 1 .. M loop
               if (MA / 2 ** (I - 1)) mod 2 = 1 then
                  LA := LA + 1;
                  SA (LA) := A (I);
               end if;
            end loop;
            LB := 0;
            for I in 1 .. N loop
               if (MB / 2 ** (I - 1)) mod 2 = 1 then
                  LB := LB + 1;
                  SB (LB) := B (I);
               end if;
            end loop;
            if LA + LB = K then
               Interleave (0, 0, 1);
            end if;
         end loop;
      end loop;
      return Best;
   end Reference;

   procedure Run (A : Digit_Array; M : Length_Type; B : Digit_Array; N : Length_Type; K : Result_Length;
                  Tag : String) is
      R    : constant Result_Array := Max_Number (A, M, B, N, K);
      Want : constant Seq := (if K = 0 then [others => -1] else Reference (A, M, B, N, K));
      Ok   : Boolean := True;
   begin
      for I in 1 .. K loop
         Ok := Ok and then R (I) = Want (I);
      end loop;
      Check (Ok, Tag & " M =" & M'Image & " N =" & N'Image & " K =" & K'Image);
   end Run;

   A, B : Digit_Array := [others => 0];
begin
   --  LeetCode 321 examples
   A (1 .. 4) := [3, 4, 6, 5];
   B (1 .. 6) := [9, 1, 2, 5, 8, 3];
   declare
      R : constant Result_Array := Max_Number (A, 4, B, 6, 5);
   begin
      Check (R (1 .. 5) = [9, 8, 6, 5, 3], "example 1");
   end;
   A (1 .. 2) := [6, 7];
   B (1 .. 3) := [6, 0, 4];
   declare
      R : constant Result_Array := Max_Number (A, 2, B, 3, 5);
   begin
      Check (R (1 .. 5) = [6, 7, 6, 0, 4], "example 2");
   end;
   A (1 .. 2) := [3, 9];
   B (1 .. 2) := [8, 9];
   declare
      R : constant Result_Array := Max_Number (A, 2, B, 2, 3);
   begin
      Check (R (1 .. 3) = [9, 8, 9], "example 3");
   end;
   --  exhaustive on {0, 1}
   for M in 0 .. 3 loop
      for N in 0 .. 3 loop
         for CA in 0 .. 2 ** M - 1 loop
            for CB in 0 .. 2 ** N - 1 loop
               for I in 1 .. M loop
                  A (I) := (CA / 2 ** (I - 1)) mod 2;
               end loop;
               for I in 1 .. N loop
                  B (I) := (CB / 2 ** (I - 1)) mod 2;
               end loop;
               for K in 0 .. M + N loop
                  Run (A, M, B, N, K, "exhaustive");
               end loop;
            end loop;
         end loop;
      end loop;
   end loop;
   for T in 1 .. 3_000 loop
      declare
         M : constant Length_Type := Rand (6);
         N : constant Length_Type := Rand (6);
         D : constant Positive := (if Rand (2) = 0 then 10 else 3);
      begin
         for I in 1 .. M loop
            A (I) := Rand (D);
         end loop;
         for I in 1 .. N loop
            B (I) := Rand (D);
         end loop;
         Run (A, M, B, N, Rand (M + N + 1), "random" & T'Image);
      end;
   end loop;
   --  full size runs (no reference, must not fail)
   for I in Index loop
      A (I) := Rand (10);
      B (I) := Rand (10);
   end loop;
   declare
      R : constant Result_Array := Max_Number (A, 32, B, 32, 64);
   begin
      Check (R'Length = 64, "full size");
   end;
   if Fails = 0 then
      Put_Line ("PASS Create_Maximum_Number own checks:" & Cases'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
