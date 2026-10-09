with Ada.Text_IO;
with Paint_Fence_Lite; use Paint_Fence_Lite;

procedure Tests is
   --  N posts, K colours, no three adjacent posts of one colour, mod M.
   procedure Check (N : Number_Of_Posts; K : Colours; M : Modulus; Want : Natural) is
      Got : constant Natural := Count (N, K, M);
   begin
      if Got /= Want then
         raise Program_Error with "Count (" & N'Image & "," & K'Image & "," & M'Image & ") ="
           & Got'Image & ", expected" & Want'Image;
      end if;
   end Check;
   P31 : constant := 2_147_483_647;
   P   : constant := 1_000_000_007;
   Old : constant array (1 .. 16) of Natural :=
     [2, 4, 6, 10, 16, 26, 42, 68, 110, 178, 288, 466, 754, 1_220, 1_974, 3_194];
begin
   --  The old table (two colours), exact below 2 ** 31 - 1.
   for N in Old'Range loop
      Check (N, 2, P31, Old (N));
   end loop;
   --  Two colours: T (N) = 2 * Fib (N + 1); T (43) = 2 * 701_408_733 is
   --  the last value below 2 ** 31 - 1, T (44) = 2_269_806_340 wraps once.
   Check (43, 2, P31, 1_402_817_466);
   Check (44, 2, P31, 2_269_806_340 - P31);
   --  Three colours by hand: 3, 9, 27 - 3 = 24, 2 * (24 + 9) = 66.
   Check (1, 3, P, 3);
   Check (2, 3, P, 9);
   Check (3, 3, P, 24);
   Check (4, 3, P, 66);
   --  One colour: one or two posts only.
   Check (1, 1, P, 1);
   Check (2, 1, P, 1);
   Check (3, 1, P, 0);
   Check (1_000, 1, P, 0);
   --  Modulus 1, and a single post.
   Check (500, 7, 1, 0);
   Check (1, 12, 5, 2);
   --  K = 100_000: K * K = 10 ** 10 = 9 * P + 999_999_937;
   --  (K - 1) * (K * K + K) = 999_999_999_900_000 = 999_999 * P + 992_900_007.
   Check (2, 100_000, P, 999_999_937);
   Check (3, 100_000, P, 992_900_007);
   --  Large K and N are reduced mod M: K = Positive'Last, M = 2 ** 31 - 1
   --  makes K = 0 (mod M): no colours left.
   Check (1_000, Positive'Last, P31, 0);
   Ada.Text_IO.Put_Line ("paint fence tests passed");
end Tests;
