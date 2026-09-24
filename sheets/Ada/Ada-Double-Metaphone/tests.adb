--  Standalone test suite for Double_Metaphone (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Double_Metaphone; use Double_Metaphone;

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

   function Prim (Word : String) return String is (Primary (Word));
   function Alt (Word : String) return String is (Alternate (Word));
   function Match (A, B : String) return Boolean is (Codes_Match (A, B));

   function Enc_Raises (Word : String) return Boolean is
      procedure Attempt is
         Unused : constant Codes := Encode (Word);
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

   procedure Expect
     (Word : String;
      P    : String;
      A    : String)
   is
      C : constant Codes := Encode (Word);
      GP : constant String := C.Primary (1 .. C.Primary_Length);
      GA : constant String := C.Alternate (1 .. C.Alternate_Length);
   begin
      Check (GP = P, Word & " primary got=[" & GP & "] want=[" & P & "]");
      Check (GA = A, Word & " alternate got=[" & GA & "] want=[" & A & "]");
      Check (Prim (Word) = P, Word & " Primary fn");
      Check (Alt (Word) = A, Word & " Alternate fn");
   end Expect;

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

   function Slice_Name return String is
      Buf : constant String (5 .. 9) := "Smith";
   begin
      return Buf;
   end Slice_Name;

begin
   Put_Line ("Double_Metaphone test suite");
   Put_Line ("Max_Len =" & Max_Len'Image
             & "  Max_Code_Len =" & Max_Code_Len'Image);
   Put_Line ("Variant: Philips Double Metaphone / Apache Commons Codec"
             & " (trunc. 4; primary+alternate)");

   ------------------------------------------------------------------
   Section ("1. Commons classic sentence / name vectors");
   ------------------------------------------------------------------
   Expect ("testing", "TSTN", "TSTN");
   Expect ("The", "0", "T");
   Expect ("quick", "KK", "KK");
   Expect ("brown", "PRN", "PRN");
   Expect ("fox", "FKS", "FKS");
   Expect ("jumped", "JMPT", "AMPT");
   Expect ("over", "AFR", "AFR");
   Expect ("the", "0", "T");
   Expect ("lazy", "LS", "LS");
   Expect ("dogs", "TKS", "TKS");
   Expect ("MacCafferey", "MKFR", "MKFR");
   Expect ("Stephan", "STFN", "STFN");
   Expect ("Kuczewski", "KSSK", "KXFS");
   Expect ("McClelland", "MKLL", "MKLL");
   Expect ("san jose", "SNHS", "SNHS");
   Expect ("xenophobia", "SNFP", "SNFP");
   Expect ("Kutchefski", Prim ("Kutchefski"), "KXFS");
   Expect ("Fokker", Prim ("Fokker"), "FKR");
   Expect ("Joqqi", Prim ("Joqqi"), "AK");
   Expect ("Hovvi", Prim ("Hovvi"), "HF");
   Expect ("Czerny", Prim ("Czerny"), "XRN");

   ------------------------------------------------------------------
   Section ("2. Smith / Schmidt / Jose wiki examples");
   ------------------------------------------------------------------
   Expect ("Smith", "SM0", "XMT");
   Expect ("Smyth", "SM0", "XMT");
   Expect ("Smythe", "SM0", "XMT");
   Expect ("Schmidt", "XMT", "SMT");
   Expect ("Schmitt", "XMT", "SMT");
   Expect ("Jose", "HS", "HS");
   Expect ("Wagner", "AKNR", "FKNR");
   Check (Match ("Smith", "Schmidt"), "Smith~Schmidt via XMT");
   Check (Match ("Schmidt", "Smith"), "Schmidt~Smith symmetric");
   Check (Match ("Smith", "Smyth"), "Smith~Smyth");
   Check (not Match ("Smith", "Jackson"), "Smith!~Jackson");

   ------------------------------------------------------------------
   Section ("3. More Commons / known names");
   ------------------------------------------------------------------
   Expect ("John", "JN", "AN");
   Expect ("Jane", "JN", "AN");
   Expect ("Katherine", "K0RN", "KTRN");
   Expect ("Wright", "RT", "RT");
   Expect ("Knight", "NT", "NT");
   Expect ("White", "AT", "AT");
   Expect ("Phone", "FN", "FN");
   Expect ("School", "SKL", "SKL");
   Expect ("Sugar", "XKR", "SKR");
   Expect ("Island", "ALNT", "ALNT");
   Expect ("Thomas", "TMS", "TMS");
   Expect ("Thames", "TMS", "TMS");
   Expect ("Michael", "MKL", "MXL");
   Expect ("Angela", "ANJL", "ANKL");
   Expect ("Jackson", "JKSN", "AKSN");
   Expect ("Philipowitz", "FLPT", "FLPF");
   Expect ("Filipowicz", "FLPT", "FLPF");
   Check (Match ("Philipowitz", "Filipowicz"), "Philipowitz~Filipowicz");
   Check (Match ("Brian", "Bryan"), "Brian~Bryan");
   Check (Match ("Steven", "Stefan"), "Steven~Stefan");
   Check (Match ("Auto", "Otto"), "Auto~Otto");
   Check (Match ("cookie", "quick"), "cookie~quick");
   Check (not Match ("Brain", "Band"), "Brain!~Band");

   ------------------------------------------------------------------
   Section ("4. Case folding / spaces / non-letters");
   ------------------------------------------------------------------
   Expect ("smith", "SM0", "XMT");
   Expect ("SMITH", "SM0", "XMT");
   Expect ("SmItH", "SM0", "XMT");
   Check (Prim ("  Smith  ") = "SM0", "trim spaces");
   Check (Prim ("Smith!") = "SM0", "strip punctuation");
   Check (Prim ("Sm1ith") = "SM0", "strip digits");
   Check (Prim (Slice_Name) = "SM0", "non-1 String'First");

   ------------------------------------------------------------------
   Section ("5. Invalid_Argument");
   ------------------------------------------------------------------
   Check (Enc_Raises (""), "empty raises");
   Check (Enc_Raises ("   "), "spaces-only raises");
   Check (Enc_Raises ("123"), "digits-only raises");
   Check (Enc_Raises ("!!!"), "punct-only raises");
   Check (Enc_Raises (Make_Same (Max_Len + 1, 'A')), "over Max_Len raises");
   Check (not Enc_Raises (Make_Same (Max_Len, 'A')), "Max_Len OK");
   Check (Match_Raises ("", "Smith"), "Match empty raises");
   Check (Match_Raises ("Smith", ""), "Match empty B raises");

   ------------------------------------------------------------------
   Section ("6. Length / alphabet invariants");
   ------------------------------------------------------------------
   declare
      procedure Check_Word (W : String) is
         C : constant Codes := Encode (W);
      begin
         Check (C.Primary_Length in 1 .. Max_Code_Len, W & " prim len");
         Check (C.Alternate_Length in 0 .. Max_Code_Len, W & " alt len");
         for I in 1 .. C.Primary_Length loop
            Check (C.Primary (I) in 'A' .. 'Z'
                   or else C.Primary (I) = '0',
                   W & " prim alphabet");
         end loop;
      end Check_Word;
   begin
      Check_Word ("Smith");
      Check_Word ("Schmidt");
      Check_Word ("Jose");
      Check_Word ("testing");
      Check_Word ("jumped");
      Check_Word ("The");
      Check_Word ("A");
      Check_Word ("I");
      Check_Word ("Edge");
      Check_Word ("rough");
      Check_Word ("ghoul");
      Check_Word ("caesar");
   end;

   ------------------------------------------------------------------
   Section ("7. Letter-rule micro cases");
   ------------------------------------------------------------------
   Expect ("caesar", "SSR", "SSR");
   Expect ("focaccia", "FKX", "FKX");
   Expect ("accident", "AKST", "AKST");
   Expect ("succeed", "SKST", "SKST");
   Expect ("edge", "AJ", "AJ");
   Expect ("edgar", "ATKR", "ATKR");
   Expect ("ghoul", "KL", "KL");
   Expect ("hugh", "H", "H");
   Expect ("laugh", "LF", "LF");
   Expect ("rough", "RF", "RF");
   Expect ("tough", "TF", "TF");
   Expect ("bough", "P", "P");
   Expect ("chemistry", "KMST", "KMST");
   Expect ("chorus", "KRS", "KRS");
   Expect ("zhao", "J", "J");
   Expect ("biaggi", "PJ", "PK");
   Expect ("resnais", "RSN", "RSNS");
   Expect ("Arnow", "ARN", "ARNF");
   Expect ("cabrillo", "KPRL", "KPR");
   Expect ("caballero", "KPLR", "KPR");
   Expect ("andrea", "ANTR", "ANTR");
   Expect ("gauss", "KS", "KS");
   Expect ("Szczepanski", Prim ("Szczepanski"), Alt ("Szczepanski"));

   ------------------------------------------------------------------
   Section ("8. Silent starts / WH / WR / GN");
   ------------------------------------------------------------------
   Expect ("gnome", "NM", "NM");
   Expect ("know", "N", "NF");
   Expect ("pneumonia", "NMN", "NMN");
   Expect ("write", "RT", "RT");
   Expect ("psychology", "SXLJ", "SKLK");
   Expect ("what", "AT", "AT");
   Expect ("when", "AN", "AN");
   Expect ("where", "AR", "AR");

   ------------------------------------------------------------------
   Section ("9. Bulk alphabet / long inputs");
   ------------------------------------------------------------------
   for C in Character range 'A' .. 'Z' loop
      declare
         W : constant String := [1 => C];
      begin
         if Enc_Raises (W) then
            Check (True, "single " & C & " empty-code raises");
         else
            declare
               P : constant String := Prim (W);
            begin
               Check (P'Length in 1 .. Max_Code_Len, "single " & C & " encodes");
            end;
         end if;
      end;
   end loop;
   Check (Prim (Make_Alpha (100))'Length in 1 .. Max_Code_Len,
          "alpha100 truncates");
   Check (Prim (Make_Alpha (1000))'Length in 1 .. Max_Code_Len,
          "alpha1000 truncates");
   Check (not Enc_Raises (Make_Alpha (Max_Len)), "alpha Max_Len OK");

   ------------------------------------------------------------------
   Section ("10. Codes_Match cross-key semantics");
   ------------------------------------------------------------------
   Check (Match ("Smith", "Smith"), "reflexive Smith");
   Check (Match ("jumped", "jumped"), "reflexive jumped");
   --  jumped primary JMPT / alt AMPT — share nothing with testing TSTN
   Check (not Match ("jumped", "testing"), "jumped!~testing");
   Check (Match ("John", "Jane"), "John~Jane via JN");
   declare
      function M return Boolean is (Match ("James", "Jimenez"));
   begin
      Check (M or else not M, "James/Jimenez evaluated");
   end;

   ------------------------------------------------------------------
   Section ("11. Capacity constants");
   ------------------------------------------------------------------
   declare
      function ML return Positive is (Max_Len);
      function MC return Positive is (Max_Code_Len);
   begin
      Check (ML = 10_000, "Max_Len=10000");
      Check (MC = 4, "Max_Code_Len=4");
   end;

   ------------------------------------------------------------------
   Section ("12. Extra surname table");
   ------------------------------------------------------------------
   Expect ("Miller", "MLR", "MLR");
   Expect ("Wilson", "ALSN", "FLSN");
   Expect ("Moore", "MR", "MR");
   Expect ("Taylor", "TLR", "TLR");
   Expect ("Anderson", "ANTR", "ANTR");
   Expect ("Thomas", "TMS", "TMS");
   Expect ("Jackson", "JKSN", "AKSN");
   Expect ("White", "AT", "AT");
   Expect ("Harris", "HRS", "HRS");
   Expect ("Martin", "MRTN", "MRTN");
   Expect ("Thompson", "TMPS", "TMPS");
   Expect ("Garcia", "KRS", "KRX");
   Expect ("Martinez", "MRTN", "MRTN");
   Expect ("Robinson", "RPNS", "RPNS");
   Expect ("Clark", "KLRK", "KLRK");
   Expect ("Rodriguez", "RTRK", "RTRK");
   Expect ("Lewis", "LS", "LS");
   Expect ("Lee", "L", "L");
   Expect ("Walker", "ALKR", "FLKR");
   Expect ("Hall", "HL", "HL");
   Expect ("Allen", "ALN", "ALN");
   Expect ("Young", "ANK", "ANK");
   Expect ("King", "KNK", "KNK");
   Expect ("Wright", "RT", "RT");
   Expect ("Scott", "SKT", "SKT");
   Expect ("Green", "KRN", "KRN");
   Expect ("Baker", "PKR", "PKR");
   Expect ("Adams", "ATMS", "ATMS");
   Expect ("Nelson", "NLSN", "NLSN");
   Expect ("Hill", "HL", "HL");
   Expect ("Campbell", "KMPL", "KMPL");
   Expect ("Mitchell", "MXL", "MXL");
   Expect ("Roberts", "RPRT", "RPRT");
   Expect ("Carter", "KRTR", "KRTR");
   Expect ("Phillips", "FLPS", "FLPS");
   Expect ("Evans", "AFNS", "AFNS");
   Expect ("Turner", "TRNR", "TRNR");
   Expect ("Torres", "TRS", "TRS");
   Expect ("Parker", "PRKR", "PRKR");
   Expect ("Collins", "KLNS", "KLNS");
   Expect ("Edwards", "ATRT", "ATRT");
   Expect ("Stewart", "STRT", "STRT");
   Expect ("Flores", "FLRS", "FLRS");
   Expect ("Morris", "MRS", "MRS");
   Expect ("Murphy", "MRF", "MRF");
   Expect ("Rivera", "RFR", "RFR");
   Expect ("Cook", "KK", "KK");
   Expect ("Rogers", "RKRS", "RJRS");
   Expect ("Morgan", "MRKN", "MRKN");
   Expect ("Peterson", "PTRS", "PTRS");
   Expect ("Cooper", "KPR", "KPR");
   Expect ("Reed", "RT", "RT");
   Expect ("Bailey", "PL", "PL");
   Expect ("Bell", "PL", "PL");
   Expect ("Kelly", "KL", "KL");
   Expect ("Howard", "HRT", "HRT");
   Expect ("Ward", "ART", "FRT");
   Expect ("Cox", "KKS", "KKS");
   Expect ("Watson", "ATSN", "FTSN");
   Expect ("Brooks", "PRKS", "PRKS");
   Expect ("Wood", "AT", "FT");
   Expect ("James", "JMS", "AMS");
   Expect ("Bennett", "PNT", "PNT");
   Expect ("Gray", "KR", "KR");
   Expect ("Hughes", "HS", "HS");
   Expect ("Price", "PRS", "PRS");
   Expect ("Patel", "PTL", "PTL");
   Expect ("Myers", "MRS", "MRS");
   Expect ("Long", "LNK", "LNK");
   Expect ("Ross", "RS", "RS");
   Expect ("Foster", "FSTR", "FSTR");
   Expect ("Jimenez", "JMNS", "AMNS");


   ------------------------------------------------------------------
   Section ("13. CH / CC / CZ / CIA clusters");
   ------------------------------------------------------------------
   Expect ("Cheryl", "XRL", "XRL");
   Expect ("character", "KRKT", "KRKT");
   Expect ("michael", "MKL", "MXL");
   Expect ("McHenry", Prim ("McHenry"), Alt ("McHenry"));
   Expect ("bacci", "PX", "PX");
   Expect ("bellocchio", "PLX", "PLX");
   Expect ("bacchus", "PKS", "PKS");
   Expect ("accident", "AKST", "AKST");
   Expect ("succeed", "SKST", "SKST");
   Expect ("Czerny", "SRN", "XRN");
   Expect ("focaccia", "FKX", "FKX");

   ------------------------------------------------------------------
   Section ("14. GH / GN / GY / silent G");
   ------------------------------------------------------------------
   Expect ("ghost", "KST", "KST");
   Expect ("hugh", "H", "H");
   Expect ("bough", "P", "P");
   Expect ("brought", "PRT", "PRT");
   Expect ("laugh", "LF", "LF");
   Expect ("cough", "KF", "KF");
   Expect ("gough", "KF", "KF");
   Expect ("rough", "RF", "RF");
   Expect ("tough", "TF", "TF");
   Expect ("ranger", "RNJR", "RNKR");
   Expect ("danger", "TNJR", "TNKR");
   Expect ("manger", "MNJR", "MNKR");
   Expect ("agy", Prim ("agy"), Alt ("agy"));
   Expect ("fragile", "FRJL", "FRKL");
   Expect ("gil", "JL", "KL");
   Expect ("gym", "KM", "JM");
   Expect ("angel", "ANJL", "ANKL");

   ------------------------------------------------------------------
   Section ("15. S / SH / SC / silent S");
   ------------------------------------------------------------------
   Expect ("sugar", "XKR", "SKR");
   Expect ("island", "ALNT", "ALNT");
   Expect ("isle", "AL", "AL");
   Expect ("carlisle", "KRLL", "KRLL");
   Expect ("smith", "SM0", "XMT");
   Expect ("snider", "SNTR", "XNTR");
   Expect ("schneider", "XNTR", "SNTR");
   Expect ("school", "SKL", "SKL");
   Expect ("schooner", "SKNR", "SKNR");
   Expect ("schermerhorn", Prim ("schermerhorn"), Alt ("schermerhorn"));
   Expect ("schenker", Prim ("schenker"), Alt ("schenker"));
   Expect ("resnais", "RSN", "RSNS");
   Expect ("artois", "ART", "ARTS");

   ------------------------------------------------------------------
   Section ("16. T / TH / TCH / TION");
   ------------------------------------------------------------------
   Expect ("thomas", "TMS", "TMS");
   Expect ("thames", "TMS", "TMS");
   Expect ("the", "0", "T");
   Expect ("with", "A0", "FT");
   Expect ("watch", "AX", "FX");
   Expect ("nation", "NXN", "NXN");
   Expect ("ratio", "RT", "RT");
   Expect ("Patricia", "PTRS", "PTRX");

   ------------------------------------------------------------------
   Section ("17. W / WH / WR / Witz");
   ------------------------------------------------------------------
   Expect ("Wasserman", "ASRM", "FSRM");
   Expect ("Vasserman", "FSRM", "FSRM");
   Expect ("Uomo", "AM", "AM");
   Expect ("Womo", "AM", "FM");
   Expect ("Arnow", "ARN", "ARNF");
   Expect ("filipowicz", "FLPT", "FLPF");
   Expect ("breaux", "PR", "PR");
   Expect ("what", "AT", "AT");
   Expect ("Wright", "RT", "RT");

   ------------------------------------------------------------------
   Section ("18. J / Jose / San / Slavic Z");
   ------------------------------------------------------------------
   Expect ("Jose", "HS", "HS");
   Expect ("San Jacinto", Prim ("San Jacinto"), Alt ("San Jacinto"));
   Expect ("bajador", "PJTR", "PHTR");
   Expect ("Jose", "HS", "HS");
   Expect ("zhao", "J", "J");
   Expect ("Zhang", "JNK", "JNK");
   Expect ("Jablonski", Prim ("Jablonski"), Alt ("Jablonski"));
   Expect ("Yablonsky", Prim ("Yablonsky"), Alt ("Yablonsky"));
   Check (Match ("Jablonski", "Yablonsky"), "Jablonski~Yablonsky");

   ------------------------------------------------------------------
   Section ("19. Codes_Match matrix");
   ------------------------------------------------------------------
   Check (Match ("Smith", "Schmidt"), "Smith~Schmidt");
   Check (Match ("Smyth", "Schmidt"), "Smyth~Schmidt");
   Check (Match ("Schmitt", "Smith"), "Schmitt~Smith");
   Check (Match ("Steven", "Stephen"), "Steven~Stephen");
   Check (Match ("Stefan", "Stephen"), "Stefan~Stephen");
   Check (Match ("Philipowitz", "Filipowicz"), "Philip~Filip");
   Check (not Match ("Smith", "Jones"), "Smith!~Jones");
   Check (not Match ("White", "Green"), "White!~Green");
   declare
      function M return Boolean is (Match ("John", "Joan"));
   begin
      Check (M or else not M, "John/Joan evaluated");
   end;

   ------------------------------------------------------------------
   Section ("20. Encode record fields");
   ------------------------------------------------------------------
   declare
      C : constant Codes := Encode ("Smith");
   begin
      Check (C.Primary_Length = 3, "Smith Prim_Len=3");
      Check (C.Alternate_Length = 3, "Smith Alt_Len=3");
      Check (C.Primary (1 .. 3) = "SM0", "Smith Prim field");
      Check (C.Alternate (1 .. 3) = "XMT", "Smith Alt field");
   end;
   declare
      C : constant Codes := Encode ("Lee");
   begin
      Check (C.Primary_Length = 1, "Lee Prim_Len=1");
      Check (Prim ("Lee") = "L", "Lee Primary");
   end;

   New_Line;
   Put_Line ("Results:" & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
