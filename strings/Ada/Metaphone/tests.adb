--  Standalone test suite for Metaphone (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Metaphone; use Metaphone;

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

   function Enc (Word : String) return String is
     (Encode (Word));

   function Match (A, B : String) return Boolean is
     (Codes_Match (A, B));

   function Enc_Raises (Word : String) return Boolean is
      procedure Attempt is
         Unused : constant String := Encode (Word);
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
         case C (I) is
            when 'A' .. 'Z' | '0' =>
               null;
            when others =>
               return False;
         end case;
      end loop;
      return True;
   end Is_Valid_Code;

   function Slice_Name return String is
      Buf : constant String (5 .. 8) := "John";
   begin
      return Buf;
   end Slice_Name;

begin
   Put_Line ("Metaphone test suite");
   Put_Line ("Max_Len =" & Max_Len'Image
             & "  Max_Code_Len =" & Max_Code_Len'Image);
   Put_Line ("Variant: original Philips / Apache Commons Codec Metaphone"
             & " (trunc. 4; TH→0)");

   ------------------------------------------------------------------
   Section ("1. Apache Commons classic sentence vectors");
   ------------------------------------------------------------------
   Check (Enc ("howl") = "HL", "howl -> HL");
   Check (Enc ("testing") = "TSTN", "testing -> TSTN");
   Check (Enc ("The") = "0", "The -> 0");
   Check (Enc ("quick") = "KK", "quick -> KK");
   Check (Enc ("brown") = "BRN", "brown -> BRN");
   Check (Enc ("fox") = "FKS", "fox -> FKS");
   Check (Enc ("jumped") = "JMPT", "jumped -> JMPT");
   Check (Enc ("over") = "OFR", "over -> OFR");
   Check (Enc ("the") = "0", "the -> 0");
   Check (Enc ("lazy") = "LS", "lazy -> LS");
   Check (Enc ("dogs") = "TKS", "dogs -> TKS");

   ------------------------------------------------------------------
   Section ("2. SCE / SCI / SCY discard; SCH / CH / CIA");
   ------------------------------------------------------------------
   Check (Enc ("SCIENCE") = "SNS", "SCIENCE -> SNS");
   Check (Enc ("SCENE") = "SN", "SCENE -> SN");
   Check (Enc ("SCY") = "S", "SCY -> S");
   Check (Enc ("SCHEDULE") = "SKTL", "SCHEDULE -> SKTL");
   Check (Enc ("SCHEMATIC") = "SKMT", "SCHEMATIC -> SKMT");
   Check (Enc ("DISCHARGE") = "TSKR", "DISCHARGE -> TSKR");
   Check (Enc ("ECHO") = "EX", "ECHO -> EX");
   Check (Enc ("TEACH") = "TX", "TEACH -> TX");
   Check (Enc ("CHERI") = "XR", "CHERI -> XR");
   Check (Enc ("CHIP") = "XP", "CHIP -> XP");
   Check (Enc ("CHRIST") = "XRST", "CHRIST -> XRST");
   Check (Enc ("CIAO") = "X", "CIAO -> X");
   Check (Enc ("CITY") = "ST", "CITY -> ST");
   Check (Enc ("CAT") = "KT", "CAT -> KT");
   Check (Enc ("CIAPO") = "XP", "CIAPO -> XP");
   Check (Enc ("Schmidt") = "SKMT", "Schmidt -> SKMT (SCH→K)");

   ------------------------------------------------------------------
   Section ("3. Silent GN / GH; MB endings; PH; WHY");
   ------------------------------------------------------------------
   Check (Enc ("GNU") = "N", "GNU -> N");
   Check (Enc ("SIGNED") = "SNT", "SIGNED -> SNT");
   Check (Enc ("GHENT") = "KNT", "GHENT -> KNT");
   Check (Enc ("BAUGH") = "B", "BAUGH -> B");
   Check (Enc ("COMB") = "KM", "COMB -> KM");
   Check (Enc ("TOMB") = "TM", "TOMB -> TM");
   Check (Enc ("WOMB") = "WM", "WOMB -> WM");
   Check (Enc ("dumb") = "TM", "dumb -> TM");
   Check (Enc ("PHISH") = "FX", "PHISH -> FX");
   Check (Enc_Raises ("WHY"), "WHY encodes empty -> Invalid_Argument");
   Check (Enc_Raises ("why"), "why encodes empty -> Invalid_Argument");

   ------------------------------------------------------------------
   Section ("4. SH / SIO / SIA / TCH / TIO / TIA / TH");
   ------------------------------------------------------------------
   Check (Enc ("SHOT") = "XT", "SHOT -> XT");
   Check (Enc ("ODSIAN") = "OTXN", "ODSIAN -> OTXN");
   Check (Enc ("PULSION") = "PLXN", "PULSION -> PLXN");
   Check (Enc ("RETCH") = "RX", "RETCH -> RX");
   Check (Enc ("WATCH") = "WX", "WATCH -> WX");
   Check (Enc ("OTIA") = "OX", "OTIA -> OX");
   Check (Enc ("PORTION") = "PRXN", "PORTION -> PRXN");
   Check (Enc ("Smith") = "SM0", "Smith -> SM0");
   Check (Enc ("Thomas") = "0MS", "Thomas -> 0MS");
   Check (Enc ("Anthony") = "AN0N", "Anthony -> AN0N");
   Check (Enc ("Katherine") = "K0RN", "Katherine -> K0RN");

   ------------------------------------------------------------------
   Section ("5. DGE / DGI / DGY; truncation; X→KS");
   ------------------------------------------------------------------
   Check (Enc ("DODGY") = "TJ", "DODGY -> TJ");
   Check (Enc ("DODGE") = "TJ", "DODGE -> TJ");
   Check (Enc ("ADGIEMTI") = "AJMT", "ADGIEMTI -> AJMT");
   Check (Enc ("AXEAXE") = "AKSK", "AXEAXE -> AKSK (trunc 4)");
   Check (Enc ("fox") = "FKS", "fox -> FKS (X→KS)");
   Check (Enc ("Xavier") = "SFR", "Xavier -> SFR (initial X→S)");

   ------------------------------------------------------------------
   Section ("6. Well-known names / Commons match clusters");
   ------------------------------------------------------------------
   Check (Enc ("John") = "JN", "John -> JN");
   Check (Enc ("metaphone") = "MTFN", "metaphone -> MTFN");
   Check (Enc ("Lawrence") = "LRNS", "Lawrence -> LRNS");
   Check (Enc ("Gary") = "KR", "Gary -> KR");
   Check (Enc ("Albert") = "ALBR", "Albert -> ALBR");
   Check (Enc ("Mary") = "MR", "Mary -> MR");
   Check (Enc ("Paris") = "PRS", "Paris -> PRS");
   Check (Enc ("Peter") = "PTR", "Peter -> PTR");
   Check (Enc ("Ray") = "R", "Ray -> R");
   Check (Enc ("Susan") = "SSN", "Susan -> SSN");
   Check (Enc ("Wright") = "RT", "Wright -> RT");
   Check (Enc ("Knight") = "NT", "Knight -> NT");
   Check (Enc ("White") = "WT", "White -> WT");
   Check (Enc ("Aero") = "ER", "Aero -> ER");
   Check (Enc ("Xalan") = "SLN", "Xalan -> SLN");
   Check (Enc ("Robert") = "RBRT", "Robert -> RBRT");
   Check (Enc ("William") = "WLM", "William -> WLM");
   Check (Enc ("Michael") = "MXL", "Michael -> MXL");
   Check (Enc ("Jackson") = "JKSN", "Jackson -> JKSN");
   Check (Enc ("phonetics") = "FNTK", "phonetics -> FNTK");

   ------------------------------------------------------------------
   Section ("7. Prefix exceptions KN GN PN AE WR WH X");
   ------------------------------------------------------------------
   Check (Enc ("Knuth") = "N0", "Knuth -> N0");
   Check (Enc ("Gnome") = "NM", "Gnome -> NM");
   Check (Enc ("Pneumonia") = "NMN", "Pneumonia -> NMN");
   Check (Enc ("Aebersold") = "EBRS", "Aebersold -> EBRS");
   Check (Enc ("Wright") = "RT", "Wright prefix WR");
   Check (Enc ("Whalen") = "WLN", "Whalen -> WLN");
   Check (Enc ("Xiaopeng") = "XPNK", "Xiaopeng -> XPNK");

   ------------------------------------------------------------------
   Section ("8. Codes_Match true / false / symmetry");
   ------------------------------------------------------------------
   Check (Match ("John", "Jane"), "John matches Jane (both JN)");
   Check (Match ("Case", "case"), "Case matches case");
   Check (Match ("Lawrence", "Lorenza"), "Lawrence matches Lorenza");
   Check (Match ("Gary", "Cara"), "Gary matches Cara");
   Check (Match ("quick", "cookie"), "quick matches cookie");
   Check (Match ("Smith", "Smythe"), "Smith matches Smythe (SM0)");
   Check (not Match ("John", "Robert"), "John does not match Robert");
   Check (Match ("brown", "BROWN"), "brown matches BROWN");
   Check (Match ("Peter", "Pietro"), "Peter matches Pietro");
   Check (Match ("White", "Wade"), "White matches Wade");
   Check (Match ("Susan", "Zuzana"), "Susan matches Zuzana");
   Check (Match ("A", "A"), "single A matches A");

   ------------------------------------------------------------------
   Section ("9. Case folding and non-letter stripping");
   ------------------------------------------------------------------
   Check (Enc ("JOHN") = "JN", "JOHN -> JN");
   Check (Enc ("john") = "JN", "john -> JN");
   Check (Enc ("JoHn") = "JN", "JoHn -> JN");
   Check (Enc ("J-o-h-n") = "JN", "J-o-h-n -> JN");
   Check (Enc ("J0hn") = "JN", "J0hn digits ignored -> JN");
   Check (Enc ("  John  ") = "JN", "spaces ignored");
   Check (Enc ("O'Brien") = "OBRN", "O'Brien -> OBRN");
   Check (Enc ("McDonald") = "MKTN", "McDonald -> MKTN");
   Check (Enc ("Jo-Ann") = "JN", "Jo-Ann -> JN");

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Enc_Raises (""), "empty -> Invalid_Argument");
   Check (Enc_Raises ("123"), "digits only -> Invalid_Argument");
   Check (Enc_Raises ("---"), "punctuation only -> Invalid_Argument");
   Check (Enc_Raises ("   "), "spaces only -> Invalid_Argument");
   Check (Enc_Raises (Make_Same (Max_Len + 1, 'A')),
          "over Max_Len -> Invalid_Argument");
   Check (not Enc_Raises (Make_Same (Max_Len, 'A')),
          "exactly Max_Len accepted");
   Check (Match_Raises ("", "John"), "Match empty A raises");
   Check (Match_Raises ("John", ""), "Match empty B raises");
   Check (Match_Raises ("123", "456"), "Match letter-free raises");

   ------------------------------------------------------------------
   Section ("11. Single-letter early return; length invariant");
   ------------------------------------------------------------------
   Check (Enc ("A") = "A", "A -> A");
   Check (Enc ("B") = "B", "B -> B");
   Check (Enc ("H") = "H", "H -> H");
   Check (Enc ("Z") = "Z", "Z -> Z");
   Check (Enc ("k") = "K", "k -> K");
   Check (Is_Valid_Code (Enc ("testing")), "testing code valid");
   Check (Is_Valid_Code (Enc ("Smith")), "Smith code contains 0 ok");
   Check (Enc ("testing")'Length <= Max_Code_Len, "testing length <= 4");
   Check (Enc ("AXEAXEAXE")'Length = Max_Code_Len, "long X truncates to 4");

   ------------------------------------------------------------------
   Section ("12. Non-1 String'First slices");
   ------------------------------------------------------------------
   Check (Enc (Slice_Name) = "JN", "slice John -> JN");
   declare
      S : constant String (10 .. 16) := "testing";
   begin
      Check (Enc (S) = "TSTN", "slice testing -> TSTN");
   end;
   declare
      S : constant String (3 .. 7) := "Smith";
   begin
      Check (Enc (S) = "SM0", "slice Smith -> SM0");
   end;

   ------------------------------------------------------------------
   Section ("13. Vowel / W / Y / Q / V / Z / K after C");
   ------------------------------------------------------------------
   Check (Enc ("eagle") = "EKL", "eagle -> EKL");
   --  island: I S L A N D → I,S,L,N,T but trunc 4 → ISLN
   Check (Enc ("island") = "ISLN", "island -> ISLN");
   Check (Enc ("water") = "WTR", "water -> WTR");
   Check (Enc ("yellow") = "YL", "yellow -> YL");
   Check (Enc ("queen") = "KN", "queen -> KN");
   Check (Enc ("voice") = "FS", "voice -> FS");
   Check (Enc ("zebra") = "SBR", "zebra -> SBR");
   Check (Enc ("back") = "BK", "back -> BK (CK: K silent after C)");
   Check (Enc ("school") = "SKL", "school -> SKL");
   Check (Enc ("ghost") = "KST", "ghost -> KST");
   Check (Enc ("rough") = "R", "rough -> R");
   Check (Enc ("cough") = "K", "cough -> K");
   Check (Enc ("enough") = "EN", "enough -> EN");

   ------------------------------------------------------------------
   Section ("14. Bulk alphabet and long inputs");
   ------------------------------------------------------------------
   declare
      Letters : constant String := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   begin
      for I in Letters'Range loop
         declare
            C : constant String := Enc (Letters (I .. I));
         begin
            Check (Is_Valid_Code (C) and then C = Letters (I .. I),
                   "single " & Letters (I .. I) & " -> itself");
         end;
      end loop;
   end;
   Check (Is_Valid_Code (Enc (Make_Alpha (50))), "alpha-50 valid code");
   Check (Enc (Make_Alpha (50))'Length <= Max_Code_Len,
          "alpha-50 length <= 4");
   Check (Is_Valid_Code (Enc (Make_Same (100, 'B'))), "BBB.. valid");
   --  BBB.. duplicates drop → B
   Check (Enc (Make_Same (100, 'B')) = "B", "BBB.. -> B");
   Check (Enc (Make_Same (10, 'C')) = "KKKK",
          "CCCCCCCCCC -> KKKK (C dups kept → K)");

   ------------------------------------------------------------------
   Section ("15. More Commons-style match pairs");
   ------------------------------------------------------------------
   Check (Match ("Knight", "Night"), "Knight matches Night");
   Check (Match ("Wright", "Rite"), "Wright matches Rite");
   Check (Match ("Philips", "Phillips"), "Philips matches Phillips");
   Check (Match ("Catherine", "Katherine"),
          "Catherine matches Katherine");
   Check (Match ("Stephen", "Steven"), "Stephen matches Steven");
   Check (Enc ("Stephen") = "STFN", "Stephen -> STFN");
   Check (Enc ("Steven") = "STFN", "Steven -> STFN");
   Check (Enc ("Phillips") = "FLPS", "Phillips -> FLPS");
   Check (Enc ("Philips") = "FLPS", "Philips -> FLPS");
   Check (not Match ("Caesar", "Cesar"), "Caesar KSR != Cesar SSR");
   Check (Enc ("Caesar") = "KSR", "Caesar -> KSR");
   Check (Enc ("Cesar") = "SSR", "Cesar -> SSR");
   Check (Enc ("Aaron") = "ARN", "Aaron -> ARN");
   Check (Enc ("Byrne") = "BRN", "Byrne -> BRN");
   Check (Match ("brown", "Byrne"), "brown matches Byrne");

   ------------------------------------------------------------------
   Section ("16. Truncation / capacity smoke");
   ------------------------------------------------------------------
   Check (Enc ("CHARACTER") = "XRKT",
          "CHARACTER -> XRKT (trunc 4; Commons-5 would be XRKTR)");
   Check (B (Enc ("AXEAXE") = "AKSK"), "AXEAXE via B wrapper");
   Check (Enc (Make_Alpha (200))'Length <= Max_Code_Len,
          "200-letter truncated to Max_Code_Len");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS,"
             & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
