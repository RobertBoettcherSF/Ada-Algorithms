pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Numerics.Long_Elementary_Functions; use Ada.Numerics.Long_Elementary_Functions;
with Sigmoid; use Sigmoid;

--  Expected values: see tests/SOURCES.txt.
procedure Tests is
   Failures : Natural := 0;
   Checks   : Natural := 0;

   procedure Check (Ok : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not Ok then
         Failures := Failures + 1;
         Put_Line ("FAIL " & Label);
      end if;
   end Check;

   procedure Is_Value (X_Milli : Integer; Expected : Probability) is
      Got : constant Probability := Percent (X_Milli);
   begin
      Check (Got = Expected, "Percent (" & X_Milli'Image & ") =" & Got'Image & ", expected" & Expected'Image);
   end Is_Value;
begin
   --  Worked values (60-digit decimal reference, tests/SOURCES.txt).
   Is_Value (0, 50);
   Is_Value (19, 50);
   Is_Value (20, 50);          --  100 s = 50.49998...
   Is_Value (21, 51);          --  100 s = 50.52498...
   Is_Value (-19, 50);
   Is_Value (-20, 50);         --  49.50001...
   Is_Value (-21, 49);
   Is_Value (500, 62);
   Is_Value (-500, 38);
   Is_Value (1_000, 73);
   Is_Value (-1_000, 27);
   Is_Value (2_197, 90);       --  89.99797...
   Is_Value (-2_197, 10);
   Is_Value (-2_500, 8);
   Is_Value (3_892, 98);       --  98.00035...
   Is_Value (4_000, 98);
   Is_Value (-4_000, 2);
   Is_Value (4_594, 99);
   Is_Value (5_293, 99);       --  99.49984...
   Is_Value (5_294, 100);      --  99.50034...
   Is_Value (-5_293, 1);
   Is_Value (-5_294, 0);
   Is_Value (6_000, 100);
   Is_Value (-6_000, 0);
   Is_Value (Integer'Last, 100);
   Is_Value (Integer'First, 0);

   --  The old whole-number interface, unchanged values (the old table was
   --  right for -4 .. 4), now over its full range.
   Check (Evaluate (-4) = 2 and then Evaluate (-1) = 27 and then Evaluate (0) = 50
          and then Evaluate (3) = 95 and then Evaluate (4) = 98, "Evaluate on -4 .. 4");
   Check (Evaluate (Input'First) = 0 and then Evaluate (Input'Last) = 100 and then Evaluate (5) = 99
          and then Evaluate (6) = 100 and then Evaluate (-5) = 1, "Evaluate beyond -4 .. 4");

   --  Every X_Milli in -8_000 .. 8_000 (past both ends of the rounding
   --  range, |x| > ln 199): agrees with round (100 / (1 + exp (-x))) in
   --  Long_Float, whose error is far below the smallest distance of any of
   --  these values from a rounding boundary (1.67e-5 at |x| = 0.020);
   --  symmetry and monotonicity.
   declare
      Bad, Asym, Down : Natural := 0;
      Prev : Probability := 0;
   begin
      for X in -8_000 .. 8_000 loop
         declare
            V   : constant Long_Float := 100.0 / (1.0 + Exp (-Long_Float (X) / 1000.0));
            Ref : constant Integer := Integer (Long_Float'Floor (V + 0.5));
            P   : constant Probability := Percent (X);
         begin
            if P /= Ref then Bad := Bad + 1; end if;
            if P + Percent (-X) /= 100 then Asym := Asym + 1; end if;
            if X > -8_000 and then P < Prev then Down := Down + 1; end if;
            Prev := P;
         end;
      end loop;
      Check (Bad = 0, "-8000 .. 8000 vs Long_Float:" & Bad'Image & " differ");
      Check (Asym = 0, "-8000 .. 8000 symmetry:" & Asym'Image & " fail");
      Check (Down = 0, "-8000 .. 8000 nondecreasing:" & Down'Image & " fail");
   end;

   if Failures = 0 then
      Put_Line ("PASS Sigmoid (" & Checks'Image & " checks)");
   else
      Put_Line ("FAIL Sigmoid:" & Failures'Image & " of" & Checks'Image);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
