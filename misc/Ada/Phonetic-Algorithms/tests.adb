--  Standalone test suite for Phonetic_Algorithms (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Phonetic_Algorithms; use Phonetic_Algorithms;

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
   function N (X : Natural) return Natural is (X);
   function B (X : Boolean) return Boolean is (X);

   function Sdx (Name : String) return String is (Soundex (Name));
   function Nys (Name : String) return String is (NYSIIS (Name));
   function Mph (Word : String) return String is (Metaphone (Word));
   function Mra (Name : String) return String is (Match_Rating_Encode (Name));

   function Sdx_Match (A, B : String) return Boolean is
     (Codes_Match_Soundex (A, B));
   function Nys_Match (A, B : String) return Boolean is
     (Codes_Match_NYSIIS (A, B));
   function Mph_Match (A, B : String) return Boolean is
     (Codes_Match_Metaphone (A, B));

   function Sdx_Raises (Name : String) return Boolean is
      Unused : String (1 .. 4);
   begin
      Unused := Soundex (Name);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Sdx_Raises;

   function Nys_Raises (Name : String) return Boolean is
   begin
      declare
         Unused : constant String := NYSIIS (Name);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Nys_Raises;

   function Mph_Raises (Word : String) return Boolean is
   begin
      declare
         Unused : constant String := Metaphone (Word);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Mph_Raises;

   function Mra_Raises (Name : String) return Boolean is
   begin
      declare
         Unused : constant String := Match_Rating_Encode (Name);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Mra_Raises;

   function Match_Sdx_Raises (A, B : String) return Boolean is
      Unused : Boolean;
   begin
      Unused := Codes_Match_Soundex (A, B);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Match_Sdx_Raises;

   function Overlong return String is
      Buf : String (1 .. Max_Len + 1);
   begin
      for I in Buf'Range loop
         Buf (I) := 'A';
      end loop;
      return Buf;
   end Overlong;

   function Slice_Robert return String is
      Buf : constant String (5 .. 10) := "Robert";
   begin
      return Buf;
   end Slice_Robert;

   function Slice_John return String is
      Buf : constant String (5 .. 8) := "John";
   begin
      return Buf;
   end Slice_John;

   function Slice_Byrne return String is
      Buf : constant String (5 .. 9) := "Byrne";
   begin
      return Buf;
   end Slice_Byrne;

   function Slice_Bishop return String is
      Buf : constant String (5 .. 10) := "Bishop";
   begin
      return Buf;
   end Slice_Bishop;

begin
   Put_Line ("Phonetic_Algorithms survey test suite");
   Put_Line ("Max_Len =" & Max_Len'Image);
   Put_Line ("Encoders: Soundex, NYSIIS, Metaphone, Match_Rating_Encode");

   ------------------------------------------------------------------
   Section ("Soundex — classic American / NARA");
   ------------------------------------------------------------------
   Check (Sdx ("Robert") = "R163", "Soundex Robert -> R163");
   Check (Sdx ("Rupert") = "R163", "Soundex Rupert -> R163");
   Check (Sdx ("Rubin") = "R150", "Soundex Rubin -> R150");
   Check (Sdx ("Ashcraft") = "A261", "Soundex Ashcraft -> A261");
   Check (Sdx ("Ashcroft") = "A261", "Soundex Ashcroft -> A261");
   Check (Sdx ("Tymczak") = "T522", "Soundex Tymczak -> T522");
   Check (Sdx ("Pfister") = "P236", "Soundex Pfister -> P236");
   Check (Sdx ("Honeyman") = "H555", "Soundex Honeyman -> H555");
   Check (Sdx ("Euler") = "E460", "Soundex Euler -> E460");
   Check (Sdx ("Ellery") = "E460", "Soundex Ellery -> E460");
   Check (Sdx ("Gauss") = "G200", "Soundex Gauss -> G200");
   Check (Sdx ("Ghosh") = "G200", "Soundex Ghosh -> G200");
   Check (Sdx ("Hilbert") = "H416", "Soundex Hilbert -> H416");
   Check (Sdx ("Heilbronn") = "H416", "Soundex Heilbronn -> H416");
   Check (Sdx ("Knuth") = "K530", "Soundex Knuth -> K530");
   Check (Sdx ("Kant") = "K530", "Soundex Kant -> K530");
   Check (Sdx ("Lloyd") = "L300", "Soundex Lloyd -> L300");
   Check (Sdx ("Ladd") = "L300", "Soundex Ladd -> L300");
   Check (Sdx ("Lukasiewicz") = "L222", "Soundex Lukasiewicz -> L222");
   Check (Sdx ("Lissajous") = "L222", "Soundex Lissajous -> L222");
   Check (Sdx ("Williams") = "W452", "Soundex Williams -> W452");
   Check (Sdx ("Smith") = "S530", "Soundex Smith -> S530");
   Check (Sdx ("Smyth") = "S530", "Soundex Smyth -> S530");
   Check (Sdx ("Jackson") = "J250", "Soundex Jackson -> J250");
   Check (Sdx ("Johnson") = "J525", "Soundex Johnson -> J525");
   Check (Sdx ("Jones") = "J520", "Soundex Jones -> J520");
   Check (Sdx ("Bauer") = "B600", "Soundex Bauer -> B600");
   Check (Sdx ("Wheaton") = "W350", "Soundex Wheaton -> W350");
   Check (Sdx ("Burroughs") = "B620", "Soundex Burroughs -> B620");
   Check (Sdx ("Burrows") = "B620", "Soundex Burrows -> B620");
   Check (Sdx ("O'Hara") = "O600", "Soundex O'Hara -> O600");
   Check (Sdx ("Washington") = "W252", "Soundex Washington -> W252");
   Check (Sdx ("Lee") = "L000", "Soundex Lee -> L000");
   Check (Sdx ("Gutierrez") = "G362", "Soundex Gutierrez -> G362");
   Check (Sdx ("Donnell") = "D540", "Soundex Donnell -> D540");
   Check (Sdx ("Baragwanath") = "B625", "Soundex Baragwanath -> B625");
   Check (Sdx ("Schmidt") = "S530", "Soundex Schmidt -> S530");
   Check (Sdx ("A") = "A000", "Soundex A -> A000");
   Check (Sdx ("Z") = "Z000", "Soundex Z -> Z000");

   ------------------------------------------------------------------
   Section ("Soundex — case, non-letters, length, H/W");
   ------------------------------------------------------------------
   Check (Sdx ("robert") = "R163", "Soundex lowercase robert");
   Check (Sdx ("ROBERT") = "R163", "Soundex uppercase ROBERT");
   Check (Sdx ("RoBeRt") = "R163", "Soundex mixed RoBeRt");
   Check (Sdx ("  Robert  ") = "R163", "Soundex spaces ignored");
   Check (Sdx ("123Robert") = "R163", "Soundex leading digits");
   Check (Sdx ("Robert456") = "R163", "Soundex trailing digits");
   Check (Sdx ("Rob ert") = "R163", "Soundex internal space");
   Check (Sdx ("Ashcraft")'Length = N (4), "Soundex always length 4");
   Check (Sdx ("Lee")'Length = N (4), "Soundex Lee length 4");
   Check (Sdx (Slice_Robert) = "R163", "Soundex non-1'First slice");
   Check (Sdx ("Ashcraft") = "A261", "Soundex H/W non-separating Ashcraft");

   ------------------------------------------------------------------
   Section ("Soundex — Codes_Match_Soundex");
   ------------------------------------------------------------------
   Check (B (Sdx_Match ("Robert", "Rupert")), "Soundex match Robert/Rupert");
   Check (B (Sdx_Match ("Robert", "robert")), "Soundex match case fold");
   Check (B (Sdx_Match ("Ashcraft", "Ashcroft")), "Soundex match Ashcraft/Ashcroft");
   Check (B (Sdx_Match ("Smith", "Smyth")), "Soundex match Smith/Smyth");
   Check (B (Sdx_Match ("Schmidt", "Smith")), "Soundex match Schmidt/Smith");
   Check (B (not Sdx_Match ("Robert", "Rubin")), "Soundex no-match Robert/Rubin");
   Check (B (not Sdx_Match ("Smith", "Jones")), "Soundex no-match Smith/Jones");
   Check (B (Sdx_Match ("Robert", "Robert")), "Soundex reflexive");
   Check (B (Sdx_Match ("Robert", "Rupert") = Sdx_Match ("Rupert", "Robert")),
          "Soundex symmetric");

   ------------------------------------------------------------------
   Section ("Soundex — Invalid_Argument");
   ------------------------------------------------------------------
   Check (B (Sdx_Raises ("")), "Soundex empty raises");
   Check (B (Sdx_Raises ("123")), "Soundex digit-only raises");
   Check (B (Sdx_Raises ("!!!")), "Soundex punctuation-only raises");
   Check (B (Sdx_Raises (Overlong)), "Soundex overlong raises");
   Check (B (not Sdx_Raises ("Robert")), "Soundex Robert does not raise");
   Check (B (Match_Sdx_Raises ("", "Robert")), "Soundex match empty A raises");
   Check (B (Match_Sdx_Raises ("Robert", "")), "Soundex match empty B raises");

   ------------------------------------------------------------------
   Section ("NYSIIS — Commons / Taft golden");
   ------------------------------------------------------------------
   Check (Nys ("MACINTOSH") = "MCANT", "NYSIIS MACINTOSH -> MCANT");
   Check (Nys ("KNUTH") = "NAT", "NYSIIS KNUTH -> NAT");
   Check (Nys ("KOEHN") = "CAN", "NYSIIS KOEHN -> CAN");
   Check (Nys ("PHILLIPSON") = "FALAPS", "NYSIIS PHILLIPSON -> FALAPS");
   Check (Nys ("PFEISTER") = "FASTAR", "NYSIIS PFEISTER -> FASTAR");
   Check (Nys ("SCHOENHOEFT") = "SANAFT", "NYSIIS SCHOENHOEFT -> SANAFT");
   Check (Nys ("MCKEE") = "MCY", "NYSIIS MCKEE -> MCY");
   Check (Nys ("MACKIE") = "MCY", "NYSIIS MACKIE -> MCY");
   Check (Nys ("HEITSCHMIDT") = "HATSNA", "NYSIIS HEITSCHMIDT -> HATSNA");
   Check (Nys ("BART") = "BAD", "NYSIIS BART -> BAD");
   Check (Nys ("HURD") = "HAD", "NYSIIS HURD -> HAD");
   Check (Nys ("HUNT") = "HAD", "NYSIIS HUNT -> HAD");
   Check (Nys ("WESTERLUND") = "WASTAR", "NYSIIS WESTERLUND -> WASTAR");
   Check (Nys ("CASSTEVENS") = "CASTAF", "NYSIIS CASSTEVENS -> CASTAF");
   Check (Nys ("VASQUEZ") = "VASG", "NYSIIS VASQUEZ -> VASG");
   Check (Nys ("FRAZIER") = "FRASAR", "NYSIIS FRAZIER -> FRASAR");
   Check (Nys ("BOWMAN") = "BANAN", "NYSIIS BOWMAN -> BANAN");
   Check (Nys ("MCKNIGHT") = "MCNAGT", "NYSIIS MCKNIGHT -> MCNAGT");
   Check (Nys ("RICKERT") = "RACAD", "NYSIIS RICKERT -> RACAD");
   Check (Nys ("DEUTSCH") = "DAT", "NYSIIS DEUTSCH -> DAT");
   Check (Nys ("WESTPHAL") = "WASTFA", "NYSIIS WESTPHAL -> WASTFA");
   Check (Nys ("SHRIVER") = "SRAVAR", "NYSIIS SHRIVER -> SRAVAR");
   Check (Nys ("KUHL") = "CAL", "NYSIIS KUHL -> CAL");
   Check (Nys ("RAWSON") = "RASAN", "NYSIIS RAWSON -> RASAN");
   Check (Nys ("JILES") = "JAL", "NYSIIS JILES -> JAL");
   Check (Nys ("CARRAWAY") = "CARY", "NYSIIS CARRAWAY -> CARY");
   Check (Nys ("YAMADA") = "YANAD", "NYSIIS YAMADA -> YANAD");
   Check (Nys ("Bishop") = "BASAP", "NYSIIS Bishop -> BASAP");
   Check (Nys ("Willis") = "WAL", "NYSIIS Willis -> WAL");
   Check (Nys ("Ash") = "A", "NYSIIS Ash -> A");
   Check (Nys ("Smith") = "SNAT", "NYSIIS Smith -> SNAT");
   Check (Nys ("Schmit") = "SNAT", "NYSIIS Schmit -> SNAT");
   Check (Nys ("Schmidt") = "SNAD", "NYSIIS Schmidt -> SNAD");
   Check (Nys ("Brian") = "BRAN", "NYSIIS Brian -> BRAN");
   Check (Nys ("Brown") = "BRAN", "NYSIIS Brown -> BRAN");
   Check (Nys ("Phil") = "FAL", "NYSIIS Phil -> FAL");
   Check (Nys ("O'Brien") = "OBRAN", "NYSIIS O'Brien -> OBRAN");
   Check (Nys ("Wheeler") = "WALAR", "NYSIIS Wheeler -> WALAR");
   Check (Nys ("knight") = "NAGT", "NYSIIS knight -> NAGT");
   Check (Nys ("FUZZY") = "FASY", "NYSIIS FUZZY -> FASY");
   Check (Nys ("Cory") = "CARY", "NYSIIS Cory -> CARY");
   Check (Nys ("Corey") = "CARY", "NYSIIS Corey -> CARY");
   Check (Nys ("Kory") = "CARY", "NYSIIS Kory -> CARY");
   Check (Nys ("A") = "A", "NYSIIS single A");
   Check (Nys ("B") = "B", "NYSIIS single B");

   ------------------------------------------------------------------
   Section ("NYSIIS — truncation, case, match");
   ------------------------------------------------------------------
   Check (Nys ("PHILLIPSON")'Length <= N (6), "NYSIIS max length 6");
   Check (Nys ("Carlson") = "CARLSA", "NYSIIS Carlson -> CARLSA");
   Check (Nys ("bishop") = "BASAP", "NYSIIS lowercase");
   Check (Nys ("BiShOp") = "BASAP", "NYSIIS mixed case");
   Check (Nys (Slice_Bishop) = "BASAP", "NYSIIS non-1'First slice");
   Check (B (Nys_Match ("Smith", "Schmit")), "NYSIIS match Smith/Schmit");
   Check (B (Nys_Match ("Brian", "Brown")), "NYSIIS match Brian/Brown");
   Check (B (Nys_Match ("Cory", "Kory")), "NYSIIS match Cory/Kory");
   Check (B (not Nys_Match ("Bishop", "Willis")), "NYSIIS no-match Bishop/Willis");
   Check (B (Nys_Match ("Bishop", "bishop")), "NYSIIS case-insensitive match");
   Check (B (Nys_Raises ("")), "NYSIIS empty raises");
   Check (B (Nys_Raises ("123")), "NYSIIS digit-only raises");
   Check (B (Nys_Raises (Overlong)), "NYSIIS overlong raises");
   Check (B (not Nys_Raises ("Bishop")), "NYSIIS Bishop does not raise");

   ------------------------------------------------------------------
   Section ("Metaphone — Commons / Philips golden");
   ------------------------------------------------------------------
   Check (Mph ("howl") = "HL", "Metaphone howl -> HL");
   Check (Mph ("testing") = "TSTN", "Metaphone testing -> TSTN");
   Check (Mph ("The") = "0", "Metaphone The -> 0");
   Check (Mph ("quick") = "KK", "Metaphone quick -> KK");
   Check (Mph ("brown") = "BRN", "Metaphone brown -> BRN");
   Check (Mph ("fox") = "FKS", "Metaphone fox -> FKS");
   Check (Mph ("jumped") = "JMPT", "Metaphone jumped -> JMPT");
   Check (Mph ("over") = "OFR", "Metaphone over -> OFR");
   Check (Mph ("lazy") = "LS", "Metaphone lazy -> LS");
   Check (Mph ("dogs") = "TKS", "Metaphone dogs -> TKS");
   Check (Mph ("Schmidt") = "SKMT", "Metaphone Schmidt -> SKMT");
   Check (Mph ("Smith") = "SM0", "Metaphone Smith -> SM0");
   Check (Mph ("John") = "JN", "Metaphone John -> JN");
   Check (Mph ("Robert") = "RBRT", "Metaphone Robert -> RBRT");
   Check (Mph ("Thomas") = "0MS", "Metaphone Thomas -> 0MS");
   Check (Mph ("Anthony") = "AN0N", "Metaphone Anthony -> AN0N");
   Check (Mph ("Katherine") = "K0RN", "Metaphone Katherine -> K0RN");
   Check (Mph ("metaphone") = "MTFN", "Metaphone metaphone -> MTFN");
   Check (Mph ("Lawrence") = "LRNS", "Metaphone Lawrence -> LRNS");
   Check (Mph ("Gary") = "KR", "Metaphone Gary -> KR");
   Check (Mph ("Albert") = "ALBR", "Metaphone Albert -> ALBR");
   Check (Mph ("Mary") = "MR", "Metaphone Mary -> MR");
   Check (Mph ("Paris") = "PRS", "Metaphone Paris -> PRS");
   Check (Mph ("Peter") = "PTR", "Metaphone Peter -> PTR");
   Check (Mph ("Ray") = "R", "Metaphone Ray -> R");
   Check (Mph ("Susan") = "SSN", "Metaphone Susan -> SSN");
   Check (Mph ("Wright") = "RT", "Metaphone Wright -> RT");
   Check (Mph ("Knight") = "NT", "Metaphone Knight -> NT");
   Check (Mph ("White") = "WT", "Metaphone White -> WT");
   Check (Mph ("Aero") = "ER", "Metaphone Aero -> ER");
   Check (Mph ("Xavier") = "SFR", "Metaphone Xavier -> SFR");
   Check (Mph ("William") = "WLM", "Metaphone William -> WLM");
   Check (Mph ("Michael") = "MXL", "Metaphone Michael -> MXL");
   Check (Mph ("Jackson") = "JKSN", "Metaphone Jackson -> JKSN");
   Check (Mph ("phonetics") = "FNTK", "Metaphone phonetics -> FNTK");
   Check (Mph ("Knuth") = "N0", "Metaphone Knuth -> N0");
   Check (Mph ("Gnome") = "NM", "Metaphone Gnome -> NM");
   Check (Mph ("Pneumonia") = "NMN", "Metaphone Pneumonia -> NMN");
   Check (Mph ("Aebersold") = "EBRS", "Metaphone Aebersold -> EBRS");
   Check (Mph ("Whalen") = "WLN", "Metaphone Whalen -> WLN");
   Check (Mph ("SCIENCE") = "SNS", "Metaphone SCIENCE -> SNS");
   Check (Mph ("ECHO") = "EX", "Metaphone ECHO -> EX");
   Check (Mph ("CITY") = "ST", "Metaphone CITY -> ST");
   Check (Mph ("CAT") = "KT", "Metaphone CAT -> KT");
   Check (Mph ("CIAO") = "X", "Metaphone CIAO -> X");
   Check (Mph ("COMB") = "KM", "Metaphone COMB -> KM");
   Check (Mph ("PHISH") = "FX", "Metaphone PHISH -> FX");
   Check (Mph ("SHOT") = "XT", "Metaphone SHOT -> XT");
   Check (Mph ("DODGE") = "TJ", "Metaphone DODGE -> TJ");
   Check (Mph ("BAUGH") = "B", "Metaphone BAUGH -> B");
   Check (Mph ("Byrne") = "BRN", "Metaphone Byrne -> BRN");
   Check (Mph ("O'Brien") = "OBRN", "Metaphone O'Brien -> OBRN");
   Check (Mph ("McDonald") = "MKTN", "Metaphone McDonald -> MKTN");
   Check (Mph ("A") = "A", "Metaphone A -> A");
   Check (Mph ("B") = "B", "Metaphone B -> B");
   Check (Mph ("eagle") = "EKL", "Metaphone eagle -> EKL");

   ------------------------------------------------------------------
   Section ("Metaphone — truncation, case, match, raises");
   ------------------------------------------------------------------
   Check (Mph ("testing")'Length <= N (4), "Metaphone max length 4");
   Check (Mph ("AXEAXEAXE")'Length = N (4), "Metaphone long X truncates");
   Check (Mph ("john") = "JN", "Metaphone lowercase");
   Check (Mph ("JOHN") = "JN", "Metaphone uppercase");
   Check (Mph ("  John  ") = "JN", "Metaphone spaces");
   Check (Mph ("J-o-h-n") = "JN", "Metaphone punctuation");
   Check (Mph (Slice_John) = "JN", "Metaphone non-1'First slice");
   Check (B (Mph_Match ("John", "Jane")), "Metaphone match John/Jane");
   Check (B (Mph_Match ("Smith", "Smythe")), "Metaphone match Smith/Smythe");
   Check (B (Mph_Match ("brown", "Byrne")), "Metaphone match brown/Byrne");
   Check (B (not Mph_Match ("John", "Robert")), "Metaphone no-match John/Robert");
   Check (B (Mph_Raises ("")), "Metaphone empty raises");
   Check (B (Mph_Raises ("123")), "Metaphone digit-only raises");
   Check (B (Mph_Raises ("WHY")), "Metaphone WHY empty-code raises");
   Check (B (Mph_Raises (Overlong)), "Metaphone overlong raises");
   Check (B (not Mph_Raises ("John")), "Metaphone John does not raise");

   ------------------------------------------------------------------
   Section ("Match_Rating_Encode — Western Airlines / Wikipedia");
   ------------------------------------------------------------------
   Check (Mra ("Byrne") = "BYRN", "MRA Byrne -> BYRN");
   Check (Mra ("Boern") = "BRN", "MRA Boern -> BRN");
   Check (Mra ("Smith") = "SMTH", "MRA Smith -> SMTH");
   Check (Mra ("Smyth") = "SMYTH", "MRA Smyth -> SMYTH");
   Check (Mra ("Catherine") = "CTHRN", "MRA Catherine -> CTHRN");
   Check (Mra ("Kathryn") = "KTHRYN", "MRA Kathryn -> KTHRYN");
   Check (Mra ("Lloyd") = "LYD", "MRA Lloyd -> LYD");
   Check (Mra ("Aaron") = "ARN", "MRA Aaron -> ARN");
   Check (Mra ("Alice") = "ALC", "MRA Alice -> ALC");
   Check (Mra ("Alicia") = "ALC", "MRA Alicia -> ALC");
   Check (Mra ("Gottlieb") = "GTLB", "MRA Gottlieb -> GTLB");
   Check (Mra ("Pfeiffer") = "PFR", "MRA Pfeiffer -> PFR");
   Check (Mra ("Bookkeeper") = "BKPR", "MRA Bookkeeper -> BKPR");
   Check (Mra ("Wright") = "WRGHT", "MRA Wright -> WRGHT");
   Check (Mra ("Macintosh") = "MCNTSH", "MRA Macintosh -> MCNTSH");
   Check (Mra ("Washington") = "WSHGTN", "MRA Washington -> WSHGTN");
   Check (Mra ("Alexander") = "ALXNDR", "MRA Alexander -> ALXNDR");
   Check (Mra ("Elizabeth") = "ELZBTH", "MRA Elizabeth -> ELZBTH");
   Check (Mra ("Christopher") = "CHRPHR", "MRA Christopher -> CHRPHR");
   Check (Mra ("B") = "B", "MRA B -> B");
   Check (Mra ("A") = "A", "MRA A -> A");
   Check (Mra ("Y") = "Y", "MRA Y -> Y");
   Check (Mra ("Lee") = "L", "MRA Lee -> L");
   Check (Mra ("Ai") = "A", "MRA Ai -> A");
   Check (Mra ("Edgar") = "EDGR", "MRA Edgar -> EDGR");
   Check (Mra ("Otto") = "OT", "MRA Otto -> OT");
   Check (Mra ("Irene") = "IRN", "MRA Irene -> IRN");
   Check (Mra ("Ursula") = "URSL", "Mra Ursula -> URSL");
   Check (Mra ("Owen") = "OWN", "MRA Owen -> OWN");
   Check (Mra ("Eagle") = "EGL", "MRA Eagle -> EGL");
   Check (Mra ("Yvonne") = "YVN", "MRA Yvonne -> YVN");
   Check (Mra ("Mary") = "MRY", "MRA Mary -> MRY");
   Check (Mra ("Kelly") = "KLY", "MRA Kelly -> KLY");
   Check (Mra ("Billy") = "BLY", "MRA Billy -> BLY");
   Check (Mra ("Bobby") = "BY", "MRA Bobby -> BY");
   Check (Mra ("Tommy") = "TMY", "MRA Tommy -> TMY");
   Check (Mra ("Jenny") = "JNY", "MRA Jenny -> JNY");
   Check (Mra ("Harris") = "HRS", "MRA Harris -> HRS");
   Check (Mra ("Williams") = "WLMS", "MRA Williams -> WLMS");
   Check (Mra ("Mississippi") = "MSP", "MRA Mississippi -> MSP");
   Check (Mra ("Bartholomew") = "BRTLMW", "MRA Bartholomew truncated");
   Check (Mra ("Montgomery") = "MNTMRY", "MRA Montgomery truncated");
   Check (Mra ("Fitzgerald") = "FTZRLD", "MRA Fitzgerald truncated");
   Check (Mra ("AB") = "AB", "MRA AB -> AB");
   Check (Mra ("BA") = "B", "MRA BA -> B");
   Check (Mra ("AEIOU") = "A", "MRA AEIOU -> A");

   ------------------------------------------------------------------
   Section ("Match_Rating_Encode — case, length, raises");
   ------------------------------------------------------------------
   Check (Mra ("smith") = "SMTH", "MRA lowercase");
   Check (Mra ("SMITH") = "SMTH", "MRA uppercase");
   Check (Mra ("SmItH") = "SMTH", "MRA mixed");
   Check (Mra ("S m i t h") = "SMTH", "MRA spaces");
   Check (Mra ("S-m.i'th") = "SMTH", "MRA punctuation");
   Check (Mra ("123Smith456") = "SMTH", "MRA digits");
   Check (Mra ("  Byrne  ") = "BYRN", "MRA trim spaces");
   Check (Mra (Slice_Byrne) = "BYRN", "MRA non-1'First slice");
   Check (Mra ("Washington")'Length = N (6), "MRA Washington length 6");
   Check (Mra ("Christopher")'Length = N (6), "MRA Christopher length 6");
   Check (Mra ("A")'Length = N (1), "MRA A length 1");
   Check (Mra ("Smith")'Length <= N (6), "MRA Smith <= 6");
   Check (B (Mra_Raises ("")), "MRA empty raises");
   Check (B (Mra_Raises ("123")), "MRA digit-only raises");
   Check (B (Mra_Raises (Overlong)), "MRA overlong raises");
   Check (B (not Mra_Raises ("Byrne")), "MRA Byrne does not raise");

   ------------------------------------------------------------------
   Section ("Cross-encoder survey smoke");
   ------------------------------------------------------------------
   Check (Sdx ("Smith") = "S530", "survey Smith Soundex");
   Check (Nys ("Smith") = "SNAT", "survey Smith NYSIIS");
   Check (Mph ("Smith") = "SM0", "survey Smith Metaphone");
   Check (Mra ("Smith") = "SMTH", "survey Smith MRA");
   Check (Sdx ("Robert") /= Nys ("Robert"), "Soundex != NYSIIS strings");
   Check (Mph ("Smith") /= Mra ("Smith"), "Metaphone != MRA strings");
   Check (B (Sdx_Match ("Smith", "Smyth")), "survey Soundex Smith~Smyth");
   Check (B (Mph_Match ("Smith", "Smythe")), "survey Metaphone Smith~Smythe");
   Check (B (Nys_Match ("Cory", "Corey")), "survey NYSIIS Cory~Corey");
   Check (Sdx ("Ashcraft") (1) in 'A' .. 'Z', "Soundex leading letter");
   Check (Sdx ("Ashcraft") (2) in '0' .. '6', "Soundex digit 2");
   Check (Sdx ("Ashcraft") (3) in '0' .. '6', "Soundex digit 3");
   Check (Sdx ("Ashcraft") (4) in '0' .. '6', "Soundex digit 4");
   Check (Mph ("Smith") (3) = '0', "Metaphone TH as digit 0");
   Check (Nys ("Ash")'Length = N (1), "NYSIIS Ash length 1");
   Check (Mra ("Macintosh")'Length = N (6), "MRA Macintosh length 6");

   ------------------------------------------------------------------
   Section ("Summary");
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASS");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILURES");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
