--  Standalone test suite for NYSIIS (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with NYSIIS; use NYSIIS;

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

   function Match (A, B : String) return Boolean is
     (Codes_Match (A, B));

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
         R (K) := Character'Val (Character'Pos ('A') + (K - 1) mod 26);
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

   function Slice_Name return String is
      Buf : constant String (5 .. 10) := "Bishop";
   begin
      return Buf;
   end Slice_Name;

begin
   Put_Line ("NYSIIS test suite");
   Put_Line ("Max_Len =" & Max_Len'Image
             & "  Max_Code_Len =" & Max_Code_Len'Image);
   Put_Line ("Variant: original/strict Taft NYSIIS (truncate 6; Ash keeps A)");

   ------------------------------------------------------------------
   Section ("1. Apache Commons / dropby classic vectors");
   ------------------------------------------------------------------
   Check (Enc ("MACINTOSH") = "MCANT", "MACINTOSH -> MCANT");
   Check (Enc ("KNUTH") = "NAT", "KNUTH -> NAT");
   Check (Enc ("KOEHN") = "CAN", "KOEHN -> CAN");
   Check (Enc ("PHILLIPSON") = "FALAPS", "PHILLIPSON -> FALAPS");
   Check (Enc ("PFEISTER") = "FASTAR", "PFEISTER -> FASTAR");
   Check (Enc ("SCHOENHOEFT") = "SANAFT", "SCHOENHOEFT -> SANAFT");
   Check (Enc ("MCKEE") = "MCY", "MCKEE -> MCY");
   Check (Enc ("MACKIE") = "MCY", "MACKIE -> MCY");
   Check (Enc ("HEITSCHMIDT") = "HATSNA", "HEITSCHMIDT -> HATSNA");
   Check (Enc ("BART") = "BAD", "BART -> BAD");
   Check (Enc ("HURD") = "HAD", "HURD -> HAD");
   Check (Enc ("HUNT") = "HAD", "HUNT -> HAD");
   Check (Enc ("WESTERLUND") = "WASTAR", "WESTERLUND -> WASTAR");
   Check (Enc ("CASSTEVENS") = "CASTAF", "CASSTEVENS -> CASTAF");
   Check (Enc ("VASQUEZ") = "VASG", "VASQUEZ -> VASG");
   Check (Enc ("FRAZIER") = "FRASAR", "FRAZIER -> FRASAR");
   Check (Enc ("BOWMAN") = "BANAN", "BOWMAN -> BANAN");
   Check (Enc ("MCKNIGHT") = "MCNAGT", "MCKNIGHT -> MCNAGT");
   Check (Enc ("RICKERT") = "RACAD", "RICKERT -> RACAD");
   Check (Enc ("DEUTSCH") = "DAT", "DEUTSCH -> DAT");
   Check (Enc ("WESTPHAL") = "WASTFA", "WESTPHAL -> WASTFA");
   Check (Enc ("SHRIVER") = "SRAVAR", "SHRIVER -> SRAVAR");
   Check (Enc ("KUHL") = "CAL", "KUHL -> CAL");
   Check (Enc ("RAWSON") = "RASAN", "RAWSON -> RASAN");
   Check (Enc ("JILES") = "JAL", "JILES -> JAL");
   Check (Enc ("CARRAWAY") = "CARY", "CARRAWAY -> CARY");
   Check (Enc ("YAMADA") = "YANAD", "YAMADA -> YANAD");

   ------------------------------------------------------------------
   Section ("2. Bran / Cap / Dad / Dan / Fal clusters");
   ------------------------------------------------------------------
   Check (Enc ("Brian") = "BRAN", "Brian -> BRAN");
   Check (Enc ("Brown") = "BRAN", "Brown -> BRAN");
   Check (Enc ("Brun") = "BRAN", "Brun -> BRAN");
   Check (Enc ("Capp") = "CAP", "Capp -> CAP");
   Check (Enc ("Cope") = "CAP", "Cope -> CAP");
   Check (Enc ("Copp") = "CAP", "Copp -> CAP");
   Check (Enc ("Kipp") = "CAP", "Kipp -> CAP");
   Check (Enc ("Dent") = "DAD", "Dent -> DAD");
   Check (Enc ("Dane") = "DAN", "Dane -> DAN");
   Check (Enc ("Dean") = "DAN", "Dean -> DAN");
   Check (Enc ("Dionne") = "DAN", "Dionne -> DAN");
   Check (Enc ("Phil") = "FAL", "Phil -> FAL");

   ------------------------------------------------------------------
   Section ("3. Rosetta / surname examples (truncated to 6)");
   ------------------------------------------------------------------
   Check (Enc ("Bishop") = "BASAP", "Bishop -> BASAP");
   Check (Enc ("Carlson") = "CARLSA", "Carlson -> CARLSA");
   Check (Enc ("Carr") = "CAR", "Carr -> CAR");
   Check (Enc ("Chapman") = "CAPNAN", "Chapman -> CAPNAN");
   Check (Enc ("Franklin") = "FRANCL", "Franklin -> FRANCL");
   Check (Enc ("Greene") = "GRAN", "Greene -> GRAN");
   Check (Enc ("Harper") = "HARPAR", "Harper -> HARPAR");
   Check (Enc ("Jacobs") = "JACAB", "Jacobs -> JACAB");
   Check (Enc ("Larson") = "LARSAN", "Larson -> LARSAN");
   Check (Enc ("Lawrence") = "LARANC", "Lawrence -> LARANC");
   Check (Enc ("Lawson") = "LASAN", "Lawson -> LASAN");
   Check (Enc ("Lynch") = "LYNC", "Lynch -> LYNC");
   Check (Enc ("Mackenzie") = "MCANSY", "Mackenzie -> MCANSY");
   Check (Enc ("Matthews") = "MAT", "Matthews -> MAT");
   Check (Enc ("McCormack") = "MCARNA", "McCormack -> MCARNA");
   Check (Enc ("McDaniel") = "MCDANA", "McDaniel -> MCDANA");
   Check (Enc ("McDonald") = "MCDANA", "McDonald -> MCDANA");
   Check (Enc ("Mclaughlin") = "MCLAGL", "Mclaughlin -> MCLAGL");
   Check (Enc ("Morrison") = "MARASA", "Morrison -> MARASA");
   Check (Enc ("O'Banion") = "OBANAN", "O'Banion -> OBANAN");
   Check (Enc ("O'Brien") = "OBRAN", "O'Brien -> OBRAN");
   Check (Enc ("Richards") = "RACARD", "Richards -> RACARD");
   Check (Enc ("Silva") = "SALV", "Silva -> SALV");
   Check (Enc ("Watkins") = "WATCAN", "Watkins -> WATCAN");
   Check (Enc ("Wheeler") = "WALAR", "Wheeler -> WALAR");
   Check (Enc ("Willis") = "WAL", "Willis -> WAL");
   Check (Enc ("knight") = "NAGT", "knight -> NAGT");
   Check (Enc ("mitchell") = "MATCAL", "mitchell -> MATCAL");
   Check (Enc ("o'daniel") = "ODANAL", "o'daniel -> ODANAL");
   Check (Enc ("hayes") = "HAY", "hayes -> HAY");
   Check (Enc ("LouisXVI") = "LASXV", "LouisXVI -> LASXV");

   ------------------------------------------------------------------
   Section ("4. Prefix rule unit vectors");
   ------------------------------------------------------------------
   Check (Enc ("MACX") = "MCX", "MACX -> MCX");
   Check (Enc ("KNX") = "NX", "KNX -> NX");
   Check (Enc ("KX") = "CX", "KX -> CX");
   Check (Enc ("PHX") = "FX", "PHX -> FX");
   Check (Enc ("PFX") = "FX", "PFX -> FX");
   Check (Enc ("SCHX") = "SX", "SCHX -> SX");

   ------------------------------------------------------------------
   Section ("5. Suffix rule unit vectors");
   ------------------------------------------------------------------
   Check (Enc ("XEE") = "XY", "XEE -> XY");
   Check (Enc ("XIE") = "XY", "XIE -> XY");
   Check (Enc ("XDT") = "XD", "XDT -> XD");
   Check (Enc ("XRT") = "XD", "XRT -> XD");
   Check (Enc ("XRD") = "XD", "XRD -> XD");
   Check (Enc ("XNT") = "XD", "XNT -> XD");
   Check (Enc ("XND") = "XD", "XND -> XD");

   ------------------------------------------------------------------
   Section ("6. Mid-scan rule unit vectors");
   ------------------------------------------------------------------
   Check (Enc ("XEV") = "XAF", "XEV -> XAF");
   Check (Enc ("XAX") = "XAX", "XAX -> XAX");
   Check (Enc ("XEX") = "XAX", "XEX -> XAX");
   Check (Enc ("XIX") = "XAX", "XIX -> XAX");
   Check (Enc ("XOX") = "XAX", "XOX -> XAX");
   Check (Enc ("XUX") = "XAX", "XUX -> XAX");
   Check (Enc ("XQ") = "XG", "XQ -> XG");
   Check (Enc ("XZ") = "X", "XZ -> X (trailing S removed)");
   Check (Enc ("XM") = "XN", "XM -> XN");
   Check (Enc ("XS") = "X", "XS -> X");
   Check (Enc ("XSS") = "X", "XSS -> X");
   Check (Enc ("XAY") = "XY", "XAY -> XY");
   Check (Enc ("XAYS") = "XY", "XAYS -> XY");
   Check (Enc ("XA") = "X", "XA -> X");
   Check (Enc ("XAS") = "X", "XAS -> X");

   ------------------------------------------------------------------
   Section ("7. Special branches / short names");
   ------------------------------------------------------------------
   Check (Enc ("Schmidt") = "SNAD", "Schmidt -> SNAD");
   Check (Enc ("Smith") = "SNAT", "Smith -> SNAT");
   Check (Enc ("Schmit") = "SNAT", "Schmit -> SNAT");
   Check (Enc ("Kobwick") = "CABWAC", "Kobwick -> CABWAC");
   Check (Enc ("Kocher") = "CACAR", "Kocher -> CACAR");
   Check (Enc ("Fesca") = "FASC", "Fesca -> FASC");
   Check (Enc ("Shom") = "SAN", "Shom -> SAN");
   Check (Enc ("Ohlo") = "OL", "Ohlo -> OL");
   Check (Enc ("Uhu") = "UH", "Uhu -> UH");
   Check (Enc ("Um") = "UN", "Um -> UN");
   Check (Enc ("Trueman") = "TRANAN", "Trueman -> TRANAN");
   Check (Enc ("Truman") = "TRANAN", "Truman -> TRANAN");
   Check (Enc ("Ash") = "A", "Ash -> A (first letter preserved)");
   Check (Enc ("A") = "A", "single A -> A");
   Check (Enc ("B") = "B", "single B -> B");
   Check (Enc ("Z") = "Z", "single Z -> Z");
   Check (Enc ("FUZZY") = "FASY", "FUZZY -> FASY");
   Check (Enc ("Cory") = "CARY", "Cory -> CARY");
   Check (Enc ("Corey") = "CARY", "Corey -> CARY");
   Check (Enc ("Kory") = "CARY", "Kory -> CARY");

   ------------------------------------------------------------------
   Section ("8. Case folding and non-letter stripping");
   ------------------------------------------------------------------
   Check (Enc ("bishop") = "BASAP", "lowercase bishop");
   Check (Enc ("BiShOp") = "BASAP", "mixed case BiShOp");
   Check (Enc ("O'Daniel") = "ODANAL", "apostrophe skipped");
   Check (Enc ("O-Brien") = "OBRAN", "hyphen skipped");
   Check (Enc ("Mc Donald") = "MCDANA", "space skipped");
   Check (Enc ("Smith123") = "SNAT", "digits skipped");
   Check (Enc ("  Harper  ") = "HARPAR", "leading/trailing spaces");
   Check (Enc ("W.heeler") = "WALAR", "punctuation skipped");
   Check (Enc ("brown sr") = "BRANSR", "brown sr (letters only)");
   Check (Enc ("browne III") = "BRAN", "browne III");
   Check (Enc ("browne IV") = "BRANAV", "browne IV");

   ------------------------------------------------------------------
   Section ("9. Codes_Match true/false");
   ------------------------------------------------------------------
   Check (Match ("Brian", "Brown"), "Brian matches Brown");
   Check (Match ("Capp", "Kipp"), "Capp matches Kipp");
   Check (Match ("Smith", "Schmit"), "Smith matches Schmit");
   Check (Match ("MCKEE", "MACKIE"), "MCKEE matches MACKIE");
   Check (Match ("Cory", "Corey"), "Cory matches Corey");
   Check (Match ("Cory", "Kory"), "Cory matches Kory");
   Check (Match ("Trueman", "Truman"), "Trueman matches Truman");
   Check (Match ("HURD", "HUNT"), "HURD matches HUNT");
   Check (not Match ("Bishop", "Willis"), "Bishop != Willis");
   Check (not Match ("Smith", "Jones"), "Smith != Jones");
   Check (Match ("Bishop", "bishop"), "case-insensitive match");
   Check (Match ("O'Brien", "Obrien"), "apostrophe-insensitive match");
   Check (Match ("Robert", "Robert"), "reflexive Robert");
   Check (Match ("Ashcraft", "Ashcraft") = Match ("Ashcraft", "Ashcraft"),
          "reflexive Ashcraft");
   Check (Match ("Brian", "Brown") = Match ("Brown", "Brian"),
          "symmetric Brian/Brown");
   Check (B (Match ("A", "A")), "reflexive A via B wrapper");

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Enc_Raises (""), "empty raises");
   Check (Enc_Raises ("123"), "digits-only raises");
   Check (Enc_Raises ("---"), "punctuation-only raises");
   Check (Enc_Raises ("   "), "spaces-only raises");
   Check (Enc_Raises (Make_Same (Max_Len + 1, 'A')), "over Max_Len raises");
   Check (not Enc_Raises (Make_Same (Max_Len, 'A')), "exactly Max_Len ok");
   Check (Match_Raises ("", "A"), "Match empty left raises");
   Check (Match_Raises ("A", ""), "Match empty right raises");
   Check (Match_Raises ("123", "Smith"), "Match letter-free left raises");
   Check (Match_Raises ("Smith", "!!!"), "Match letter-free right raises");

   ------------------------------------------------------------------
   Section ("11. Truncation and length invariant");
   ------------------------------------------------------------------
   Check (Enc ("WESTERLUND")'Length = 6, "WESTERLUND length 6");
   Check (Enc ("Franklin")'Length = 6, "Franklin truncated to 6");
   Check (Enc ("Carlson")'Length = 6, "Carlson truncated to 6");
   Check (Enc ("McDonald")'Length = 6, "McDonald truncated to 6");
   Check (Enc ("Mclaughlin")'Length = 6, "Mclaughlin truncated to 6");
   Check (Enc ("Morrison")'Length = 6, "Morrison truncated to 6");
   Check (Enc ("Carr")'Length = 3, "Carr length 3 unpadded");
   Check (Enc ("A")'Length = 1, "A length 1 unpadded");
   Check (Is_Valid_Code (Enc ("WESTERLUND")), "WESTERLUND valid code");
   Check (Is_Valid_Code (Enc ("Bishop")), "Bishop valid code");
   Check (Is_Valid_Code (Enc ("A")), "A valid code");
   Check (Is_Valid_Code (Enc ("Willis")), "Willis valid code");
   Check (Is_Valid_Code (Enc (Make_Alpha (40))), "long alphabet valid");

   ------------------------------------------------------------------
   Section ("12. Non-1 String'First slices");
   ------------------------------------------------------------------
   Check (Enc (Slice_Name) = "BASAP", "slice Bishop 'First=5");
   declare
      Buf : constant String (10 .. 14) := "Smith";
   begin
      Check (Enc (Buf) = "SNAT", "slice Smith 'First=10");
   end;
   declare
      Buf : constant String (3 .. 8) := "Willis";
   begin
      Check (Enc (Buf) = "WAL", "slice Willis 'First=3");
   end;
   declare
      Buf : constant String (2 .. 2) := "A";
   begin
      Check (Enc (Buf) = "A", "slice single A 'First=2");
   end;

   ------------------------------------------------------------------
   Section ("13. Bulk micro-cases over alphabet / length");
   ------------------------------------------------------------------
   declare
      Letters : constant String := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   begin
      for I in Letters'Range loop
         declare
            C : constant Character := Letters (I);
            S : constant String := [1 => C];
         begin
            Check (Is_Valid_Code (Enc (S)),
                   "single " & S & " valid");
         end;
      end loop;
   end;
   Check (Enc (Make_Same (10, 'S')) (1) = 'S', "10 Ss start S");
   Check (Enc (Make_Same (10, 'S'))'Length <= Max_Code_Len,
          "10 Ss within Max_Code_Len");
   Check (Enc (Make_Same (50, 'A')) = "A", "50 As -> A");
   Check (Enc (Make_Same (20, 'B')) = "B", "20 Bs collapse to B");
   declare
      Long : constant String := Make_Alpha (200);
   begin
      Check (Is_Valid_Code (Enc (Long)), "200-letter alphabet valid");
      Check (Enc (Long)'Length <= Max_Code_Len, "200-letter truncated");
   end;
   declare
      Long : constant String := Make_Same (500, 'M');
   begin
      --  First M stays; later M→N; adjacent N collapse → "MN".
      Check (Enc (Long) = "MN", "500 Ms -> MN");
      Check (Is_Valid_Code (Enc (Long)), "500 Ms valid");
   end;
   Check (Enc ("ABCDEFGHIJKLMNOPQRSTUVWXYZ") (1) = 'A',
          "A..Z starts A");
   Check (Is_Valid_Code (Enc ("ABCDEFGHIJKLMNOPQRSTUVWXYZ")),
          "A..Z valid");
   Check (Match (Make_Same (5, 'B'), Make_Same (12, 'B')),
          "all-B lengths match");

   ------------------------------------------------------------------
   Section ("14. H / W / vowel edge chains");
   ------------------------------------------------------------------
   Check (Enc ("White") = "WAT", "White -> WAT");
   Check (Enc ("Wright") = "WRAGT", "Wright -> WRAGT");
   Check (Enc ("Hofmann") = "HAFNAN", "Hofmann -> HAFNAN");
   Check (Enc ("Hoffman") = "HAFNAN", "Hoffman -> HAFNAN");
   Check (Match ("Hofmann", "Hoffman"), "Hofmann matches Hoffman");
   Check (Is_Valid_Code (Enc ("Bowman")), "Bowman valid");
   Check (Enc ("Ahaha") = "AHAH", "Ahaha -> AHAH");
   Check (Enc ("Schwartz") = "SWART", "Schwartz -> SWART");
   Check (Enc ("Phillips") = "FALAP", "Phillips -> FALAP");
   Check (Enc ("School") = "SAL", "School -> SAL");
   Check (Enc ("Knight") = "NAGT", "Knight -> NAGT");
   Check (Enc ("Macdonald") = "MCDANA", "Macdonald -> MCDANA");

   ------------------------------------------------------------------
   Section ("15. More match / mismatch pairs");
   ------------------------------------------------------------------
   Check (Match ("Dent", "Dent"), "Dent reflexive");
   Check (Match ("Phil", "PHIL"), "Phil case match");
   Check (not Match ("Bishop", "Harper"), "Bishop != Harper");
   Check (not Match ("Larson", "Lawson"), "Larson != Lawson");
   --  Both truncate to MCDANA under Max_Code_Len=6
   Check (Match ("McDaniel", "McDonald"),
          "McDaniel matches McDonald under truncation");
   Check (Enc ("McDaniel") = "MCDANA", "McDaniel -> MCDANA");
   Check (Enc ("McDonald") = "MCDANA", "McDonald -> MCDANA");
   Check (Match ("MACINTOSH", "macintosh"), "MACINTOSH case match");
   Check (Is_Valid_Code (Enc ("KNUTHX")), "KNUTHX valid");
   Check (Enc ("KNUTHX") (1) = 'N', "KNUTHX starts N");
   Check (Match ("Greene", "GREENE"), "Greene case");
   Check (Match ("Lynch", "lynch"), "Lynch case");
   Check (not Match ("Carr", "Carlson"), "Carr != Carlson");

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
