with Ada.Text_IO; use Ada.Text_IO;
with Binomial_Coefficient; use Binomial_Coefficient;

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
   Put_Line ("binomial checks passed");
end Tests;
