with Ada.Text_IO;
with Ada.Assertions;
with Letter_Combinations_Of_A_Phone_Number; use Letter_Combinations_Of_A_Phone_Number;
with Own_Checks;

procedure Tests is
   --  Keypad: 2 abc, 3 def, 4 ghi, 5 jkl, 6 mno, 7 pqrs, 8 tuv, 9 wxyz.
   --  Combination (N, K) is the K-th spelling (from 0) in dictionary order.
   procedure Check_Count (N : Digit_String; Want : Positive) is
   begin
      if Count (N) /= Want then
         raise Program_Error with "Count (""" & N & """) =" & Count (N)'Image & ", expected" & Want'Image;
      end if;
   end Check_Count;

   procedure Check (N : Digit_String; K : Natural; Want : String) is
      Got : constant String := Combination (N, K);
   begin
      if Got /= Want then
         raise Program_Error with "Combination (""" & N & """," & K'Image & ") = """ & Got & """, expected """ & Want & """";
      end if;
   end Check;

   Twos : constant String (1 .. 12) := [others => '2'];
   Sevens : constant String (1 .. 15) := [others => '7'];
   Nines : constant String (1 .. 15) := [others => '9'];
   Rejected : Natural := 0;

   procedure Expect_Rejected (Bad : String) is
   begin
      declare
         N : constant Digit_String := Bad;
      begin
         Ada.Text_IO.Put_Line ("accepted" & N'Length'Image);
      end;
   exception
      when Ada.Assertions.Assertion_Error => Rejected := Rejected + 1;
   end Expect_Rejected;
begin
   --  The old table's answers: twelve digits of three letters each.
   Check_Count ("", 1);
   Check_Count (Twos (1 .. 4), 81);
   Check_Count (Twos, 531_441);

   --  "23": ad ae af bd be bf cd ce cf.
   Check_Count ("23", 9);
   declare
      All_23 : constant array (0 .. 8) of String (1 .. 2) :=
        ["ad", "ae", "af", "bd", "be", "bf", "cd", "ce", "cf"];
   begin
      for K in All_23'Range loop
         Check ("23", K, All_23 (K));
      end loop;
   end;
   Check ("", 0, "");

   --  7 and 9 have four letters.
   Check_Count ("7", 4);
   Check_Count ("9", 4);
   Check ("7", 3, "s");
   Check ("9", 0, "w");
   Check_Count ("79", 16);
   Check ("79", 5, "qx");          --  5 = 1 * 4 + 1
   Check_Count ("27", 12);
   Check ("27", 7, "bs");          --  7 = 1 * 4 + 3
   Check_Count ("234", 27);
   Check ("234", 13, "beh");       --  13 = 1 * 9 + 1 * 3 + 1
   Check ("234", 26, "cfi");
   Check_Count ("2345678", 2_916); --  3 ** 6 * 4

   --  The limit: fifteen four-letter digits spell 4 ** 15 = 2 ** 30 strings.
   Check_Count (Sevens, 1_073_741_824);
   Check_Count (Nines, 1_073_741_824);
   Check (Sevens, 0, "ppppppppppppppp");
   Check (Nines, 1_073_741_823, "zzzzzzzzzzzzzzz");
   Check (Nines, 1, "wwwwwwwwwwwwwwx");
   Check (Nines, 4, "wwwwwwwwwwwwwxw");

   --  0 and 1 carry no letters, and 16 digits could overflow: both are
   --  outside Digit_String.
   Expect_Rejected ("21");
   Expect_Rejected ("0");
   Expect_Rejected ("2345678923456789");
   if Rejected /= 3 then
      raise Program_Error with "Digit_String accepted a bad number";
   end if;
   Own_Checks;
   Ada.Text_IO.Put_Line ("letter combinations tests passed");
end Tests;
