--  Standalone test suite for Soundex (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Soundex; use Soundex;

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

   --  Non-static wrappers avoid -gnatwa constant-condition warnings.
   function B (X : Boolean) return Boolean is (X);

   function Enc (Name : String) return Code_String is
     (Encode (Name));

   function Match (A, B : String) return Boolean is
     (Codes_Match (A, B));

   function Enc_Raises (Name : String) return Boolean is
      Unused : Code_String;
   begin
      Unused := Encode (Name);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Enc_Raises;

   function Match_Raises (A, B : String) return Boolean is
      Unused : Boolean;
   begin
      Unused := Codes_Match (A, B);
      pragma Unreferenced (Unused);
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
         R (K) := Character'Val (Character'Pos ('A') + (K - 1) mod 26);
      end loop;
      return R;
   end Make_Alpha;

   function Is_Valid_Code (C : Code_String) return Boolean is
   begin
      if C'Length /= 4 then
         return False;
      end if;
      if C (1) not in 'A' .. 'Z' then
         return False;
      end if;
      for I in 2 .. 4 loop
         if C (I) not in '0' .. '6' then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Code;

   --  Slice helper with non-1 'First
   function Slice_Name return String is
      Buf : constant String (5 .. 10) := "Robert";
   begin
      return Buf;
   end Slice_Name;

