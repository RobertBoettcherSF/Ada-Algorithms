--  Standalone test suite for Spigot_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Spigot_Algorithm; use Spigot_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   procedure Expect_Invalid_E (N : Natural; Label : String) is
   begin
      declare
         S : constant String := Digits_Of_E (N);
         pragma Unreferenced (S);
      begin
         Check (False, Label & " (no exception)");
      end;
   exception
      when Invalid_Argument =>
         Check (True, Label);
      when others =>
         Check (False, Label & " (wrong exception)");
   end Expect_Invalid_E;

   procedure Expect_Invalid_Pi (N : Natural; Label : String) is
   begin
      declare
         S : constant String := Digits_Of_Pi (N);
         pragma Unreferenced (S);
      begin
         Check (False, Label & " (no exception)");
      end;
   exception
      when Invalid_Argument =>
         Check (True, Label);
      when others =>
         Check (False, Label & " (wrong exception)");
   end Expect_Invalid_Pi;

begin
   Ada.Text_IO.Put_Line ("Spigot_Algorithm test suite");
   Ada.Text_IO.Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Is_Digit_String / term counts");
   ---------------------------------------------------------------------
   Check (Is_Digit_String ("27182", Max_Digits_E), "Is_Digit_String ok");
   Check (not Is_Digit_String ("", Max_Digits_E), "empty rejected");
   Check (not Is_Digit_String ("27a82", Max_Digits_E), "letter rejected");
   Check (not Is_Digit_String ("27182", 3), "over Max rejected");
   Check (E_Term_Count (0) = 0, "E_Term_Count(0)=0");
   Check (E_Term_Count (10) = 10 + E_Term_Guard, "E_Term_Count(10)");
   Check (Pi_Term_Count (0) = 0, "Pi_Term_Count(0)=0");
   Check (Pi_Term_Count (10) = (10 * 10) / 3 + 1, "Pi_Term_Count(10)");
   Check (Pi_Term_Count (5) = 17, "Pi_Term_Count(5)=17");

   ---------------------------------------------------------------------
   Section ("2. Digits_Of_E: N=1 and small N");
   ---------------------------------------------------------------------
   declare
      S1 : constant String := Digits_Of_E (1);
      S2 : constant String := Digits_Of_E (2);
      S5 : constant String := Digits_Of_E (5);
      S10 : constant String := Digits_Of_E (10);
   begin
      Check (S1 = "2", "E(1)=2");
      Check (S1'Length = 1, "E(1) length 1");
      Check (S2 = "27", "E(2)=27");
      Check (S5 = "27182", "E(5)=27182");
      Check (S10 = "2718281828", "E(10)");
      Check (S10'Length = 10, "E(10) length");
      Check (Matches_Known_E (S5), "Matches_Known_E(5)");
      Check (Matches_Known_E (S10), "Matches_Known_E(10)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Digits_Of_E: prefixes vs Known_E_Prefix");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for N in 1 .. Max_Digits_E loop
         declare
            Got : constant String := Digits_Of_E (N);
            Exp : constant String := Known_E_Prefix (N);
         begin
            if Got /= Exp or else Got'Length /= N then
               Ok_All := False;
               Ada.Text_IO.Put_Line
                 ("  mismatch at N=" & N'Image & " got=" & Got);
            end if;
         end;
      end loop;
      Check (Ok_All, "Digits_Of_E matches Known for all N=1..Max_Digits_E");
   end;

   Check (Digits_Of_E (20) = Known_E_Prefix (20), "E(20) spot");
   Check (Digits_Of_E (50) = Known_E_Prefix (50), "E(50) spot");
   Check (Digits_Of_E (80) = Known_E_Prefix (80), "E(80)=Max spot");

   ---------------------------------------------------------------------
   Section ("4. Digits_Of_E_Array");
   ---------------------------------------------------------------------
   declare
      A5  : constant Digit_Array := Digits_Of_E_Array (5);
      A1  : constant Digit_Array := Digits_Of_E_Array (1);
      Ok  : Boolean := True;
   begin
      Check (A1'Length = 1 and then A1 (1) = 2, "E_Array(1)=[2]");
      Check (A5'Length = 5, "E_Array(5) length");
      Check (A5 (1) = 2 and A5 (2) = 7 and A5 (3) = 1
             and A5 (4) = 8 and A5 (5) = 2,
             "E_Array(5)=[2,7,1,8,2]");
      for N in 1 .. 25 loop
         declare
            S : constant String := Digits_Of_E (N);
            A : constant Digit_Array := Digits_Of_E_Array (N);
         begin
            if A'Length /= N then
               Ok := False;
            end if;
            for I in A'Range loop
               if Character'Pos (S (S'First + I - 1)) - Character'Pos ('0')
                 /= Integer (A (I))
               then
                  Ok := False;
               end if;
            end loop;
         end;
      end loop;
      Check (Ok, "E_Array agrees with Digits_Of_E for N=1..25");
   end;

   ---------------------------------------------------------------------
   Section ("5. Digits_Of_Pi: N=1 and small N");
   ---------------------------------------------------------------------
   declare
      S1  : constant String := Digits_Of_Pi (1);
      S2  : constant String := Digits_Of_Pi (2);
      S5  : constant String := Digits_Of_Pi (5);
      S10 : constant String := Digits_Of_Pi (10);
   begin
      Check (S1 = "3", "Pi(1)=3");
      Check (S2 = "31", "Pi(2)=31");
      Check (S5 = "31415", "Pi(5)=31415");
      Check (S10 = "3141592653", "Pi(10)");
      Check (S10'Length = 10, "Pi(10) length");
      Check (Matches_Known_Pi (S5), "Matches_Known_Pi(5)");
      Check (Matches_Known_Pi (S10), "Matches_Known_Pi(10)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Digits_Of_Pi: prefixes vs Known_Pi_Prefix");
   ---------------------------------------------------------------------
   declare
      Ok_All : Boolean := True;
   begin
      for N in 1 .. Max_Digits_Pi loop
         declare
            Got : constant String := Digits_Of_Pi (N);
            Exp : constant String := Known_Pi_Prefix (N);
         begin
            if Got /= Exp or else Got'Length /= N then
               Ok_All := False;
               Ada.Text_IO.Put_Line
                 ("  mismatch at N=" & N'Image & " got=" & Got
                  & " exp=" & Exp);
            end if;
         end;
      end loop;
      Check (Ok_All, "Digits_Of_Pi matches Known for all N=1..Max_Digits_Pi");
   end;

   Check (Digits_Of_Pi (20) = Known_Pi_Prefix (20), "Pi(20) spot");
   Check (Digits_Of_Pi (32) = Known_Pi_Prefix (32), "Pi(32) carry edge");
   Check (Digits_Of_Pi (50) = Known_Pi_Prefix (50), "Pi(50)=Max spot");

   ---------------------------------------------------------------------
   Section ("7. Digits_Of_Pi_Array");
   ---------------------------------------------------------------------
   declare
      A5 : constant Digit_Array := Digits_Of_Pi_Array (5);
      A1 : constant Digit_Array := Digits_Of_Pi_Array (1);
      Ok : Boolean := True;
   begin
      Check (A1'Length = 1 and then A1 (1) = 3, "Pi_Array(1)=[3]");
      Check (A5 (1) = 3 and A5 (2) = 1 and A5 (3) = 4
             and A5 (4) = 1 and A5 (5) = 5,
             "Pi_Array(5)=[3,1,4,1,5]");
      for N in 1 .. 25 loop
         declare
            S : constant String := Digits_Of_Pi (N);
            A : constant Digit_Array := Digits_Of_Pi_Array (N);
         begin
            if A'Length /= N then
               Ok := False;
            end if;
            for I in A'Range loop
               if Character'Pos (S (S'First + I - 1)) - Character'Pos ('0')
                 /= Integer (A (I))
               then
                  Ok := False;
               end if;
            end loop;
         end;
      end loop;
      Check (Ok, "Pi_Array agrees with Digits_Of_Pi for N=1..25");
   end;

   ---------------------------------------------------------------------
   Section ("8. Invalid_Argument / caps");
   ---------------------------------------------------------------------
   Expect_Invalid_E (0, "E(0) raises");
   Expect_Invalid_E (Max_Digits_E + 1, "E(Max+1) raises");
   Expect_Invalid_E (1000, "E(1000) raises");
   Expect_Invalid_Pi (0, "Pi(0) raises");
   Expect_Invalid_Pi (Max_Digits_Pi + 1, "Pi(Max+1) raises");
   Expect_Invalid_Pi (999, "Pi(999) raises");

   declare
      Raised_E : Boolean := False;
      Raised_P : Boolean := False;
   begin
      begin
         declare
            S : constant String := Known_E_Prefix (0);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised_E := True;
      end;
      begin
         declare
            S : constant String := Known_Pi_Prefix (0);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised_P := True;
      end;
      Check (Raised_E, "Known_E_Prefix(0) raises");
      Check (Raised_P, "Known_Pi_Prefix(0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("9. Matches_Known_* negatives");
   ---------------------------------------------------------------------
   Check (not Matches_Known_E (""), "Matches_E empty");
   Check (not Matches_Known_E ("27183"), "Matches_E wrong digit");
   Check (not Matches_Known_E ("3"), "Matches_E pi digit");
   Check (not Matches_Known_Pi (""), "Matches_Pi empty");
   Check (not Matches_Known_Pi ("31416"), "Matches_Pi wrong digit");
   Check (not Matches_Known_Pi ("2"), "Matches_Pi e digit");
   Check (Matches_Known_E ("2"), "Matches_E single");
   Check (Matches_Known_Pi ("3"), "Matches_Pi single");

   ---------------------------------------------------------------------
   Section ("10. Length / stability cross-checks");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
   begin
      for N in 1 .. 40 loop
         if Digits_Of_E (N)'Length /= N then
            Ok := False;
         end if;
         if Digits_Of_Pi (N)'Length /= N then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "result lengths equal N for E(1..40) and Pi(1..40)");
   end;

   --  Longer prefix starts with shorter prefix.
   Check
     (Digits_Of_E (30) (1 .. 10) = Digits_Of_E (10),
      "E(30) prefix = E(10)");
   Check
     (Digits_Of_Pi (40) (1 .. 15) = Digits_Of_Pi (15),
      "Pi(40) prefix = Pi(15)");
   Check
     (Digits_Of_E (Max_Digits_E) (1 .. 5) = "27182",
      "E max starts 27182");
   Check
     (Digits_Of_Pi (Max_Digits_Pi) (1 .. 5) = "31415",
      "Pi max starts 31415");

   --  Caps used consistently by helpers.
   Check
     (E_Term_Count (Max_Digits_E) = Max_Digits_E + E_Term_Guard,
      "E cap and guard compose");
   Check
     (Pi_Term_Count (Max_Digits_Pi) =
      (10 * Max_Digits_Pi) / 3 + 1,
      "Pi cap term formula");
   Check
     (E_Term_Count (7) = 7 + E_Term_Guard
      and then Pi_Term_Count (7 + Pi_Digit_Guard) =
               (10 * (7 + Pi_Digit_Guard)) / 3 + 1,
      "guards appear in term counts");

   ---------------------------------------------------------------------
   Section ("11. Extra spot digits (classroom anchors)");
   ---------------------------------------------------------------------
   Check (Digits_Of_E (15) = "271828182845904", "E(15) anchor");
   Check (Digits_Of_E (25) = "2718281828459045235360287", "E(25) anchor");
   Check (Digits_Of_Pi (15) = "314159265358979", "Pi(15) anchor");
   Check (Digits_Of_Pi (25) = "3141592653589793238462643", "Pi(25) anchor");
   Check (Digits_Of_Pi (6) = "314159", "Pi(6) nines-buffer");
   Check (Digits_Of_Pi (13) = "3141592653589", "Pi(13) nines-buffer");

   --  Array first/last digit checks at larger N.
   declare
      AE : constant Digit_Array := Digits_Of_E_Array (40);
      AP : constant Digit_Array := Digits_Of_Pi_Array (40);
   begin
      Check (AE (1) = 2 and AE (40) = 7, "E_Array(40) ends with …7");
      Check (AP (1) = 3 and AP (40) = 7, "Pi_Array(40) ends with …7");
   end;

   ---------------------------------------------------------------------
   Section ("12. More Invalid / Is_Digit_String edges");
   ---------------------------------------------------------------------
   Check (Is_Digit_String ("0", 1), "digit 0 ok");
   Check (Is_Digit_String ("9", Max_Digits_E), "digit 9 ok");
   Check (not Is_Digit_String ("/", 5), "slash rejected");
   Check (not Is_Digit_String (" 2", 5), "space rejected");

   Expect_Invalid_E (Max_Digits_E + 10, "E(Max+10) raises");
   Expect_Invalid_Pi (Max_Digits_Pi + 10, "Pi(Max+10) raises");

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            S : constant String := Known_E_Prefix (Max_Digits_E + 1);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Known_E_Prefix(Max+1) raises");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            S : constant String := Known_Pi_Prefix (Max_Digits_Pi + 1);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Known_Pi_Prefix(Max+1) raises");
   end;

   --  Term-count monotonicity.
   Check (E_Term_Count (5) < E_Term_Count (6), "E_Term_Count mono");
   Check (Pi_Term_Count (5) < Pi_Term_Count (6), "Pi_Term_Count mono");
   Check
     (E_Term_Count (Max_Digits_E) = Max_Digits_E + E_Term_Guard,
      "E_Term_Count at max");
   Check
     (Pi_Term_Count (Max_Digits_Pi + Pi_Digit_Guard) =
      (10 * (Max_Digits_Pi + Pi_Digit_Guard)) / 3 + 1,
      "Pi_Term_Count at max request");

   ---------------------------------------------------------------------
   Section ("13. Additional prefix / length / oracle checks");
   ---------------------------------------------------------------------
   Check (Digits_Of_E (3) = "271", "E(3)=271");
   Check (Digits_Of_E (4) = "2718", "E(4)=2718");
   Check (Digits_Of_E (6) = "271828", "E(6)");
   Check (Digits_Of_E (7) = "2718281", "E(7)");
   Check (Digits_Of_E (8) = "27182818", "E(8)");
   Check (Digits_Of_E (9) = "271828182", "E(9)");
   Check (Digits_Of_E (12) = Known_E_Prefix (12), "E(12) known");
   Check (Digits_Of_E (16) = Known_E_Prefix (16), "E(16) known");
   Check (Digits_Of_E (35) = Known_E_Prefix (35), "E(35) known");
   Check (Digits_Of_E (60) = Known_E_Prefix (60), "E(60) known");
   Check (Digits_Of_E (79) = Known_E_Prefix (79), "E(79) known");

   Check (Digits_Of_Pi (3) = "314", "Pi(3)=314");
   Check (Digits_Of_Pi (4) = "3141", "Pi(4)");
   Check (Digits_Of_Pi (7) = "3141592", "Pi(7)");
   Check (Digits_Of_Pi (8) = "31415926", "Pi(8)");
   Check (Digits_Of_Pi (9) = "314159265", "Pi(9)");
   Check (Digits_Of_Pi (11) = Known_Pi_Prefix (11), "Pi(11) known");
   Check (Digits_Of_Pi (14) = Known_Pi_Prefix (14), "Pi(14) known");
   Check (Digits_Of_Pi (18) = Known_Pi_Prefix (18), "Pi(18) known");
   Check (Digits_Of_Pi (24) = Known_Pi_Prefix (24), "Pi(24) known");
   Check (Digits_Of_Pi (35) = Known_Pi_Prefix (35), "Pi(35) known");
   Check (Digits_Of_Pi (45) = Known_Pi_Prefix (45), "Pi(45) known");
   Check (Digits_Of_Pi (49) = Known_Pi_Prefix (49), "Pi(49) known");

   Check
     (Digits_Of_E (50) (1 .. 25) = Digits_Of_E (25),
      "E(50) shares E(25) prefix");
   Check
     (Digits_Of_Pi (50) (1 .. 25) = Digits_Of_Pi (25),
      "Pi(50) shares Pi(25) prefix");
   Check
     (Digits_Of_E (80) (1 .. 40) = Digits_Of_E (40),
      "E(80) shares E(40) prefix");

   declare
      AE : constant Digit_Array := Digits_Of_E_Array (10);
      AP : constant Digit_Array := Digits_Of_Pi_Array (10);
      Sum_E : Natural := 0;
      Sum_P : Natural := 0;
   begin
      Check (AE'First = 1 and AE'Last = 10, "E_Array bounds 1..10");
      Check (AP'First = 1 and AP'Last = 10, "Pi_Array bounds 1..10");
      for I in AE'Range loop
         Sum_E := Sum_E + AE (I);
      end loop;
      for I in AP'Range loop
         Sum_P := Sum_P + AP (I);
      end loop;
      --  2+7+1+8+2+8+1+8+2+8 = 47 ; 3+1+4+1+5+9+2+6+5+3 = 39
      Check (Sum_E = 47, "E_Array(10) digit sum");
      Check (Sum_P = 39, "Pi_Array(10) digit sum");
   end;

   Check (Matches_Known_E (Known_E_Prefix (1)), "oracle E self-match 1");
   Check (Matches_Known_E (Known_E_Prefix (40)), "oracle E self-match 40");
   Check (Matches_Known_Pi (Known_Pi_Prefix (1)), "oracle Pi self-match 1");
   Check (Matches_Known_Pi (Known_Pi_Prefix (40)), "oracle Pi self-match 40");
   Check (not Matches_Known_E ("2718281829"), "E(10) last digit wrong");
   Check (not Matches_Known_Pi ("3141592654"), "Pi(10) last digit wrong");

   Check (Is_Digit_String (Digits_Of_E (33), Max_Digits_E),
          "E(33) is digit string");
   Check (Is_Digit_String (Digits_Of_Pi (33), Max_Digits_Pi),
          "Pi(33) is digit string");

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===========================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
