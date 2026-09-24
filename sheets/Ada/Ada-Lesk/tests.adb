--  Standalone test suite for Lesk (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Lesk; use Lesk;

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

begin
   Put_Line ("Lesk algorithm test suite (Simplified + Original Lesk WSD)");
   Put_Line ("===========================================================");

   ---------------------------------------------------------------------
   Section ("1. To_Lower / Is_Letter / Near");
   ---------------------------------------------------------------------
   Check (To_Lower ('A') = 'a', "To_Lower('A')=a");
   Check (To_Lower ('Z') = 'z', "To_Lower('Z')=z");
   Check (To_Lower ('m') = 'm', "To_Lower('m')=m");
   Check (To_Lower ('3') = '3', "To_Lower digit unchanged");
   Check (To_Lower ("PiNe") = "pine", "To_Lower string PiNe");
   Check (To_Lower ("") = "", "To_Lower empty");
   Check (Is_Letter ('a') and Is_Letter ('Z'), "Is_Letter aZ");
   Check (not Is_Letter ('3') and not Is_Letter ('-'), "Is_Letter rejects nonletters");
   Check (Near (2, 2), "Near equal");
   Check (Near (2, 3, 1), "Near tol=1");
   Check (not Near (2, 4, 1), "Near rejects far");
   Check (Near (-1, 1, 2), "Near signed");

   ---------------------------------------------------------------------
   Section ("2. Tokenize basics");
   ---------------------------------------------------------------------
   declare
      T : constant Token_List := Tokenize ("Pine Cone!");
   begin
      Check (Length (T) = 2, "Tokenize Pine Cone! → 2 tokens");
      Check (To_String (Element (T, 1)) = "pine", "token1=pine");
      Check (To_String (Element (T, 2)) = "cone", "token2=cone");
   end;
   declare
      T : constant Token_List := Tokenize ("needle-shaped leaves");
   begin
      Check (Length (T) = 3, "hyphen splits needle-shaped");
      Check (To_String (Element (T, 1)) = "needle", "needle");
      Check (To_String (Element (T, 2)) = "shaped", "shaped");
      Check (To_String (Element (T, 3)) = "leaves", "leaves");
   end;
   Check (Length (Tokenize ("")) = 0, "Tokenize empty");
   Check (Length (Tokenize ("...")) = 0, "Tokenize punctuation only");
   Check (Length (Tokenize ("ONE two THREE")) = 3, "case folding tokenize");
   Check (To_String (Element (Tokenize ("ABC"), 1)) = "abc", "ABC→abc");

   ---------------------------------------------------------------------
   Section ("3. Unique / Contains / Append / Overlap symmetry");
   ---------------------------------------------------------------------
   declare
      A : constant Token_List := Tokenize ("evergreen tree evergreen");
      U : Token_List;
      B : constant Token_List := Tokenize ("tree fruit evergreen");
   begin
      Check (Length (A) = 3, "multiset length 3");
      U := Unique_Tokens (A);
      Check (Length (U) = 2, "unique → 2");
      Check (Contains (A, Make_Token ("tree")), "Contains tree");
      Check (not Contains (A, Make_Token ("cone")), "not Contains cone");
      Check (Overlap (A, B) = 2, "Overlap evergreen+tree = 2");
      Check (Overlap (A => A, B => B) = Overlap (A => B, B => A), "Overlap symmetric");
      Check (Overlap (A, A) = 2, "Overlap self = |set|");
      Check (Overlap (Empty_Tokens, A) = 0, "Overlap empty");
   end;

   ---------------------------------------------------------------------
   Section ("4. Wikipedia pine#1 ∩ cone#3 = 2");
   ---------------------------------------------------------------------
   Check (Overlap_Count (Pine_Gloss_1, Cone_Gloss_3) = 2,
          "pine#1 ∩ cone#3 = 2");
   Check (Overlap_Count (Cone_Gloss_3, Pine_Gloss_1) = 2,
          "symmetric cone#3 ∩ pine#1 = 2");
   --  Shared raw tokens: "of", "evergreen"
   declare
      P : constant Token_List := Unique_Tokens (Tokenize (Pine_Gloss_1));
      C : constant Token_List := Unique_Tokens (Tokenize (Cone_Gloss_3));
   begin
      Check (Contains (P, Make_Token ("of")), "pine gloss has of");
      Check (Contains (P, Make_Token ("evergreen")), "pine gloss has evergreen");
      Check (Contains (C, Make_Token ("of")), "cone gloss has of");
      Check (Contains (C, Make_Token ("evergreen")), "cone gloss has evergreen");
      Check (not Contains (P, Make_Token ("trees")), "pine has tree not trees");
      Check (Contains (C, Make_Token ("trees")), "cone has trees");
   end;
   Check (Overlap_Count (Pine_Gloss_1, Cone_Gloss_1) = 0,
          "pine#1 ∩ cone#1 = 0");
   Check (Overlap_Count (Pine_Gloss_2, Cone_Gloss_3) = 0,
          "pine#2 ∩ cone#3 = 0");
   Check (Overlap_Count (Pine_Gloss_1, Cone_Gloss_2) >= 1,
          "pine#1 ∩ cone#2 has 'of' at least");

   ---------------------------------------------------------------------
   Section ("5. Stopwords");
   ---------------------------------------------------------------------
   declare
      St : constant Stopword_List := Default_Stopwords;
      Raw : constant Natural :=
        Overlap_Count (Pine_Gloss_1, Cone_Gloss_3);
      Filt : constant Natural :=
        Overlap_Count (Pine_Gloss_1, Cone_Gloss_3, St);
   begin
      Check (Is_Stopword ("of", St), "of is stopword");
      Check (Is_Stopword ("THE", St), "THE is stopword");
      Check (not Is_Stopword ("evergreen", St), "evergreen not stopword");
      Check (Raw = 2, "raw overlap still 2");
      Check (Filt = 1, "filtered overlap = 1 (evergreen only)");
      Check (Length (Tokenize (Pine_Gloss_1, St)) <
             Length (Tokenize (Pine_Gloss_1)),
             "stop filter shortens pine gloss tokens");
   end;
   declare
      St : Stopword_List := Empty_Stopwords;
   begin
      St := Add_Stopword (St, "evergreen");
      Check (Is_Stopword ("Evergreen", St), "custom stopword");
      Check (Overlap_Count (Pine_Gloss_1, Cone_Gloss_3, St) = 1,
             "custom stop leaves 'of'");
   end;

   ---------------------------------------------------------------------
   Section ("6. Dictionary entry / pine cone fixture");
   ---------------------------------------------------------------------
   declare
      Pine : constant Dictionary_Entry := Pine_Entry;
      Cone : constant Dictionary_Entry := Cone_Entry;
      Dict : constant Dictionary := Pine_Cone_Dictionary;
   begin
      Check (Word_Of (Pine) = "pine", "Word_Of pine");
      Check (Word_Of (Cone) = "cone", "Word_Of cone");
      Check (Pine.Sense_Count = 2, "pine has 2 senses");
      Check (Cone.Sense_Count = 3, "cone has 3 senses");
      Check (Gloss_Of (Pine.Senses (1)) = Pine_Gloss_1, "pine gloss1");
      Check (Gloss_Of (Pine.Senses (2)) = Pine_Gloss_2, "pine gloss2");
      Check (Gloss_Of (Cone.Senses (3)) = Cone_Gloss_3, "cone gloss3");
      Check (Dict.Count = 2, "dict size 2");
      Check (Find_Entry (Dict, "PINE") = 1, "Find_Entry PINE");
      Check (Find_Entry (Dict, "cone") = 2, "Find_Entry cone");
      Check (Find_Entry (Dict, "apple") = 0, "Find_Entry miss");
   end;

   ---------------------------------------------------------------------
   Section ("7. Pine_Cone_Demo + Simplified Lesk");
   ---------------------------------------------------------------------
   declare
      PS, CS, GO : Natural;
   begin
      Pine_Cone_Demo (PS, CS, GO);
      Check (GO = 2, "Demo Gloss_Overlap=2");
      Check (PS = 1, "Demo Pine_Sense=1");
      Check (CS = 3, "Demo Cone_Sense=3");
   end;
   Check (Simplified_Lesk (Pine_Entry, Pine_Context_Sentence) = 1,
          "Simplified pine → sense 1");
   Check (Simplified_Lesk (Cone_Entry, Cone_Context_Sentence) = 3,
          "Simplified cone → sense 3");
   Check (Simplified_Lesk (Pine_Entry, "waste away sorrow illness") = 2,
          "Simplified pine sorrow → sense 2");
   Check (Simplified_Lesk (Cone_Entry, "solid body narrows point") = 1,
          "Simplified cone geometry → sense 1");
   Check (Simplified_Lesk (Cone_Entry, "hollow shape solid body") = 2
            or else Simplified_Lesk (Cone_Entry, "hollow shape solid body") = 1,
          "Simplified cone shape → sense 1 or 2");
   --  With default stopwords still picks tree sense
   Check (Simplified_Lesk
            (Pine_Entry, Pine_Context_Sentence, True, Default_Stopwords) = 1,
          "Simplified pine + stops → 1");
   Check (Simplified_Lesk
            (Cone_Entry, Cone_Context_Sentence, True, Default_Stopwords) = 3,
          "Simplified cone + stops → 3");

   ---------------------------------------------------------------------
   Section ("8. Best_Sense_Index ties / empty / backoff");
   ---------------------------------------------------------------------
   declare
      E : constant Dictionary_Entry :=
        Make_Entry ("bank",
                    "financial institution money",
                    "river edge shore");
      Ctx_Tie : constant Token_List := Tokenize ("xyzzy");
      Ctx_Fin : constant Token_List := Tokenize ("money financial");
      Ctx_Riv : constant Token_List := Tokenize ("river shore");
      Empty_E : Dictionary_Entry;
   begin
      Check (Best_Sense_Index (E, Ctx_Fin) = 1, "bank money → 1");
      Check (Best_Sense_Index (E, Ctx_Riv) = 2, "bank river → 2");
      --  Zero overlap → first-sense backoff
      Check (Best_Sense_Index (E, Ctx_Tie) = 1, "zero overlap backoff → 1");
      Check (Best_Sense_Index (E, "MONEY") = 1, "case folding context");
      Empty_E.Sense_Count := 0;
      Check (Best_Sense_Index (Empty_E, Ctx_Fin) = 0, "empty entry → 0");
      Check (Simplified_Lesk (Empty_E, "anything") = 0, "Simplified empty → 0");
   end;
   --  Explicit tie: two senses share same overlap count → lowest index
   declare
      E : constant Dictionary_Entry :=
        Make_Entry ("tie",
                    "alpha shared word",
                    "beta shared word");
      Ctx : constant Token_List := Tokenize ("shared word");
   begin
      Check (Sense_Overlap (E.Senses (1), Ctx) =
             Sense_Overlap (E.Senses (2), Ctx),
             "tie equal overlaps");
      Check (Best_Sense_Index (E, Ctx) = 1, "tie → lowest index 1");
   end;
   Check (Gloss_Of (Make_Sense ("")) = "", "empty gloss");
   Check (Overlap_Count ("", "evergreen tree") = 0, "empty gloss overlap 0");
   Check (Overlap_Count ("evergreen", "") = 0, "empty context overlap 0");
   Check (Simplified_Lesk_Score
            (Pine_Entry, Tokenize ("evergreen tree"), 1) >= 2,
          "score pine sense1 vs evergreen tree >=2");
   Check (Simplified_Lesk_Score
            (Pine_Entry, Tokenize ("evergreen tree"), 2) = 0,
          "score pine sense2 vs evergreen tree =0");

   ---------------------------------------------------------------------
   Section ("9. Original Lesk pine/cone");
   ---------------------------------------------------------------------
   declare
      Dict : constant Dictionary := Pine_Cone_Dictionary;
      P_Idx : constant Natural :=
        Original_Lesk (Pine_Entry, Dict);
      C_Idx : constant Natural :=
        Original_Lesk (Cone_Entry, Dict);
   begin
      Check (P_Idx = 1, "Original Lesk pine → 1");
      Check (C_Idx = 3, "Original Lesk cone → 3");
   end;
   declare
      Dict : constant Dictionary := Pine_Cone_Dictionary;
   begin
      Check (Original_Lesk (Pine_Entry, Dict, Default_Stopwords) = 1,
             "Original Lesk pine + stops → 1");
      Check (Original_Lesk (Cone_Entry, Dict, Default_Stopwords) = 3,
             "Original Lesk cone + stops → 3");
   end;

   ---------------------------------------------------------------------
   Section ("10. Synthetic dictionaries / vignettes");
   ---------------------------------------------------------------------
   declare
      Bass : constant Dictionary_Entry :=
        Make_Entry ("bass",
                    "fish freshwater scales",
                    "low musical tone pitch");
      Crane : constant Dictionary_Entry :=
        Make_Entry ("crane",
                    "bird long neck wetland",
                    "machine lift construction heavy");
      Interest : constant Dictionary_Entry :=
        Make_Entry ("interest",
                    "curiosity attention subject",
                    "money bank loan rate percent");
      Match : constant Dictionary_Entry :=
        Make_Entry ("match",
                    "game contest competition winner",
                    "stick fire flame strike");
      Plant : constant Dictionary_Entry :=
        Make_Entry ("plant",
                    "living green leaf photosynthesis",
                    "factory industrial manufacturing");
   begin
      Check (Simplified_Lesk (Bass, "catch freshwater fish lake") = 1,
             "bass fish context → 1");
      Check (Simplified_Lesk (Bass, "guitar musical pitch tone") = 2,
             "bass music context → 2");
      Check (Simplified_Lesk (Crane, "bird wetland nest neck") = 1,
             "crane bird → 1");
      Check (Simplified_Lesk (Crane, "construction machine lift heavy") = 2,
             "crane machine → 2");
      Check (Simplified_Lesk (Interest, "curiosity subject attention") = 1,
             "interest curiosity → 1");
      Check (Simplified_Lesk (Interest, "bank loan rate percent") = 2,
             "interest money → 2");
      Check (Simplified_Lesk (Match, "contest winner competition") = 1,
             "match contest → 1");
      Check (Simplified_Lesk (Match, "strike flame fire stick") = 2,
             "match fire → 2");
      Check (Simplified_Lesk (Plant, "green leaf living photosynthesis") = 1,
             "plant biology → 1");
      Check (Simplified_Lesk (Plant, "factory industrial manufacturing") = 2,
             "plant factory → 2");
   end;

   --  Batch vignettes: (entry, sentence, expected sense)
   declare
      procedure V
        (Word, G1, G2, Sentence : String;
         Expect                 : Positive;
         Label                  : String)
      is
         E : constant Dictionary_Entry := Make_Entry (Word, G1, G2);
         Got : constant Natural := Simplified_Lesk (E, Sentence);
      begin
         Check (Got = Expect,
                "vignette " & Label & " →" & Natural'Image (Expect)
                & " (got" & Natural'Image (Got) & ")");
      end V;
   begin
      V ("seal", "animal marine ocean mammal",
         "close document stamp wax",
         "ocean mammal swims marine", 1, "seal-animal");
      V ("seal", "animal marine ocean mammal",
         "close document stamp wax",
         "wax stamp document close", 2, "seal-stamp");
      V ("rock", "stone mineral geology hard",
         "music band guitar loud",
         "geology mineral hard stone", 1, "rock-stone");
      V ("rock", "stone mineral geology hard",
         "music band guitar loud",
         "guitar band loud music", 2, "rock-music");
      V ("spring", "season flowers bloom warm",
         "coil metal elastic bounce",
         "flowers bloom warm season", 1, "spring-season");
      V ("spring", "season flowers bloom warm",
         "coil metal elastic bounce",
         "metal coil bounce elastic", 2, "spring-coil");
      V ("bark", "dog sound loud yelp",
         "tree outer wood covering",
         "dog loud yelp sound", 1, "bark-dog");
      V ("bark", "dog sound loud yelp",
         "tree outer wood covering",
         "tree wood outer covering", 2, "bark-tree");
      V ("light", "illumination lamp bright sun",
         "not heavy weight portable",
         "lamp bright sun illumination", 1, "light-bright");
      V ("light", "illumination lamp bright sun",
         "not heavy weight portable",
         "heavy weight portable not", 2, "light-weight");
      V ("mole", "animal burrow underground skin",
         "chemistry unit measure amount",
         "burrow underground animal", 1, "mole-animal");
      V ("mole", "animal burrow underground skin",
         "chemistry unit measure amount",
         "chemistry measure unit amount", 2, "mole-chem");
      V ("jam", "fruit sweet spread toast",
         "traffic congestion stuck cars",
         "sweet fruit toast spread", 1, "jam-food");
      V ("jam", "fruit sweet spread toast",
         "traffic congestion stuck cars",
         "traffic cars congestion stuck", 2, "jam-traffic");
      V ("pitch", "throw baseball sport ball",
         "tar sticky black roof",
         "baseball throw ball sport", 1, "pitch-throw");
      V ("pitch", "throw baseball sport ball",
         "tar sticky black roof",
         "tar sticky roof black", 2, "pitch-tar");
      V ("date", "calendar day month year",
         "fruit palm sweet edible",
         "calendar month year day", 1, "date-calendar");
      V ("date", "calendar day month year",
         "fruit palm sweet edible",
         "palm fruit sweet edible", 2, "date-fruit");
      V ("poach", "cook egg water gentle",
         "hunt illegal wildlife crime",
         "cook egg water gentle", 1, "poach-cook");
      V ("poach", "cook egg water gentle",
         "hunt illegal wildlife crime",
         "illegal hunt wildlife crime", 2, "poach-hunt");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exclude target / case / Make_Token");
   ---------------------------------------------------------------------
   declare
      E : constant Dictionary_Entry :=
        Make_Entry ("pine", Pine_Gloss_1, Pine_Gloss_2);
      --  Sentence repeats headword; exclusion should still work
      S1 : constant Natural :=
        Simplified_Lesk (E, "pine evergreen tree cone", True);
      S2 : constant Natural :=
        Simplified_Lesk (E, "PINE evergreen TREE", True);
   begin
      Check (S1 = 1, "exclude target still sense 1");
      Check (S2 = 1, "case-folded sentence sense 1");
      Check (To_String (Make_Token ("EverGreen")) = "evergreen",
             "Make_Token folds case");
      Check (Token_Length_Of (Make_Token ("ab")) = 2, "token len 2");
   end;
   --  Without excluding target, headword in gloss rarely helps; still ok
   Check (Simplified_Lesk
            (Pine_Entry, "evergreen tree", False) = 1,
          "no-exclude with content → 1");

   ---------------------------------------------------------------------
   Section ("12. Four-sense entry / Find / Append capacity smoke");
   ---------------------------------------------------------------------
   declare
      E : constant Dictionary_Entry :=
        Make_Entry ("term",
                    "word vocabulary language",
                    "period time duration semester",
                    "condition contract agreement",
                    "computer terminal keyboard");
   begin
      Check (E.Sense_Count = 4, "four senses");
      Check (Simplified_Lesk (E, "vocabulary language word") = 1,
             "term vocab → 1");
      Check (Simplified_Lesk (E, "semester duration period time") = 2,
             "term period → 2");
      Check (Simplified_Lesk (E, "contract agreement condition") = 3,
             "term contract → 3");
      Check (Simplified_Lesk (E, "keyboard computer terminal") = 4,
             "term computer → 4");
   end;
   declare
      L : Token_List := Empty_Tokens;
   begin
      L := Append (L, Make_Token ("alpha"));
      L := Append (L, Make_Token ("beta"));
      Check (Length (L) = 2, "Append length 2");
      Check (To_String (Element (L, 2)) = "beta", "Element 2 beta");
   end;

   ---------------------------------------------------------------------
   Section ("13. Overlap set vs multiset documentation");
   ---------------------------------------------------------------------
   declare
      --  Multiset would count evergreen twice; set counts once.
      A : constant Token_List := Tokenize ("evergreen evergreen tree");
      B : constant Token_List := Tokenize ("evergreen tree tree");
   begin
      Check (Overlap (A, B) = 2, "set overlap not multiset (2 not 3+)");
      Check (Length (A) = 3 and Length (Unique_Tokens (A)) = 2,
             "unique shrinks multiset");
   end;
   Check (Overlap_Count ("a a a", "a b") = 1, "repeated a counts once");
   Check (Near (Overlap_Count (Pine_Gloss_1, Cone_Gloss_3), 2),
          "Near checks wiki overlap");

   ---------------------------------------------------------------------
   Section ("14. Ice-cream cone contrast (no pine overlap)");
   ---------------------------------------------------------------------
   declare
      Ice : constant Dictionary_Entry :=
        Make_Entry ("cone",
                    "pastry wafer ice cream dessert",
                    Cone_Gloss_1,
                    Cone_Gloss_3);
      --  Ice-cream context should pick pastry sense (1), not evergreen (3)
   begin
      Check (Simplified_Lesk (Ice, "ice cream dessert wafer pastry") = 1,
             "ice cream cone → pastry sense");
      Check (Simplified_Lesk (Ice, "evergreen trees fruit") = 3,
             "evergreen still → fruit sense");
   end;

   New_Line;
   Put_Line ("===========================================================");
   Put_Line ("Pass_Count =" & Natural'Image (Pass_Count));
   Put_Line ("Fail_Count =" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED (>=100 PASS, Fail_Count=0)");
   elsif Fail_Count = 0 then
      Put_Line ("WARNING: Fail_Count=0 but Pass_Count < 100");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;
end Tests;
