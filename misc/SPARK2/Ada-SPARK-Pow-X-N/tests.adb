pragma Ada_2022;
with Ada.Text_IO;
with Pow_X_N; use Pow_X_N;

procedure Tests is
   procedure Gives (X : Integer; N : Natural; Want : Integer) is
      R  : Integer;
      Ok : Boolean;
   begin
      Power (X, N, R, Ok);
      if not Ok or else R /= Want then
         raise Program_Error with "Power" & X'Image & N'Image & ": got" & R'Image & " ok " & Ok'Image
           & ", expected" & Want'Image;
      end if;
   end Gives;

   procedure Overflows (X : Integer; N : Natural) is
      R  : Integer;
      Ok : Boolean;
   begin
      Power (X, N, R, Ok);
      if Ok or else R /= 0 then
         raise Program_Error with "Power" & X'Image & N'Image & " should overflow, got" & R'Image;
      end if;
   end Overflows;

   type Row is array (0 .. 5) of Integer;
   --  The old table (X in -2 .. 2, N in 0 .. 5), worked by hand.
   Old : constant array (-2 .. 2) of Row :=
     [[1, -2, 4, -8, 16, -32], [1, -1, 1, -1, 1, -1], [1, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1], [1, 2, 4, 8, 16, 32]];
begin
   for X in Old'Range loop
      for N in Row'Range loop
         Gives (X, N, Old (X) (N));
      end loop;
   end loop;

   --  Bases 0, 1, -1 with any exponent (Natural'Last is odd).
   Gives (0, 0, 1);
   Gives (0, 7, 0);
   Gives (0, Natural'Last, 0);
   Gives (1, Natural'Last, 1);
   Gives (-1, Natural'Last, -1);
   Gives (-1, Natural'Last - 1, 1);

   --  Around the top of Integer: 2 ** 30 = 1_073_741_824 fits, 2 ** 31 does
   --  not; (-2) ** 31 = Integer'First fits, (-2) ** 32 does not.
   Gives (2, 30, 1_073_741_824);
   Overflows (2, 31);
   Gives (-2, 31, Integer'First);
   Overflows (-2, 32);
   Overflows (2, Natural'Last);
   Overflows (-2, Natural'Last);

   --  46_340 ** 2 = 2_147_395_600 fits, 46_341 ** 2 = 2_147_488_281 does not.
   Gives (46_340, 2, 2_147_395_600);
   Gives (-46_340, 2, 2_147_395_600);
   Overflows (46_341, 2);
   Overflows (-46_341, 2);

   --  1_290 ** 3 = 2_146_689_000 fits, 1_291 ** 3 = 2_151_685_171 does not.
   Gives (1_290, 3, 2_146_689_000);
   Gives (-1_290, 3, -2_146_689_000);
   Overflows (1_291, 3);
   Overflows (-1_291, 3);

   --  3 ** 19 = 1_162_261_467 fits, 3 ** 20 = 3_486_784_401 does not;
   --  7 ** 11 = 1_977_326_743 fits, 7 ** 12 = 13_841_287_201 does not.
   Gives (3, 19, 1_162_261_467);
   Gives (-3, 19, -1_162_261_467);
   Overflows (3, 20);
   Gives (7, 11, 1_977_326_743);
   Overflows (7, 12);

   --  The extremes of Integer.
   Gives (Integer'Last, 1, Integer'Last);
   Gives (Integer'First, 1, Integer'First);
   Gives (Integer'First, 0, 1);
   Overflows (Integer'First, 2);
   Overflows (Integer'Last, 2);
   Overflows (Integer'Last, Natural'Last);

   Ada.Text_IO.Put_Line ("pow_x_n tests passed");
end Tests;
