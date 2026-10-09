with Ada.Text_IO; use Ada.Text_IO;
with Binomial_Coefficient; use Binomial_Coefficient;
with Own_Checks;

procedure Tests is
   procedure Check (N, K : Input; Want : Result) is
   begin
      if Choose (N, K) /= Want then
         raise Program_Error with "Choose (" & N'Image & "," & K'Image & ") =" & Choose (N, K)'Image
           & ", expected" & Want'Image;
      end if;
   end Check;
begin
   Check (5, 2, 10);
   Check (10, 5, 252);
   Check (4, 8, 0);
   --  Beyond the old table (N <= 10), worked by the multiplicative formula
   --  C (n, k) = n (n - 1) .. (n - k + 1) / k!:
   --    C (11, 3) = 11 * 10 * 9 / 6 = 165
   --    C (20, 10) = 184_756
   --    C (30, 15) = 155_117_520, the largest value for N <= 30
   --    C (30, 1) = 30, C (30, 30) = 1, C (12, 13) = 0
   Check (11, 3, 165);
   Check (20, 10, 184_756);
   Check (30, 15, 155_117_520);
   Check (30, 1, 30);
   Check (30, 30, 1);
   Check (12, 13, 0);
   --  The top of the range: C (33, 16) = C (33, 17) = 1_166_803_110 is the
   --  largest value for N <= 33 and still fits Natural; C (34, 17) =
   --  2_333_606_220 would not (see the package comment).
   Check (33, 16, 1_166_803_110);
   Check (33, 17, 1_166_803_110);
   Check (33, 0, 1);
   Check (33, 33, 1);
   --  All of row 33 against the multiplicative formula in Long_Long_Integer
   --  (every partial product C (33 - K + I, I) * (next factor) < 2 ** 63),
   --  and every entry <= Natural'Last.
   declare
      C : Long_Long_Integer := 1;
   begin
      for K in 0 .. 33 loop
         if K > 0 then
            C := C * Long_Long_Integer (33 - K + 1) / Long_Long_Integer (K);
         end if;
         if Long_Long_Integer (Choose (33, K)) /= C or else C > Long_Long_Integer (Natural'Last) then
            raise Program_Error with "row 33, K =" & K'Image & ": got" & Choose (33, K)'Image
              & ", formula" & C'Image;
         end if;
      end loop;
   end;
   Own_Checks;
   Put_Line ("binomial checks passed");
end Tests;