begin
   Put_Line ("Soundex test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);
   Put_Line ("H/W variant: NARA/Wikipedia (H/W non-separating; Ashcraft -> A261)");

   ------------------------------------------------------------------
   Section ("1. Classic surname examples");
   ------------------------------------------------------------------
   Check (Enc ("Robert") = "R163", "Robert -> R163");
   Check (Enc ("Rupert") = "R163", "Rupert -> R163");
   Check (Enc ("Rubin") = "R150", "Rubin -> R150");
   Check (Enc ("Ashcraft") = "A261", "Ashcraft -> A261");
   Check (Enc ("Ashcroft") = "A261", "Ashcroft -> A261");
   Check (Enc ("Tymczak") = "T522", "Tymczak -> T522");
   Check (Enc ("Pfister") = "P236", "Pfister -> P236");
   Check (Enc ("Honeyman") = "H555", "Honeyman -> H555");
   Check (Enc ("Euler") = "E460", "Euler -> E460");
   Check (Enc ("Ellery") = "E460", "Ellery -> E460");
   Check (Enc ("Gauss") = "G200", "Gauss -> G200");
   Check (Enc ("Ghosh") = "G200", "Ghosh -> G200");
   Check (Enc ("Hilbert") = "H416", "Hilbert -> H416");
   Check (Enc ("Heilbronn") = "H416", "Heilbronn -> H416");
   Check (Enc ("Knuth") = "K530", "Knuth -> K530");
   Check (Enc ("Kant") = "K530", "Kant -> K530");
   Check (Enc ("Lloyd") = "L300", "Lloyd -> L300");
   Check (Enc ("Ladd") = "L300", "Ladd -> L300");
   Check (Enc ("Lukasiewicz") = "L222", "Lukasiewicz -> L222");
   Check (Enc ("Lissajous") = "L222", "Lissajous -> L222");
   Check (Enc ("Williams") = "W452", "Williams -> W452");
   Check (Enc ("Baragwanath") = "B625", "Baragwanath -> B625");
   Check (Enc ("Donnell") = "D540", "Donnell -> D540");
   Check (Enc ("Smith") = "S530", "Smith -> S530");
   Check (Enc ("Smyth") = "S530", "Smyth -> S530");
   Check (Enc ("Jackson") = "J250", "Jackson -> J250");
   Check (Enc ("Johnson") = "J525", "Johnson -> J525");
   Check (Enc ("Jones") = "J520", "Jones -> J520");
   Check (Enc ("Bauer") = "B600", "Bauer -> B600");
   Check (Enc ("Wheaton") = "W350", "Wheaton -> W350");
   Check (Enc ("Burroughs") = "B620", "Burroughs -> B620");
   Check (Enc ("Burrows") = "B620", "Burrows -> B620");
   Check (Enc ("O'Hara") = "O600", "O'Hara -> O600 (apostrophe skipped)");
   Check (Enc ("Washington") = "W252", "Washington -> W252");
   Check (Enc ("Lee") = "L000", "Lee -> L000");
   Check (Enc ("Gutierrez") = "G362", "Gutierrez -> G362");
   Check (Enc ("Pfister") = "P236", "Pfister again");
   Check (Enc ("Jackson") = "J250", "Jackson again");

   ------------------------------------------------------------------
   Section ("2. Case folding");
   ------------------------------------------------------------------
   Check (Enc ("robert") = "R163", "lowercase robert");
   Check (Enc ("ROBERT") = "R163", "uppercase ROBERT");
   Check (Enc ("RoBeRt") = "R163", "mixed RoBeRt");
   Check (Enc ("ashcraft") = "A261", "lowercase ashcraft");
   Check (Enc ("ASHCRAFT") = "A261", "uppercase ASHCRAFT");
   Check (Enc ("knuth") = "K530", "lowercase knuth");
   Check (Enc ("smith") = "S530", "lowercase smith");
   Check (Enc ("SMYTH") = "S530", "uppercase SMYTH");
   Check (Enc ("a") = "A000", "single lower a");
   Check (Enc ("A") = "A000", "single upper A");
   Check (Enc ("z") = "Z000", "single lower z");
   Check (Enc ("McDonald") = Enc ("MCDONALD"), "McDonald case fold equal");

   ------------------------------------------------------------------
   Section ("3. Padding and short names");
   ------------------------------------------------------------------
   Check (Enc ("A") = "A000", "A -> A000");
   Check (Enc ("I") = "I000", "I -> I000");
   Check (Enc ("E") = "E000", "E -> E000");
   Check (Enc ("Ai") = "A000", "Ai -> A000");
   Check (Enc ("Ae") = "A000", "Ae -> A000");
   Check (Enc ("Au") = "A000", "Au -> A000");
   Check (Enc ("Ab") = "A100", "Ab -> A100");
   Check (Enc ("Ac") = "A200", "Ac -> A200");
   Check (Enc ("Ad") = "A300", "Ad -> A300");
   Check (Enc ("Al") = "A400", "Al -> A400");
   Check (Enc ("Am") = "A500", "Am -> A500");
   Check (Enc ("Ar") = "A600", "Ar -> A600");
   Check (Enc ("Abe") = "A100", "Abe -> A100");
   Check (Enc ("Ace") = "A200", "Ace -> A200");
   Check (Enc ("Bo") = "B000", "Bo -> B000");
   Check (Enc ("By") = "B000", "By -> B000 (Y dropped)");
   Check (Enc ("Bh") = "B000", "Bh -> B000 (H dropped)");
   Check (Enc ("Bw") = "B000", "Bw -> B000 (W dropped)");

   ------------------------------------------------------------------
   Section ("4. Adjacent duplicates and H/W/Y collapse");
   ------------------------------------------------------------------
   Check (Enc ("Abby") = "A100", "Abby collapses BB");
   Check (Enc ("Ass") = "A200", "Ass collapses SS");
   Check (Enc ("Att") = "A300", "Att collapses TT");
   Check (Enc ("All") = "A400", "All collapses LL");
   Check (Enc ("Ann") = "A500", "Ann collapses NN");
   Check (Enc ("Arr") = "A600", "Arr collapses RR");
   Check (Enc ("Ashcraft") = "A261", "Ashcraft H does not separate");
   Check (Enc ("Ashcroft") = "A261", "Ashcroft H does not separate");
   --  SGH: S=2, G=2 with H between → collapse; vowel between keeps both
   Check (Enc ("Sgher") = "S600", "Sgher: S/G collapse across H, then R");
   Check (Enc ("Sager") = "S260", "Sager: vowel keeps S and G separate");
   Check (Enc ("Tymczak") = "T522", "Tymczak CZ collapse to one 2");
   Check (Enc ("Pfister") = "P236", "Pfister P/F same code skip");
   Check (Enc ("Lloyd") = "L300", "Lloyd LL collapse");
   Check (Enc ("Ladd") = "L300", "Ladd DD collapse");
   Check (Enc ("Gauss") = "G200", "Gauss SS collapse");
   Check (Enc ("Jackson") = "J250", "Jackson CK collapse");

   ------------------------------------------------------------------
   Section ("5. Non-letter stripping");
   ------------------------------------------------------------------
   Check (Enc ("Rob-ert") = "R163", "hyphen Rob-ert");
   Check (Enc ("Rob ert") = "R163", "space Rob ert");
   Check (Enc ("Rob.ert") = "R163", "dot Rob.ert");
   Check (Enc ("R0bert") = "R163", "digit zero inside");
   Check (Enc ("  Robert  ") = "R163", "leading/trailing spaces");
   Check (Enc ("R!o@b#e$r%t") = "R163", "punctuation salad");
   Check (Enc ("123Robert") = "R163", "leading digits");
   Check (Enc ("Robert456") = "R163", "trailing digits");
   Check (Enc ("O''Brien") = "O165", "O''Brien");
   Check (Enc ("Van Helsing") = "V542", "Van Helsing");
   Check (Enc ("D'Angelo") = "D524", "D'Angelo");

   ------------------------------------------------------------------
   Section ("6. Codes_Match");
   ------------------------------------------------------------------
   Check (Match ("Robert", "Rupert"), "Robert matches Rupert");
   Check (Match ("Robert", "robert"), "Robert matches robert");
   Check (Match ("Ashcraft", "Ashcroft"), "Ashcraft matches Ashcroft");
   Check (Match ("Smith", "Smyth"), "Smith matches Smyth");
   Check (Match ("Euler", "Ellery"), "Euler matches Ellery");
   Check (Match ("Gauss", "Ghosh"), "Gauss matches Ghosh");
   Check (Match ("Hilbert", "Heilbronn"), "Hilbert matches Heilbronn");
   Check (Match ("Knuth", "Kant"), "Knuth matches Kant");
   Check (Match ("Lloyd", "Ladd"), "Lloyd matches Ladd");
   Check (Match ("Lukasiewicz", "Lissajous"), "Lukasiewicz matches Lissajous");
   Check (Match ("Burroughs", "Burrows"), "Burroughs matches Burrows");
   Check (not Match ("Robert", "Rubin"), "Robert does not match Rubin");
   Check (not Match ("Smith", "Jones"), "Smith does not match Jones");
   Check (not Match ("Ashcraft", "Robert"), "Ashcraft does not match Robert");
   Check (not Match ("Lee", "Lloyd"), "Lee does not match Lloyd");
   Check (Match ("A", "A"), "A matches A");
   Check (Match ("A", "Ae"), "A matches Ae");
   Check (Match ("Bo", "By"), "Bo matches By");
   Check (Match ("Rob ert", "Robert"), "spaced matches plain");
   Check (Match ("ROBERT", "rupert"), "case-insensitive match");

   ------------------------------------------------------------------
   Section ("7. Invalid_Argument");
   ------------------------------------------------------------------
   Check (Enc_Raises (""), "empty Encode raises");
   Check (Enc_Raises ("123"), "digits-only Encode raises");
   Check (Enc_Raises ("!!!"), "punct-only Encode raises");
   Check (Enc_Raises ("   "), "spaces-only Encode raises");
   Check (Enc_Raises ("'-."), "symbols-only Encode raises");
   Check (Match_Raises ("", "Robert"), "Codes_Match empty A raises");
   Check (Match_Raises ("Robert", ""), "Codes_Match empty B raises");
   Check (Match_Raises ("", ""), "Codes_Match empty/empty raises");
   Check (Match_Raises ("123", "Robert"), "Codes_Match digit-only A raises");
   Check (not Enc_Raises ("A"), "single letter does not raise");
   Check (not Enc_Raises ("Robert"), "Robert does not raise");
   declare
      Over : constant String := Make_Same (Max_Len + 1, 'A');
   begin
      Check (Enc_Raises (Over), "Max_Len+1 Encode raises");
      Check (Match_Raises (Over, "A"), "Max_Len+1 Codes_Match raises");
   end;
   declare
      Exact : constant String := Make_Same (Max_Len, 'A');
   begin
      Check (not Enc_Raises (Exact), "Max_Len exact Encode ok");
      Check (Enc (Exact) = "A000", "Max_Len all-A -> A000");
   end;

   ------------------------------------------------------------------
   Section ("8. Result shape invariants");
   ------------------------------------------------------------------
   Check (Enc ("Robert")'Length = 4, "Robert code length 4");
   Check (Is_Valid_Code (Enc ("Robert")), "Robert valid shape");
   Check (Is_Valid_Code (Enc ("A")), "A valid shape");
   Check (Is_Valid_Code (Enc ("Ashcraft")), "Ashcraft valid shape");
   Check (Is_Valid_Code (Enc ("Pfister")), "Pfister valid shape");
   Check (Is_Valid_Code (Enc ("Tymczak")), "Tymczak valid shape");
   Check (Is_Valid_Code (Enc ("O'Hara")), "O'Hara valid shape");
   Check (Enc ("Robert") (1) in 'A' .. 'Z', "leading letter upper");
   Check (Enc ("robert") (1) = 'R', "leading folded to R");
   Check (Enc ("xyz") (2 .. 4) = "200", "xyz digits");
   Check (Enc ("bcd") (2 .. 4) = "230", "bcd -> B230");

   ------------------------------------------------------------------
   Section ("9. Non-1 String'First slices");
   ------------------------------------------------------------------
   Check (Enc (Slice_Name) = "R163", "slice Robert 'First=5");
   declare
      Buf : constant String (10 .. 14) := "Smith";
   begin
      Check (Enc (Buf) = "S530", "slice Smith 'First=10");
      Check (Match (Buf, "Smyth"), "slice Smith matches Smyth");
   end;
   declare
      Buf : constant String (3 .. 3) := "A";
   begin
      Check (Enc (Buf) = "A000", "slice single A 'First=3");
   end;

   ------------------------------------------------------------------
   Section ("10. Alphabet micro-cases (first letter)");
   ------------------------------------------------------------------
   Check (Enc ("A") = "A000", "letter A alone");
   Check (Enc ("B") = "B000", "letter B alone");
   Check (Enc ("C") = "C000", "letter C alone");
   Check (Enc ("D") = "D000", "letter D alone");
   Check (Enc ("E") = "E000", "letter E alone");
   Check (Enc ("F") = "F000", "letter F alone");
   Check (Enc ("G") = "G000", "letter G alone");
   Check (Enc ("H") = "H000", "letter H alone");
   Check (Enc ("I") = "I000", "letter I alone");
   Check (Enc ("J") = "J000", "letter J alone");
   Check (Enc ("K") = "K000", "letter K alone");
   Check (Enc ("L") = "L000", "letter L alone");
   Check (Enc ("M") = "M000", "letter M alone");
   Check (Enc ("N") = "N000", "letter N alone");
   Check (Enc ("O") = "O000", "letter O alone");
   Check (Enc ("P") = "P000", "letter P alone");
   Check (Enc ("Q") = "Q000", "letter Q alone");
   Check (Enc ("R") = "R000", "letter R alone");
   Check (Enc ("S") = "S000", "letter S alone");
   Check (Enc ("T") = "T000", "letter T alone");
   Check (Enc ("U") = "U000", "letter U alone");
   Check (Enc ("V") = "V000", "letter V alone");
   Check (Enc ("W") = "W000", "letter W alone");
   Check (Enc ("X") = "X000", "letter X alone");
   Check (Enc ("Y") = "Y000", "letter Y alone");
   Check (Enc ("Z") = "Z000", "letter Z alone");

   ------------------------------------------------------------------
   Section ("11. Consonant map spot checks (Xb form)");
   ------------------------------------------------------------------
   Check (Enc ("Ab") = "A100", "Ab map 1");
   Check (Enc ("Af") = "A100", "Af map 1");
   Check (Enc ("Ap") = "A100", "Ap map 1");
   Check (Enc ("Av") = "A100", "Av map 1");
   Check (Enc ("Ac") = "A200", "Ac map 2");
   Check (Enc ("Ag") = "A200", "Ag map 2");
   Check (Enc ("Aj") = "A200", "Aj map 2");
   Check (Enc ("Ak") = "A200", "Ak map 2");
   Check (Enc ("Aq") = "A200", "Aq map 2");
   Check (Enc ("As") = "A200", "As map 2");
   Check (Enc ("Ax") = "A200", "Ax map 2");
   Check (Enc ("Az") = "A200", "Az map 2");
   Check (Enc ("Ad") = "A300", "Ad map 3");
   Check (Enc ("At") = "A300", "At map 3");
   Check (Enc ("Al") = "A400", "Al map 4");
   Check (Enc ("Am") = "A500", "Am map 5");
   Check (Enc ("An") = "A500", "An map 5");
   Check (Enc ("Ar") = "A600", "Ar map 6");

   ------------------------------------------------------------------
   Section ("12. More surnames and pairs");
   ------------------------------------------------------------------
   Check (Enc ("Miller") = "M460", "Miller -> M460");
   Check (Enc ("Muller") = "M460", "Muller -> M460");
   Check (Match ("Miller", "Muller"), "Miller matches Muller");
   Check (Enc ("Peterson") = "P362", "Peterson -> P362");
   Check (Enc ("Peters") = "P362", "Peters -> P362");
   Check (Match ("Peterson", "Peters"), "Peterson matches Peters");
   Check (Enc ("Catherine") = "C365", "Catherine -> C365");
   Check (Enc ("Katherine") = "K365", "Katherine -> K365");
   Check (not Match ("Catherine", "Katherine"),
          "Catherine/Katherine differ (C vs K)");
   Check (Enc ("Tchaikovsky") = "T221", "Tchaikovsky -> T221");
   Check (Enc ("Czerny") = "C650", "Czerny");
   Check (Enc ("Schmidt") = "S530", "Schmidt -> S530");
   Check (Match ("Schmidt", "Smith"), "Schmidt matches Smith");
   Check (Enc ("Schneider") = "S536", "Schneider -> S536");
   Check (Enc ("Fitzgerald") = "F326", "Fitzgerald");
   Check (Enc ("MacDonald") = "M235", "MacDonald");
   Check (Enc ("McDonald") = "M235", "McDonald");
   Check (Match ("MacDonald", "McDonald"), "Mac/Mc Donald match");
   Check (Enc ("Phillips") = "P412", "Phillips");
   Check (Enc ("Filips") = "F412", "Filips");
   Check (not Match ("Phillips", "Filips"), "P vs F leading letter");
   Check (Enc ("R") = "R000", "R alone");
   Check (Enc ("Rr") = "R000", "Rr collapses");
   Check (Enc ("Rrr") = "R000", "Rrr collapses");
   Check (Enc ("Rb") = "R100", "Rb");
   Check (Enc ("Rbb") = "R100", "Rbb");

   ------------------------------------------------------------------
   Section ("13. Longer inputs and bulk");
   ------------------------------------------------------------------
   declare
      Long : constant String := Make_Alpha (200);
   begin
      Check (Is_Valid_Code (Enc (Long)), "200-letter alphabet valid");
      Check (Enc (Long)'Length = 4, "200-letter length 4");
      Check (Enc (Long) (1) = 'A', "200-letter starts with A");
   end;
   declare
      Long : constant String := Make_Same (500, 'B');
   begin
      Check (Enc (Long) = "B000", "500 Bs -> B000 (all collapse)");
   end;
   declare
      Long : constant String := Make_Same (100, 'M') & "R";
   begin
      Check (Enc (Long) = "M600", "Ms then R -> M600");
   end;
   Check (Is_Valid_Code (Enc (Make_Alpha (26))), "full alphabet valid");
   Check (Is_Valid_Code (Enc (Make_Alpha (52))), "two alphabets valid");
   Check (Match (Make_Same (10, 'S'), Make_Same (3, 'S')),
          "all-S lengths match");
   Check (Enc ("ABCDEFGHIJKLMNOPQRSTUVWXYZ") (1) = 'A',
          "A..Z starts A");
   Check (Is_Valid_Code (Enc ("ABCDEFGHIJKLMNOPQRSTUVWXYZ")),
          "A..Z valid code");
   Check (Enc ("bcdfghjklmnpqrstvwxz") (1) = 'B',
          "consonant run starts B");

   ------------------------------------------------------------------
   Section ("14. Codes_Match symmetry and reflexivity");
   ------------------------------------------------------------------
   Check (Match ("Robert", "Robert"), "reflexive Robert");
   Check (Match ("Ashcraft", "Ashcraft"), "reflexive Ashcraft");
   Check (Match ("Robert", "Rupert") = Match ("Rupert", "Robert"),
          "symmetric Robert/Rupert");
   Check (Match ("Smith", "Jones") = Match ("Jones", "Smith"),
          "symmetric Smith/Jones");
   Check (B (Match ("A", "A")), "reflexive A via B wrapper");

   ------------------------------------------------------------------
   Section ("15. Edge: vowels after first, HWY chains");
   ------------------------------------------------------------------
   Check (Enc ("Aeiou") = "A000", "Aeiou all vowels");
   Check (Enc ("Ahwya") = "A000", "Ahwya all droppable");
   Check (Enc ("Boh") = "B000", "Boh");
   Check (Enc ("Bow") = "B000", "Bow");
   Check (Enc ("Boy") = "B000", "Boy");
   Check (Enc ("Baa") = "B000", "Baa");
   Check (Enc ("Bee") = "B000", "Bee");
   Check (Enc ("Bih") = "B000", "Bih");
   Check (Enc ("Bsr") = "B260", "Bsr");
   Check (Enc ("Bshr") = "B260", "Bshr: S then R across H");
   --  B S H R: S=2, H no-reset, R=6 → B260
   Check (Enc ("Bssr") = "B260", "Bssr SS collapse");
   Check (Enc ("Wh") = "W000", "Wh");
   Check (Enc ("White") = "W300", "White -> W300");
   Check (Enc ("Wright") = "W623", "Wright");
   Check (Enc ("Hofmann") = "H155", "Hofmann");
   Check (Enc ("Hoffman") = "H155", "Hoffman");
   Check (Match ("Hofmann", "Hoffman"), "Hofmann matches Hoffman");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
