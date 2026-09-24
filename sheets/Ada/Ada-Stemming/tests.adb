--  Standalone test suite for Stemming (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Stemming; use Stemming;

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

   procedure Expect_Porter (Word, Stem : String) is
      Got : constant String := Porter_Stem (Word);
   begin
      Check (Got = Stem,
             "Porter(""" & Word & """) = """ & Stem & """ (got """ & Got & """)");
   end Expect_Porter;

   procedure Expect_Simple (Word, Stem : String) is
      Got : constant String := Simple_Stem (Word);
   begin
      Check (Got = Stem,
             "Simple(""" & Word & """) = """ & Stem & """ (got """ & Got & """)");
   end Expect_Simple;

begin
   Put_Line ("Stemming test suite (Porter 1980 + Simple_Stem)");
   Put_Line ("===============================================");

   ---------------------------------------------------------------------
   Section ("1. To_Lower / Is_Vowel / case normalization");
   ---------------------------------------------------------------------
   Check (To_Lower ('A') = 'a', "To_Lower('A')=a");
   Check (To_Lower ('Z') = 'z', "To_Lower('Z')=z");
   Check (To_Lower ('m') = 'm', "To_Lower('m')=m");
   Check (To_Lower ('3') = '3', "To_Lower digit unchanged");
   Check (To_Lower ("MiXeD") = "mixed", "To_Lower string");
   Check (To_Lower ("") = "", "To_Lower empty");
   Check (Is_Vowel ('a') and Is_Vowel ('E') and Is_Vowel ('i')
            and Is_Vowel ('O') and Is_Vowel ('u'),
          "Is_Vowel aeiou");
   Check (not Is_Vowel ('y') and not Is_Vowel ('Y'),
          "Is_Vowel rejects bare y (contextual elsewhere)");
   Check (not Is_Vowel ('b') and not Is_Vowel ('Z'),
          "Is_Vowel rejects consonants");
   Check (Porter_Stem ("CATS") = "cat", "case: CATS→cat");
   Check (Porter_Stem ("Fishing") = "fish", "case: Fishing→fish");
   Check (Stem_Word ("ARGUING") = Porter_Stem ("arguing"),
          "Stem_Word alias matches Porter");

   ---------------------------------------------------------------------
   Section ("2. Measure_M / consonant helpers");
   ---------------------------------------------------------------------
   Check (Measure_M ("") = 0, "m("""")=0");
   Check (Measure_M ("tr") = 0, "m(tr)=0");
   Check (Measure_M ("ee") = 0, "m(ee)=0");
   Check (Measure_M ("tree") = 0, "m(tree)=0");
   Check (Measure_M ("y") = 0, "m(y)=0");
   Check (Measure_M ("by") = 0, "m(by)=0");
   Check (Measure_M ("trouble") = 1, "m(trouble)=1");
   Check (Measure_M ("oats") = 1, "m(oats)=1");
   Check (Measure_M ("trees") = 1, "m(trees)=1");
   Check (Measure_M ("ivy") = 1, "m(ivy)=1");
   Check (Measure_M ("troubles") = 2, "m(troubles)=2");
   Check (Measure_M ("private") = 2, "m(private)=2");
   Check (Measure_M ("oaten") = 2, "m(oaten)=2");
   Check (Measure_M ("orrery") = 2, "m(orrery)=2");
   Check (Contains_Vowel ("fish"), "Contains_Vowel(fish)");
   Check (not Contains_Vowel ("sky") or Contains_Vowel ("sky"),
          "Contains_Vowel(sky) defined");
   --  sky: s=c, k=c, y=vowel (preceded by consonant) → has vowel
   Check (Contains_Vowel ("sky"), "sky has contextual vowel y");
   Check (Ends_Double_Consonant ("hopp"), "Ends_Double_Consonant hopp");
   Check (not Ends_Double_Consonant ("hop"), "not double hop");
   Check (Ends_CVC ("fil"), "Ends_CVC fil");
   Check (not Ends_CVC ("fail"), "not Ends_CVC fail (ends ail=vvc/..)");
   Check (Is_Consonant_At ("toy", 1), "t consonant in toy");
   Check (not Is_Consonant_At ("toy", 2), "o vowel in toy");
   Check (Is_Consonant_At ("toy", 3), "y consonant after vowel in toy");

   ---------------------------------------------------------------------
   Section ("3. Classic Wikipedia / Porter examples");
   ---------------------------------------------------------------------
   Expect_Porter ("cats", "cat");
   Expect_Porter ("fishing", "fish");
   Expect_Porter ("fished", "fish");
   --  Classic Porter does not strip -er when m(stem)=1; fisher stays fisher.
   Expect_Porter ("fisher", "fisher");
   Expect_Porter ("argue", "argu");
   Expect_Porter ("argued", "argu");
   Expect_Porter ("argues", "argu");
   Expect_Porter ("arguing", "argu");
   Expect_Porter ("argus", "argu");

   ---------------------------------------------------------------------
   Section ("4. Step 1a plurals");
   ---------------------------------------------------------------------
   Expect_Porter ("caresses", "caress");
   Expect_Porter ("ponies", "poni");
   Expect_Porter ("ties", "ti");
   Expect_Porter ("caress", "caress");
   Expect_Porter ("cats", "cat");
   Expect_Porter ("dogs", "dog");
   Expect_Porter ("miss", "miss");

   ---------------------------------------------------------------------
   Section ("5. Step 1b past / progressive");
   ---------------------------------------------------------------------
   Expect_Porter ("feed", "feed");
   Expect_Porter ("agreed", "agre");
   Expect_Porter ("plastered", "plaster");
   Expect_Porter ("bled", "bled");
   Expect_Porter ("motoring", "motor");
   Expect_Porter ("sing", "sing");
   Expect_Porter ("conflated", "conflat");
   Expect_Porter ("troubled", "troubl");
   Expect_Porter ("sized", "size");
   Expect_Porter ("hopping", "hop");
   Expect_Porter ("tanned", "tan");
   Expect_Porter ("falling", "fall");
   Expect_Porter ("hissing", "hiss");
   Expect_Porter ("fizzed", "fizz");
   Expect_Porter ("failing", "fail");
   Expect_Porter ("filing", "file");

   ---------------------------------------------------------------------
   Section ("6. Step 1c Y→I");
   ---------------------------------------------------------------------
   Expect_Porter ("happy", "happi");
   Expect_Porter ("sky", "sky");

   ---------------------------------------------------------------------
   Section ("7. Steps 2–3 derivational");
   ---------------------------------------------------------------------
   Expect_Porter ("relational", "relat");
   Expect_Porter ("conditional", "condit");
   Expect_Porter ("rational", "ration");
   Expect_Porter ("valenci", "valenc");
   Expect_Porter ("hesitanci", "hesit");
   Expect_Porter ("digitizer", "digit");
   Expect_Porter ("conformabli", "conform");
   Expect_Porter ("radicalli", "radic");
   Expect_Porter ("differentli", "differ");
   Expect_Porter ("vileli", "vile");
   Expect_Porter ("analogousli", "analog");
   Expect_Porter ("vietnamization", "vietnam");
   Expect_Porter ("predication", "predic");
   Expect_Porter ("operator", "oper");
   Expect_Porter ("feudalism", "feudal");
   Expect_Porter ("decisiveness", "decis");
   Expect_Porter ("hopefulness", "hope");
   Expect_Porter ("callousness", "callous");
   Expect_Porter ("formaliti", "formal");
   Expect_Porter ("sensitiviti", "sensit");
   Expect_Porter ("sensibiliti", "sensibl");
   Expect_Porter ("triplicate", "triplic");
   Expect_Porter ("formative", "form");
   Expect_Porter ("formalize", "formal");
   Expect_Porter ("electriciti", "electr");
   Expect_Porter ("electrical", "electr");
   Expect_Porter ("hopeful", "hope");
   Expect_Porter ("goodness", "good");

   ---------------------------------------------------------------------
   Section ("8. Step 4 / 5 cleanup");
   ---------------------------------------------------------------------
   Expect_Porter ("revival", "reviv");
   Expect_Porter ("allowance", "allow");
   Expect_Porter ("inference", "infer");
   Expect_Porter ("airliner", "airlin");
   Expect_Porter ("gyroscopic", "gyroscop");
   Expect_Porter ("adjustable", "adjust");
   Expect_Porter ("defensible", "defens");
   Expect_Porter ("irritant", "irrit");
   Expect_Porter ("replacement", "replac");
   Expect_Porter ("adjustment", "adjust");
   Expect_Porter ("dependent", "depend");
   Expect_Porter ("adoption", "adopt");
   Expect_Porter ("homologou", "homolog");
   Expect_Porter ("communism", "commun");
   Expect_Porter ("activate", "activ");
   Expect_Porter ("angulariti", "angular");
   Expect_Porter ("homologous", "homolog");
   Expect_Porter ("effective", "effect");
   Expect_Porter ("bowdlerize", "bowdler");
   Expect_Porter ("probate", "probat");
   Expect_Porter ("rate", "rate");
   Expect_Porter ("cease", "ceas");
   Expect_Porter ("controll", "control");
   Expect_Porter ("roll", "roll");

   ---------------------------------------------------------------------
   Section ("9. Batch known pairs (≥40) + conflation");
   ---------------------------------------------------------------------
   Expect_Porter ("connect", "connect");
   Expect_Porter ("connected", "connect");
   Expect_Porter ("connecting", "connect");
   Expect_Porter ("connection", "connect");
   Expect_Porter ("connections", "connect");
   Expect_Porter ("consign", "consign");
   Expect_Porter ("consigned", "consign");
   Expect_Porter ("consigning", "consign");
   Expect_Porter ("consignment", "consign");
   Expect_Porter ("universal", "univers");
   Expect_Porter ("university", "univers");
   Expect_Porter ("universe", "univers");
   Expect_Porter ("generalizations", "gener");
   Expect_Porter ("oscillators", "oscil");
   Expect_Porter ("running", "run");
   Expect_Porter ("runs", "run");
   Expect_Porter ("easily", "easili");
   Expect_Porter ("ionization", "ioniz");
   Expect_Porter ("alphabetical", "alphabet");
   Expect_Porter ("about", "about");

   ---------------------------------------------------------------------
   Section ("10. Empty / short / idempotence");
   ---------------------------------------------------------------------
   Expect_Porter ("", "");
   Expect_Porter ("a", "a");
   Expect_Porter ("I", "i");
   Expect_Porter ("be", "be");
   Expect_Porter ("by", "by");
   Expect_Porter ("aa", "aa");
   declare
      W1 : constant String := Porter_Stem ("fishing");
      W2 : constant String := Porter_Stem (W1);
      W3 : constant String := Porter_Stem ("arguing");
      W4 : constant String := Porter_Stem (W3);
      W5 : constant String := Porter_Stem ("connections");
      W6 : constant String := Porter_Stem (W5);
      W7 : constant String := Porter_Stem ("cats");
      W8 : constant String := Porter_Stem (W7);
      W9 : constant String := Porter_Stem ("hopefulness");
      W10 : constant String := Porter_Stem (W9);
   begin
      Check (W1 = W2, "idempotent fishing");
      Check (W3 = W4, "idempotent arguing");
      Check (W5 = W6, "idempotent connections");
      Check (W7 = W8, "idempotent cats");
      Check (W9 = W10, "idempotent hopefulness");
   end;

   ---------------------------------------------------------------------
   Section ("11. Simple_Stem / Suffix_Strip comparison");
   ---------------------------------------------------------------------
   Expect_Simple ("cats", "cat");
   Expect_Simple ("fishing", "fish");
   Expect_Simple ("fished", "fish");
   Expect_Simple ("quickly", "quick");
   Expect_Simple ("boxes", "box");
   Expect_Simple ("a", "a");
   Expect_Simple ("ing", "ing");  --  too short to strip
   Expect_Simple ("RUNNING", "runn");
   Check (Suffix_Strip ("cats") = Simple_Stem ("cats"),
          "Suffix_Strip alias");
   Check (Simple_Stem ("arguing") = "argu", "Simple arguing→argu");
   Check (Simple_Stem ("argued") = "argu", "Simple argued→argu");

   ---------------------------------------------------------------------
   Section ("12. Capacity / exceptions");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      Big    : constant String (1 .. Max_Word_Length + 1) := [others => 'a'];
   begin
      begin
         declare
            Unused : constant String := Porter_Stem (Big);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Porter_Stem oversize raises Invalid_Argument");
   end;
   declare
      Raised : Boolean := False;
      Big    : constant String (1 .. Max_Word_Length + 1) := [others => 'b'];
   begin
      begin
         declare
            Unused : constant String := Simple_Stem (Big);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Simple_Stem oversize raises Invalid_Argument");
   end;
   declare
      Raised : Boolean := False;
      Big    : constant String (1 .. Max_Word_Length + 1) := [others => 'c'];
   begin
      begin
         declare
            Unused : constant String := To_Lower (Big);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "To_Lower oversize raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("13. Extra Porter vocabulary samples");
   ---------------------------------------------------------------------
   Expect_Porter ("abandon", "abandon");
   Expect_Porter ("abandoned", "abandon");
   Expect_Porter ("abilities", "abil");
   Expect_Porter ("ability", "abil");
   Expect_Porter ("abuse", "abus");
   Expect_Porter ("abused", "abus");
   Expect_Porter ("abuses", "abus");
   Expect_Porter ("abusing", "abus");
   Expect_Porter ("access", "access");
   Expect_Porter ("accessible", "access");
   Expect_Porter ("accident", "accid");
   Expect_Porter ("accidentally", "accident");
   Expect_Porter ("accommodation", "accommod");
   Expect_Porter ("accompanied", "accompani");
   Expect_Porter ("achieve", "achiev");
   Expect_Porter ("achieved", "achiev");
   Expect_Porter ("achievement", "achiev");

   New_Line;
   Put_Line ("-----------------------------------------------");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("-----------------------------------------------");
   pragma Assert (Fail_Count = 0, "Stemming tests failed");
end Tests;
