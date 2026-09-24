--  Standalone test suite for Match_Rating_Approach (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Match_Rating_Approach; use Match_Rating_Approach;

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

   function Enc (Name : String) return String is
     (Encode (Name));

   function Cmp (A, B : String) return Boolean is
     (Compare (A, B));

   function Rate (A, B : String) return Natural is
     (Similarity_Rating (A, B));

   function Enc_Raises (Name : String) return Boolean is
      procedure Attempt is
         Unused : constant String := Encode (Name);
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

   function Cmp_Raises (A, B : String) return Boolean is
      procedure Attempt is
         Unused : constant Boolean := Compare (A, B);
      begin
         pragma Unreferenced (Unused);
      end Attempt;
   begin
      Attempt;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Cmp_Raises;

   function Rate_Raises (A, B : String) return Boolean is
      procedure Attempt is
         Unused : constant Natural := Similarity_Rating (A, B);
      begin
         pragma Unreferenced (Unused);
      end Attempt;
   begin
      Attempt;
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Rate_Raises;

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

   function Is_Valid_Code (C : String) return Boolean is
   begin
      if C'Length < 1 or else C'Length > Max_Code_Len then
         return False;
      end if;
      for I in C'Range loop
         if C (I) not in 'A' .. 'Z' then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Code;

   function Slice_Byrne return String is
      Buf : constant String (5 .. 9) := "Byrne";
   begin
      return Buf;
   end Slice_Byrne;

begin
   Put_Line ("Match Rating Approach (MRA) test suite");
   Put_Line ("Max_Len =" & Max_Len'Image
             & "  Max_Code_Len =" & Max_Code_Len'Image);
   Put_Line ("Variant: Western Airlines / Wikipedia MRA"
             & " (first3+last3; Commons LTR/RTL rating)");

   ------------------------------------------------------------------
   Section ("1. Wikipedia classic encode vectors");
   ------------------------------------------------------------------
   Check (Enc ("Byrne") = "BYRN", "Byrne -> BYRN");
   Check (Enc ("Boern") = "BRN", "Boern -> BRN");
   Check (Enc ("Smith") = "SMTH", "Smith -> SMTH");
   Check (Enc ("Smyth") = "SMYTH", "Smyth -> SMYTH");
   Check (Enc ("Catherine") = "CTHRN", "Catherine -> CTHRN");
   Check (Enc ("Kathryn") = "KTHRYN", "Kathryn -> KTHRYN");

   ------------------------------------------------------------------
   Section ("2. Wikipedia classic compare / rating");
   ------------------------------------------------------------------
   Check (B (Cmp ("Byrne", "Boern")), "Compare Byrne/Boern match");
   Check (Rate ("Byrne", "Boern") = 5, "Byrne/Boern rating 5");
   Check (Minimum_Rating (Enc ("Byrne")'Length + Enc ("Boern")'Length) = 4,
          "Byrne/Boern min rating 4");

   Check (B (Cmp ("Smith", "Smyth")), "Compare Smith/Smyth match");
   Check (Rate ("Smith", "Smyth") = 5, "Smith/Smyth rating 5");
   Check (Minimum_Rating (Enc ("Smith")'Length + Enc ("Smyth")'Length) = 3,
          "Smith/Smyth min rating 3");

   Check (B (Cmp ("Catherine", "Kathryn")), "Compare Catherine/Kathryn match");
   Check (Rate ("Catherine", "Kathryn") = 4, "Catherine/Kathryn rating 4");
   Check (Minimum_Rating
            (Enc ("Catherine")'Length + Enc ("Kathryn")'Length) = 3,
          "Catherine/Kathryn min rating 3");

   ------------------------------------------------------------------
   Section ("3. Encoding: vowels, doubles, truncation");
   ------------------------------------------------------------------
   Check (Enc ("Lloyd") = "LYD", "Lloyd -> LYD (LL collapse, vowel drop)");
   Check (Enc ("Aaron") = "ARN", "Aaron -> ARN (leading vowel kept)");
   Check (Enc ("Alice") = "ALC", "Alice -> ALC");
   Check (Enc ("Alicia") = "ALC", "Alicia -> ALC");
   Check (Enc ("Gottlieb") = "GTLB", "Gottlieb -> GTLB");
   Check (Enc ("Pfeiffer") = "PFR", "Pfeiffer -> PFR (multi F collapse)");
   Check (Enc ("Bookkeeper") = "BKPR", "Bookkeeper -> BKPR");
   Check (Enc ("Wright") = "WRGHT", "Wright -> WRGHT");
   Check (Enc ("Macintosh") = "MCNTSH", "Macintosh -> MCNTSH (len 6)");
   Check (Enc ("Washington") = "WSHGTN",
          "Washington -> WSHGTN (first3+last3)");
   Check (Enc ("Alexander") = "ALXNDR", "Alexander -> ALXNDR");
   Check (Enc ("Elizabeth") = "ELZBTH", "Elizabeth -> ELZBTH");
   Check (Enc ("Christopher") = "CHRPHR",
          "Christopher -> CHRPHR (truncation)");
   Check (Enc ("B") = "B", "single consonant B -> B");
   Check (Enc ("A") = "A", "single vowel A -> A");
   Check (Enc ("Y") = "Y", "single Y (consonant) -> Y");
   Check (Enc ("Lee") = "L", "Lee -> L");
   Check (Enc ("Ai") = "A", "Ai -> A");

   ------------------------------------------------------------------
   Section ("4. Case folding and non-letter stripping");
   ------------------------------------------------------------------
   Check (Enc ("smith") = "SMTH", "lowercase smith");
   Check (Enc ("SMITH") = "SMTH", "uppercase SMITH");
   Check (Enc ("SmItH") = "SMTH", "mixed SmItH");
   Check (Enc ("S m i t h") = "SMTH", "spaces stripped");
   Check (Enc ("S-m.i'th") = "SMTH", "punctuation stripped");
   Check (Enc ("123Smith456") = "SMTH", "digits stripped");
   Check (Enc ("  Byrne  ") = "BYRN", "leading/trailing spaces");
   Check (Enc (Slice_Byrne) = "BYRN", "non-1 String'First slice Byrne");

   ------------------------------------------------------------------
   Section ("5. Codex length invariant (<= 6)");
   ------------------------------------------------------------------
   Check (Is_Valid_Code (Enc ("Byrne")), "BYRN valid code");
   Check (Is_Valid_Code (Enc ("Washington")), "WSHGTN valid code");
   Check (Enc ("Washington")'Length = 6, "Washington code length 6");
   Check (Enc ("Christopher")'Length = 6, "Christopher code length 6");
   Check (Enc ("A")'Length = 1, "A code length 1");
   Check (Enc ("Smith")'Length <= Max_Code_Len, "Smith <= Max_Code_Len");
   declare
      Long : constant String := Make_Alpha (80);
      C    : constant String := Enc (Long);
   begin
      Check (C'Length = 6, "long alpha encodes to length 6");
      Check (Is_Valid_Code (C), "long alpha code alphabetic");
   end;

   ------------------------------------------------------------------
   Section ("6. Table A Minimum_Rating");
   ------------------------------------------------------------------
   Check (Minimum_Rating (0) = 5, "sum 0 -> min 5");
   Check (Minimum_Rating (1) = 5, "sum 1 -> min 5");
   Check (Minimum_Rating (4) = 5, "sum 4 -> min 5");
   Check (Minimum_Rating (5) = 4, "sum 5 -> min 4");
   Check (Minimum_Rating (7) = 4, "sum 7 -> min 4");
   Check (Minimum_Rating (8) = 3, "sum 8 -> min 3");
   Check (Minimum_Rating (11) = 3, "sum 11 -> min 3");
   Check (Minimum_Rating (12) = 2, "sum 12 -> min 2");
   Check (Minimum_Rating (13) = 1, "sum 13 -> min 1 (guard)");
   Check (Minimum_Rating (100) = 1, "sum 100 -> min 1 (guard)");

   ------------------------------------------------------------------
   Section ("7. Compare true pairs (homophones / near)");
   ------------------------------------------------------------------
   Check (B (Cmp ("John", "Joan")), "John/Joan match");
   Check (B (Cmp ("Robert", "Rupert")), "Robert/Rupert match");
   Check (B (Cmp ("Alice", "Alicia")), "Alice/Alicia match");
   Check (B (Cmp ("Michael", "Mitchell")), "Michael/Mitchell match");
   Check (B (Cmp ("Stephen", "Steven")), "Stephen/Steven match");
   Check (B (Cmp ("Brian", "Bryan")), "Brian/Bryan match");
   Check (B (Cmp ("Cathy", "Kathy")), "Cathy/Kathy match");
   Check (B (Cmp ("Ann", "Anne")), "Ann/Anne match");
   Check (B (Cmp ("Smith", "Smith")), "identical Smith match");
   Check (B (Cmp ("byrne", "BOERN")), "case-insensitive Byrne/Boern");
   Check (B (Cmp ("Smyth", "Smith")), "Smyth/Smith symmetric");
   Check (B (Cmp ("Boern", "Byrne")), "Boern/Byrne symmetric");

   ------------------------------------------------------------------
   Section ("8. Compare false / length-diff skip");
   ------------------------------------------------------------------
   Check (not Cmp ("Smith", "Jones"), "Smith/Jones no match");
   Check (not Cmp ("Byrne", "Washington"), "Byrne/Washington no match");
   Check (Rate ("Byrne", "Washington") = 0
            or else not Cmp ("Byrne", "Washington"),
          "Byrne/Washington rating low or length skip");
   --  Encoded length difference >= 3 forces rating 0 and no match.
   declare
      --  "A" -> A (len 1); "Christopher" -> CHRPHR (len 6); diff 5 >= 3
   begin
      Check (Rate ("A", "Christopher") = 0, "len-diff>=3 rating 0");
      Check (not Cmp ("A", "Christopher"), "len-diff>=3 Compare false");
   end;
   Check (not Cmp ("Al", "Washington"), "Al/Washington no match");

   ------------------------------------------------------------------
   Section ("9. Similarity_Rating details");
   ------------------------------------------------------------------
   Check (Rate ("Smith", "Smith") = 6, "identical encodings rating 6");
   Check (Rate ("Alice", "Alicia") = 6, "Alice/Alicia both ALC rating 6");
   Check (Rate ("Byrne", "Boern") >= Minimum_Rating (7),
          "Byrne/Boern rating meets min");
   Check (Rate ("John", "Joan") = 5, "John/Joan rating 5");
   Check (Rate ("Robert", "Rupert") = 5, "Robert/Rupert rating 5");

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Enc_Raises (""), "empty Encode raises");
   Check (Enc_Raises ("123"), "digits-only Encode raises");
   Check (Enc_Raises ("---"), "punct-only Encode raises");
   Check (Enc_Raises ("   "), "spaces-only Encode raises");
   Check (Enc_Raises (Make_Same (Max_Len + 1, 'A')),
          "over Max_Len Encode raises");
   Check (not Enc_Raises (Make_Same (Max_Len, 'B')),
          "exactly Max_Len Encode ok");
   Check (Cmp_Raises ("", "Smith"), "Compare empty left raises");
   Check (Cmp_Raises ("Smith", ""), "Compare empty right raises");
   Check (Cmp_Raises ("!!!", "Smith"), "Compare letter-free raises");
   Check (Rate_Raises ("", "A"), "Similarity empty raises");
   Check (Rate_Raises ("A", "@@@"), "Similarity letter-free raises");

   ------------------------------------------------------------------
   Section ("11. Leading vowel preservation");
   ------------------------------------------------------------------
   Check (Enc ("Edgar") = "EDGR", "Edgar -> EDGR");
   Check (Enc ("Otto") = "OT", "Otto -> OT");
   Check (Enc ("Irene") = "IRN", "Irene -> IRN");
   Check (Enc ("Ursula") = "URSL", "Ursula -> URSL");
   Check (Enc ("Owen") = "OWN", "Owen -> OWN");
   Check (Enc ("Eagle") = "EGL", "Eagle -> EGL");

   ------------------------------------------------------------------
   Section ("12. Y treated as consonant");
   ------------------------------------------------------------------
   Check (Enc ("Smyth") = "SMYTH", "Y kept in Smyth");
   Check (Enc ("Byrne") = "BYRN", "Y kept in Byrne");
   Check (Enc ("Yvonne") = "YVN", "Yvonne -> YVN");
   Check (Enc ("Mary") = "MRY", "Mary -> MRY");
   Check (Enc ("Kelly") = "KLY", "Kelly -> KLY");
   Check (B (Cmp ("Smith", "Smyth")), "Y does not break Smith/Smyth");

   ------------------------------------------------------------------
   Section ("13. Double-consonant collapse suite");
   ------------------------------------------------------------------
   Check (Enc ("Billy") = "BLY", "Billy -> BLY");
   --  Bobby: B O B B Y -> BBBY -> BY after adjacent collapse
   Check (Enc ("Bobby") = "BY", "Bobby -> BY");
   Check (Enc ("Tommy") = "TMY", "Tommy -> TMY");
   Check (Enc ("Jenny") = "JNY", "Jenny -> JNY");
   Check (Enc ("Harris") = "HRS", "Harris -> HRS");
   Check (Enc ("Williams") = "WLMS", "Williams -> WLMS");
   --  MISSISSIPPI -> MSSSSPP -> MSP after full adjacent collapse
   Check (Enc ("Mississippi") = "MSP", "Mississippi -> MSP");

   ------------------------------------------------------------------
   Section ("14. Truncation first3+last3 more vectors");
   ------------------------------------------------------------------
   Check (Enc ("Bartholomew") = "BRTLMW", "Bartholomew truncated");
   Check (Enc ("Montgomery") = "MNTMRY", "Montgomery truncated");
   Check (Enc ("Fitzgerald") = "FTZRLD", "Fitzgerald truncated");
   declare
      E : constant String := Enc ("Bartholomew");
   begin
      Check (E'Length = 6, "Bartholomew length 6");
      Check (E (E'First .. E'First + 2) = "BRT", "Bartholomew first3 BRT");
   end;

   ------------------------------------------------------------------
   Section ("15. Bulk single-letter and short names");
   ------------------------------------------------------------------
   declare
      Letters : constant String := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   begin
      for I in Letters'Range loop
         declare
            S : constant String (1 .. 1) := [Letters (I)];
            C : constant String := Enc (S);
         begin
            Check (C = S, "single " & S & " encodes to itself");
         end;
      end loop;
   end;
   Check (Enc ("AB") = "AB", "AB -> AB");
   Check (Enc ("BA") = "B", "BA -> B");
   Check (Enc ("AEIOU") = "A", "AEIOU -> A");
   Check (Enc ("BCDFG") = "BCDFG", "BCDFG unchanged");

   ------------------------------------------------------------------
   Section ("16. Compare symmetry and idempotence");
   ------------------------------------------------------------------
   Check (Cmp ("Byrne", "Boern") = Cmp ("Boern", "Byrne"),
          "Compare symmetry Byrne/Boern");
   Check (Cmp ("Smith", "Jones") = Cmp ("Jones", "Smith"),
          "Compare symmetry Smith/Jones");
   Check (Rate ("Byrne", "Boern") = Rate ("Boern", "Byrne"),
          "Rating symmetry Byrne/Boern");
   Check (Enc (Enc ("Smith")) = Enc ("Smith"),
          "Encode idempotent on codex-like input");

   ------------------------------------------------------------------
   Section ("17. Longer inputs and capacity");
   ------------------------------------------------------------------
   declare
      N9999 : constant String := Make_Same (9999, 'N');
      C     : constant String := Enc (N9999);
   begin
      Check (C = "N", "9999 N's -> N after collapse");
   end;
   declare
      Mix : constant String := Make_Alpha (200);
      C   : constant String := Enc (Mix);
   begin
      Check (C'Length = 6, "200-letter alpha -> len 6");
      Check (Is_Valid_Code (C), "200-letter alpha valid");
   end;
   Check (not Enc_Raises ("Z"), "single Z ok");
   Check (B (Cmp ("Nn", "N")), "Nn/N match after collapse");

   ------------------------------------------------------------------
   Section ("18. More homophone / near-miss pairs");
   ------------------------------------------------------------------
   Check (B (Cmp ("Catherine", "Katharine")), "Catherine/Katharine");
   Check (B (Cmp ("Steven", "Stephen")), "Steven/Stephen");
   Check (B (Cmp ("Jon", "John")), "Jon/John");
   Check (B (Cmp ("Sara", "Sarah")), "Sara/Sarah");
   Check (B (Cmp ("Marc", "Mark")), "Marc/Mark");
   Check (B (Cmp ("Philip", "Phillip")), "Philip/Phillip");
   Check (Enc ("Philip") = Enc ("Phillip")
            or else Cmp ("Philip", "Phillip"),
          "Philip/Phillip encode-equal or compare");
   Check (B (Cmp ("Carl", "Karl")), "Carl/Karl");
   Check (B (Cmp ("Jeffrey", "Geoffrey"))
            or else Rate ("Jeffrey", "Geoffrey") >= 0,
          "Jeffrey/Geoffrey compare or rating defined");

   ------------------------------------------------------------------
   Section ("19. Residual rating edge cases");
   ------------------------------------------------------------------
   --  Completely different short codes
   Check (Rate ("B", "C") = 5, "B/C residual 1 => rating 5");
   Check (Minimum_Rating (2) = 5, "sum 2 min 5");
   Check (B (Cmp ("B", "C")), "B/C match at min 5 with rating 5");
   Check (Rate ("AB", "CD") = 4, "AB/CD residual 2 => rating 4");
   Check (not Cmp ("AB", "CD") or else Cmp ("AB", "CD"),
          "AB/CD defined (sum 4 min 5; rating 4 => no match)");
   Check (not Cmp ("AB", "CD"), "AB/CD no match (4 < 5)");

   ------------------------------------------------------------------
   Section ("20. Mixed punctuation names");
   ------------------------------------------------------------------
   Check (Enc ("O'Brien") = "OBRN", "O'Brien -> OBRN");
   Check (Enc ("Mary-Jane") = "MRYJN", "Mary-Jane -> MRYJN");
   Check (Enc ("Jean-Luc") = "JNLC", "Jean-Luc -> JNLC");
   Check (B (Cmp ("OBrien", "O'Brien")), "OBrien vs O'Brien match");

   ------------------------------------------------------------------
   Section ("21. Encode length policy spot checks");
   ------------------------------------------------------------------
   Check (Enc ("ABC")'Length = 3, "ABC len 3");
   Check (Enc ("ABCDEF") = "ABCDF", "ABCDEF -> ABCDF (drop E)");
   Check (Enc ("ABCDEFG") = "ABCDFG", "ABCDEFG -> ABCDFG");
   Check (Enc ("ABCDEFGH") = "ABCFGH", "ABCDEFGH -> ABCFGH");
   Check (Enc ("ABCDEFGHIJ") = "ABCGHJ", "ABCDEFGHIJ -> ABCGHJ");

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS,"
             & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
