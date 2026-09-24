--  Standalone test suite for Daitch_Mokotoff_Soundex (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Daitch_Mokotoff_Soundex; use Daitch_Mokotoff_Soundex;

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
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Prim (Name : String) return Code_String is
     (Primary_Encode (Name));

   function Match (A, B : String) return Boolean is
     (Codes_Match (A, B));

   function Enc_Raises (Name : String) return Boolean is
      procedure Attempt is
         Unused : constant Code_List := Encode (Name);
      begin
         pragma Unreferenced (Unused);
      end Attempt;
   begin
      Attempt;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Enc_Raises;

   function Prim_Raises (Name : String) return Boolean is
      procedure Attempt is
         Unused : constant Code_String := Primary_Encode (Name);
      begin
         pragma Unreferenced (Unused);
      end Attempt;
   begin
      Attempt;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Prim_Raises;

   function Match_Raises (A, B : String) return Boolean is
      procedure Attempt is
         Unused : constant Boolean := Codes_Match (A, B);
      begin
         pragma Unreferenced (Unused);
      end Attempt;
   begin
      Attempt;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Match_Raises;

   function Make_Same (L : Natural; C : Character) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := C;
      end loop;
      return R;
   end Make_Same;

   function Make_Alpha (L : Natural) return String is
      R : String (1 .. L);
   begin
      for K in 1 .. L loop
         R (K) := Character'Val
           (Character'Pos ('A') + (K - 1) mod 26);
      end loop;
      return R;
   end Make_Alpha;

   function Join_Codes (Name : String) return String is
      C   : constant Code_List := Encode (Name);
      Acc : String (1 .. C'Length * 7);
      N   : Natural := 0;
   begin
      for I in C'Range loop
         if I > C'First then
            N := N + 1;
            Acc (N) := '|';
         end if;
         for K in 1 .. 6 loop
            N := N + 1;
            Acc (N) := C (I) (K);
         end loop;
      end loop;
      return Acc (1 .. N);
   end Join_Codes;

   function Has_Code (Name : String; Want : Code_String) return Boolean is
      C : constant Code_List := Encode (Name);
   begin
      for I in C'Range loop
         if C (I) = Want then
            return True;
         end if;
      end loop;
      return False;
   end Has_Code;

   function Is_Valid_Code (C : Code_String) return Boolean is
   begin
      for I in C'Range loop
         if C (I) not in '0' .. '9' then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Code;

   procedure Expect_Primary (Name : String; Want : Code_String) is
      Got : constant Code_String := Prim (Name);
   begin
      Check (Got = Want,
             Name & " primary got=[" & Got & "] want=[" & Want & "]");
   end Expect_Primary;

   procedure Expect_All (Name : String; Want : String) is
      Got : constant String := Join_Codes (Name);
   begin
      Check (Got = Want,
             Name & " all got=[" & Got & "] want=[" & Want & "]");
   end Expect_All;

   procedure Expect_Count (Name : String; N : Positive) is
      C : constant Code_List := Encode (Name);
   begin
      Check (C'Length = N,
             Name & " count got=" & Natural'Image (C'Length)
             & " want=" & Positive'Image (N));
   end Expect_Count;

   --  Non-static wrappers avoid -gnatwa constant-condition warnings.
   function B (X : Boolean) return Boolean is (X);
   function N_Pos (X : Positive) return Positive is (X);

begin
   Section ("Constants");
   Check (B (N_Pos (Max_Len) = 10_000), "Max_Len");
   Check (B (N_Pos (Code_Length) = 6), "Code_Length");
   Check (B (N_Pos (Max_Codes) = 16), "Max_Codes");

   Section ("JewishGen / Commons basic (single code)");
   Expect_Primary ("GOLDEN", "583600");
   Expect_All ("GOLDEN", "583600");
   Expect_Primary ("Alpert", "087930");
   Expect_Primary ("Breuer", "791900");
   Expect_Primary ("Haber", "579000");
   Expect_Primary ("Mannheim", "665600");
   Expect_Primary ("Mintz", "664000");
   Expect_Primary ("Topf", "370000");
   Expect_Primary ("Kleinmann", "586660");
   Expect_Primary ("Ben Aron", "769600");
   Expect_Primary ("LIPSHITZ", "874400");
   Expect_Primary ("LEWINSKY", "876450");
   Expect_Primary ("LEVINSKI", "876450");
   Expect_Primary ("SZLAMAWICZ", "486740");
   Expect_Primary ("SHLAMOVITZ", "486740");
   Expect_Primary ("Tsenyuv", "467000");
   Expect_Primary ("Golubitsa", "587400");
   Expect_Primary ("Pshemeshil", "746480");
   Expect_Primary ("Washington", "746536");
   Expect_Primary ("KINGSMITH", "565463");
   Expect_Primary ("AKSSOL", "054800");

   Section ("Wikipedia / Commons branching examples");
   Expect_All ("Peters", "734000|739400");
   Expect_Primary ("Peters", "734000");
   Expect_All ("Peterson", "734600|739460");
   Expect_Primary ("Peterson", "734600");
   Expect_All ("Moskowitz", "645740");
   Expect_All ("Moskovitz", "645740");
   Expect_All ("AUERBACH", "097400|097500");
   Expect_Primary ("AUERBACH", "097400");
   Expect_All ("OHRBACH", "097400|097500");
   Expect_All ("Uhrbach", "097400|097500");
   Expect_All ("Jackson", "154600|145460|454600|445460");
   Expect_Primary ("Jackson", "154600");
   Expect_All ("LIPPSZYC", "874400|874500");
   Expect_All ("Ceniow", "467000|567000");
   Expect_All ("Holubica", "587400|587500");
   Expect_All ("Przemysl", "746480|794648");
   Expect_All ("GERSCHFELD", "547830|545783|594783|594578");
   Expect_All
     ("Jackson-Jackson",
      "154654|154645|154644|145465|145464|"
      & "454654|454645|454644|445465|445464");
   Expect_Count ("Jackson", 4);
   Expect_Count ("Peters", 2);
   Expect_Count ("Moskowitz", 1);
   Expect_Count ("Jackson-Jackson", 10);

   Section ("Codes_Match (any-vs-any)");
   --  Peters 734000|739400 vs Peterson 734600|739460 — no shared code
   Check (not Match ("Peters", "Peterson"), "Peters not match Peterson");
   Check (Match ("Moskowitz", "Moskovitz"), "Moskowitz=Moskovitz");
   Check (Match ("AUERBACH", "OHRBACH"), "Auerbach~Ohrbach");
   Check (Match ("AUERBACH", "Uhrbach"), "Auerbach~Uhrbach");
   Check (Match ("LIPSHITZ", "LIPPSZYC"), "Lipshitz~Lippszyc via 874400");
   Check (Match ("LEWINSKY", "LEVINSKI"), "Lewinsky=Levinski");
   Check (Match ("SZLAMAWICZ", "SHLAMOVITZ"), "Szlamawicz=Shlamovitz");
   Check (Match ("Ceniow", "Tsenyuv"), "Ceniow~Tsenyuv via 467000");
   Check (Match ("Holubica", "Golubitsa"), "Holubica~Golubitsa");
   Check (Match ("Przemysl", "Pshemeshil"), "Przemysl~Pshemeshil");
   Check (Match ("Jackson", "Jackson"), "Jackson self");
   Check (not Match ("GOLDEN", "Alpert"), "Golden not Alpert");
   Check (Match ("peters", "PETERS"), "case insensitive match");

   Section ("Primary equals first Encode code");
   declare
      procedure One (N : String) is
         C : constant Code_List := Encode (N);
      begin
         Check (Prim (N) = C (C'First), N & " primary=Encode(1)");
      end One;
   begin
      One ("Peters");
      One ("Jackson");
      One ("AUERBACH");
      One ("GOLDEN");
      One ("Kleinmann");
      One ("Washington");
   end;

   Section ("Padding and code shape");
   Check (Is_Valid_Code (Prim ("A")), "A valid digits");
   Expect_Primary ("A", "000000");
   Expect_Primary ("B", "700000");
   Expect_Primary ("R", "900000");
   Expect_Primary ("L", "800000");
   Expect_Primary ("M", "600000");
   Check (Prim ("GOLDEN") (5 .. 6) = "00", "GOLDEN padded");
   Check (Has_Code ("Peters", "734000"), "Peters has 734000");
   Check (Has_Code ("Peters", "739400"), "Peters has 739400");
   Check (not Has_Code ("Peters", "000000"), "Peters no zero code");

   Section ("Adjacent-code collapse and MN/NM");
   Expect_Primary ("Topf", "370000");
   Expect_Primary ("Kleinmann", "586660");
   Expect_Primary ("AKSSOL", "054800");
   Expect_Primary ("Mintz", "664000");

   Section ("Multi-word / punctuation / case");
   Expect_Primary ("Ben Aron", "769600");
   Expect_Primary ("benaron", "769600");
   Expect_Primary ("BEN-ARON", "769600");
   Expect_Primary ("O'Brien", "079600");
   Expect_Primary ("OBrien", "079600");
   Expect_Primary ("  Washington  ", "746536");
   Expect_Primary ("king-smith", "565463");
   Expect_All ("JacksonJackson", Join_Codes ("Jackson-Jackson"));
   Expect_All ("Jackson$Jackson", Join_Codes ("Jackson-Jackson"));
   Expect_All ("Jackson_Jackson", Join_Codes ("Jackson-Jackson"));
   Check (Prim ("peters") = Prim ("PETERS"), "case fold primary");
   Check (Join_Codes ("peters") = Join_Codes ("PeTeRs"), "case fold all");

   Section ("Vowels / H / start-of-name");
   Expect_Primary ("Alpert", "087930");
   Expect_Primary ("Haber", "579000");
   Expect_Primary ("Mannheim", "665600");
   Expect_Primary ("Breuer", "791900");
   --  Freud: EU before consonant is NC for second part; F R D
   Expect_Primary ("Freud", "793000");

   Section ("N-gram longest match");
   Expect_Primary ("Mintz", "664000");  -- MIN-TZ not MIN-T-Z
   Expect_Primary ("LIPSHITZ", "874400");
   Expect_Primary ("SCHMIDT", Join_Codes ("SCHMIDT") (1 .. 6));
   declare
      S : constant Code_String := Prim ("SCHMIDT");
   begin
      Check (Is_Valid_Code (S), "SCHMIDT valid");
      Check (S (1) = '4', "SCHMIDT starts with SCH=4");
   end;

   Section ("Branch letter C / CH / J / RS");
   Check (Has_Code ("Ceniow", "467000"), "Ceniow C->4");
   Check (Has_Code ("Ceniow", "567000"), "Ceniow C->5");
   Check (Has_Code ("Jackson", "154600"), "Jackson J->1");
   Check (Has_Code ("Jackson", "454600"), "Jackson J->4");
   Check (Has_Code ("Peters", "734000"), "Peters RS->4");
   Check (Has_Code ("Peters", "739400"), "Peters RS->94");

   Section ("Invalid_Argument");
   Check (Enc_Raises (""), "Encode empty");
   Check (Prim_Raises (""), "Primary empty");
   Check (Enc_Raises ("12345"), "Encode digits only");
   Check (Enc_Raises ("---"), "Encode punct only");
   Check (Enc_Raises ("   "), "Encode spaces only");
   Check (Enc_Raises (Make_Same (Max_Len + 1, 'A')), "Encode over Max_Len");
   Check (Prim_Raises (Make_Same (Max_Len + 1, 'B')), "Primary over Max_Len");
   Check (Match_Raises ("", "A"), "Match empty left");
   Check (Match_Raises ("A", ""), "Match empty right");
   Check (Match_Raises ("123", "A"), "Match letter-free left");
   Check (not Enc_Raises ("A"), "Encode A ok");
   Check (not Enc_Raises (Make_Same (Max_Len, 'A')), "Encode Max_Len ok");
   Check (not Enc_Raises (Make_Alpha (100)), "Encode alpha 100 ok");

   Section ("Non-1 'First slice");
   declare
      Full : constant String := "xxPetersyy";
      Sub  : String renames Full (3 .. 8);
   begin
      Check (Prim (Sub) = "734000", "slice Peters primary");
      Check (Join_Codes (Sub) = "734000|739400", "slice Peters all");
   end;

   Section ("All codes length-6 digits");
   declare
      procedure One (N : String) is
         C : constant Code_List := Encode (N);
      begin
         Check (C'Length >= 1, N & " non-empty list");
         Check (C'Length <= Max_Codes, N & " within Max_Codes");
         for J in C'Range loop
            Check (Is_Valid_Code (C (J)), N & " code digits " & C (J));
         end loop;
      end One;
   begin
      One ("Peters");
      One ("Jackson");
      One ("AUERBACH");
      One ("GERSCHFELD");
      One ("Rosochowaciec");
      One ("Kleinmann");
   end;

   Section ("Avotaynu Rosochowaciec branches");
   Expect_All
     ("Rosochowaciec",
      "944744|944745|944754|944755|945744|945745|945754|945755");
   Expect_Primary ("Rosokhovatsets", "945744");
   Check (Match ("Rosochowaciec", "Rosokhovatsets"),
          "Rosochowaciec~Rosokhovatsets");

   Section ("Accent folding (Latin-1)");
   Expect_Primary ("Strasburg", "294795");
   --  Straßburg: ß folds to s
   declare
      Sharp_S : constant Character := Character'Val (16#DF#);
      Name    : constant String := "Stra" & Sharp_S & "burg";
   begin
      Expect_Primary (Name, "294795");
      Check (Match (Name, "Strasburg"), "ß folds to s");
   end;
   declare
      E_Acute : constant Character := Character'Val (16#C9#);  -- É
      Name    : constant String := E_Acute & "regon";
   begin
      Expect_Primary (Name, "095600");
      Check (Match (Name, "Eregon"), "É folds to E");
   end;

   Section ("Idempotent primary / list stability");
   Check (Prim ("Peters") = Prim ("Peters"), "primary stable");
   Check (Join_Codes ("Jackson") = Join_Codes ("Jackson"), "list stable");
   Check (Encode ("A") (1) = Primary_Encode ("A"), "Encode(1)=Primary A");

   Section ("More surname pairs");
   Expect_Primary ("OHRBACH", "097400");
   Expect_Primary ("Uhrbach", "097400");
   Check (Has_Code ("AUERBACH", "097500"), "Auerbach has 097500");
   Check (Has_Code ("OHRBACH", "097500"), "Ohrbach has 097500");
   Expect_Primary ("Moskowitz", "645740");
   Expect_Primary ("Moskovitz", "645740");

   Section ("Short names and vowel-only");
   Expect_Primary ("I", "000000");
   Expect_Primary ("O", "000000");
   Expect_Primary ("Ea", "000000");
   Expect_Primary ("Eu", "100000");  -- EU at start -> 1
   Expect_Primary ("Ai", "000000");  -- AI at start -> 0
   Expect_Count ("Eu", 1);

   Section ("Extra encodings and cross-checks");
   Expect_Primary ("Schmidt", Prim ("SCHMIDT"));
   Expect_Primary ("SCHMIDT", Prim ("Schmidt"));
   Check (Prim ("Cherkassy") /= "495440", "Cherkassy not uncollapsed");
   --  Cherkassy: adjacent S collapse → 495400 (JewishGen rule 6)
   Expect_Primary ("Cherkassy", "495400");
   Expect_Primary ("Manheim", "665600");  -- H before vowel
   Expect_Primary ("Ohrbach", "097400");
   Check (Has_Code ("Jackson", "145460"), "Jackson 145460");
   Check (Has_Code ("Jackson", "445460"), "Jackson 445460");
   Check (not Match ("Peters", "GOLDEN"), "Peters not Golden");
   Check (Match ("AUERBACH", "auerbach"), "case match Auerbach");
   Check (Prim ("W") = "700000", "W=7");
   Check (Prim ("V") = "700000", "V=7");
   Check (Prim ("F") = "700000", "F=7");
   Check (Prim ("P") = "700000", "P=7");
   Check (Prim ("X") = "500000", "X at start=5");
   Check (Prim ("Z") = "400000", "Z=4");
   Check (Prim ("S") = "400000", "S=4");
   Check (Prim ("T") = "300000", "T=3");
   Check (Prim ("D") = "300000", "D=3");
   Check (Prim ("G") = "500000", "G=5");
   Check (Prim ("K") = "500000", "K=5");
   Check (Prim ("Q") = "500000", "Q=5");
   Check (Encode ("Jackson")'Length = 4, "Jackson 4 codes");
   Check (Encode ("AUERBACH")'Length = 2, "Auerbach 2 codes");
   Check (Encode ("GERSCHFELD")'Length = 4, "Gerschfeld 4 codes");
   Check (not Enc_Raises ("A1B2C3"), "mixed alnum ok");
   Expect_Primary ("A1B2C3", Prim ("ABC"));
   Check (Prim ("ABC") = Prim ("A B C"), "spaces ignored");
   Check (Match ("Ben Aron", "Benaron"), "Ben Aron = Benaron");
   Check (Prim ("PH") = "700000", "PH=7");
   Check (Prim ("TS") = "400000", "TS=4");
   Check (Prim ("TZ") = "400000", "TZ=4");
   Check (Prim ("SH") = "400000", "SH=4");
   Check (Prim ("SCH") = "400000", "SCH=4");
   Check (Prim ("CK") = "500000", "CK primary=5");
   Check (Has_Code ("CK", "450000") or Has_Code ("CK", "500000"),
          "CK branches 5|45");
   Check (Has_Code ("CK", "500000"), "CK has 500000");
   Check (Has_Code ("CK", "450000"), "CK has 450000");

   Section ("Hyphen variants same as concatenated");
   Check (Join_Codes ("Jackson-Jackson")
            = Join_Codes ("JacksonJackson"), "hyphen strip");
   Check (Prim ("KING-SMITH") = Prim ("KINGSMITH"), "KING-SMITH");

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed :" & Natural'Image (Pass_Count));
   Put_Line ("Failed :" & Natural'Image (Fail_Count));
   Put_Line ("Total  :" & Natural'Image (Pass_Count + Fail_Count));
   if Fail_Count = 0 then
      Put_Line ("ALL PASS");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILURES");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
