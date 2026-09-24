--  Standalone test suite for Knuth_Bendix_Completion (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Knuth_Bendix_Completion; use Knuth_Bendix_Completion;

procedure Tests
  with SPARK_Mode => Off
is

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

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function S (X : String) return String is (X);

   function Has_Rule (Rules : Rule_Array; Left, Right : String) return Boolean
   is
   begin
      for R of Rules loop
         if Image (R.LHS) = Left and then Image (R.RHS) = Right then
            return True;
         end if;
      end loop;
      return False;
   end Has_Rule;

begin
   Ada.Text_IO.Put_Line ("Knuth_Bendix_Completion tests");
   Ada.Text_IO.Put_Line ("==============================");

   ------------------------------------------------------------------
   Section ("1. Word / shortlex basics");
   ------------------------------------------------------------------
   Check (Image (To_Word (S (""))) = "", "empty word image");
   Check (Image (To_Word (S ("ab"))) = "ab", "ab image");
   Check (To_Word (S ("a")).Len = 1, "len a = 1");
   Check (To_Word (S ("")).Len = 0, "len empty = 0");
   Check (Shortlex_Less (S (""), S ("a")), "'' < a");
   Check (Shortlex_Less (S ("a"), S ("b")), "a < b");
   Check (Shortlex_Less (S ("a"), S ("aa")), "a < aa (length)");
   Check (Shortlex_Less (S ("bb"), S ("aaa")), "bb < aaa (length)");
   Check (Shortlex_Less (S ("ab"), S ("ba")), "ab < ba (lex)");
   Check (not Shortlex_Less (S ("ba"), S ("ab")), "not ba < ab");
   Check (not Shortlex_Less (S ("a"), S ("a")), "not a < a");
   Check (Shortlex_Less (S ("aa"), S ("ab")), "aa < ab");
   Check (Shortlex_Less (S ("z"), S ("aa")), "z < aa (len)");

   ------------------------------------------------------------------
   Section ("2. Orient");
   ------------------------------------------------------------------
   declare
      R1 : constant Rule := Orient (S ("ba"), S ("ab"));
      R2 : constant Rule := Orient (S ("ab"), S ("ba"));
      R3 : constant Rule := Orient (S ("aa"), S (""));
   begin
      Check (Image (R1.LHS) = "ba" and then Image (R1.RHS) = "ab",
             "orient ba=ab -> ba->ab");
      Check (Image (R2.LHS) = "ba" and then Image (R2.RHS) = "ab",
             "orient ab=ba -> ba->ab");
      Check (Image (R3.LHS) = "aa" and then Image (R3.RHS) = "",
             "orient aa='' -> aa->''");
   end;

   ------------------------------------------------------------------
   Section ("3. Reduce with a single rule");
   ------------------------------------------------------------------
   declare
      Rules : constant Rule_Array := [Make_Rule ("ba", "ab")];
   begin
      Check (Reduce (S ("ba"), Rules) = "ab", "reduce ba");
      Check (Reduce (S ("ab"), Rules) = "ab", "reduce ab irreducible");
      Check (Reduce (S (""), Rules) = "", "reduce empty");
      Check (Reduce (S ("a"), Rules) = "a", "reduce a");
      Check (Reduce (S ("baba"), Rules) = "aabb", "reduce baba -> aabb");
      Check (Reduce (S ("bbba"), Rules) = "abbb", "reduce bbba -> abbb");
      Check (Reduce (S ("cba"), Rules) = "cab", "reduce cba -> cab");
      Check (Normal_Form (S ("bababa"), Rules) = "aaabbb",
             "NF bababa = aaabbb");
      Check (Equivalent (S ("ba"), S ("ab"), Rules), "ba ~ ab");
      Check (Equivalent (S ("baba"), S ("aabb"), Rules), "baba ~ aabb");
      Check (not Equivalent (S ("a"), S ("b"), Rules), "a !~ b");
   end;

   declare
      Rules : constant Rule_Array := [Make_Rule ("aa", "")];
   begin
      Check (Reduce (S ("aa"), Rules) = "", "aa -> ''");
      Check (Reduce (S ("aaa"), Rules) = "a", "aaa -> a");
      Check (Reduce (S ("aaaa"), Rules) = "", "aaaa -> ''");
      Check (Reduce (S ("baab"), Rules) = "bb", "baab -> bb");
      Check (Reduce (S ("a"), Rules) = "a", "single a stays");
   end;

   ------------------------------------------------------------------
   Section ("4. Multiple rules / leftmost-outermost");
   ------------------------------------------------------------------
   declare
      Rules : constant Rule_Array :=
        [Make_Rule ("aa", ""), Make_Rule ("bb", "")];
   begin
      Check (Reduce (S ("aabb"), Rules) = "", "aabb -> ''");
      Check (Reduce (S ("abab"), Rules) = "abab", "abab irreducible");
      Check (Reduce (S ("aaabb"), Rules) = "a", "aaabb -> a");
      Check (Reduce (S ("bbaa"), Rules) = "", "bbaa -> ''");
   end;

   declare
      Rules : constant Rule_Array :=
        [Make_Rule ("ab", "c"), Make_Rule ("bc", "a")];
   begin
      Check (Reduce (S ("ab"), Rules) = "c", "ab -> c");
      Check (Reduce (S ("bc"), Rules) = "a", "bc -> a");
      Check (Reduce (S ("abc"), Rules) = "cc",
             "abc leftmost ab -> cc");
   end;

   ------------------------------------------------------------------
   Section ("5. Critical pairs on a known toy");
   ------------------------------------------------------------------
   --  Rules ab->c and bc->a overlap on abc giving (cc, aa).
   declare
      Rules : constant Rule_Array :=
        [Make_Rule ("ab", "c"), Make_Rule ("bc", "a")];
      Pairs : constant Critical_Pair_Array := Critical_Pairs (Rules, 1, 2);
      Found_CC_AA : Boolean := False;
   begin
      Check (Pairs'Length >= 1, "at least one critical pair ab/bc");
      for P of Pairs loop
         declare
            U : constant String := Image (P.U);
            V : constant String := Image (P.V);
         begin
            if (U = "cc" and then V = "aa")
              or else (U = "aa" and then V = "cc")
            then
               Found_CC_AA := True;
            end if;
         end;
      end loop;
      Check (Found_CC_AA, "critical pair includes {aa,cc}");
      Check (not Is_Locally_Confluent (Rules),
             "ab->c, bc->a not yet locally confluent");
   end;

   ------------------------------------------------------------------
   Section ("6. Complete: commutativity (already convergent)");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("ba", "ab")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 8, Max_Steps => 32);
   begin
      Check (Res.Kind = Success, "commutativity completes");
      Check (Res.Count >= 1, "at least one rule");
      Check (Has_Rule (Res.Rules, "ba", "ab"), "has ba->ab");
      Check (Is_Locally_Confluent (Res.Rules), "comm locally confluent");
      Check (Normal_Form (S ("baba"), Res.Rules) =
               Normal_Form (S ("aabb"), Res.Rules),
             "NF baba = NF aabb");
      Check (Normal_Form (S ("bab"), Res.Rules) = "abb", "NF bab = abb");
      Check (Normal_Form (S ("bba"), Res.Rules) = "abb", "NF bba = abb");
      Check (Equivalent (S ("baa"), S ("aba"), Res.Rules), "baa ~ aba");
      Check (Equivalent (S ("baa"), S ("aab"), Res.Rules), "baa ~ aab");
   end;

   ------------------------------------------------------------------
   Section ("7. Complete: ab/bc toy adds expected rule");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("ab", "c"), Make_Equation ("bc", "a")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 16, Max_Steps => 64);
   begin
      Check (Res.Kind = Success, "ab/bc system completes");
      Check (Res.Count >= 3, "at least 3 rules after CP resolution");
      --  shortlex: aa < cc ⇒ cc → aa
      Check (Has_Rule (Res.Rules, "cc", "aa")
               or else Has_Rule (Res.Rules, "aa", "cc"),
             "completion adds aa/cc rule");
      Check (Is_Locally_Confluent (Res.Rules), "ab/bc locally confluent");
      Check (Equivalent (S ("abc"), S ("aa"), Res.Rules)
               or else Equivalent (S ("abc"), S ("cc"), Res.Rules),
             "abc equivalent to aa or cc NF");
      Check (Normal_Form (S ("abc"), Res.Rules) =
               Normal_Form (S ("aa"), Res.Rules)
             or else Normal_Form (S ("abc"), Res.Rules) =
               Normal_Form (S ("cc"), Res.Rules),
             "NF(abc) matches NF of aa or cc");
   end;

   ------------------------------------------------------------------
   Section ("8. Complete: involution aa='' ");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array := [Make_Equation ("aa", "")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 8, Max_Steps => 32);
   begin
      Check (Res.Kind = Success, "aa='' completes");
      Check (Has_Rule (Res.Rules, "aa", ""), "has aa->''");
      Check (Is_Locally_Confluent (Res.Rules), "aa locally confluent");
      Check (Normal_Form (S ("aaaa"), Res.Rules) = "", "NF aaaa = ''");
      Check (Normal_Form (S ("aaa"), Res.Rules) = "a", "NF aaa = a");
      Check (Equivalent (S ("aaaaaa"), S (""), Res.Rules), "a^6 ~ ''");
   end;

   ------------------------------------------------------------------
   Section ("9. Complete: two involutions aa, bb");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("aa", ""), Make_Equation ("bb", "")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 8, Max_Steps => 64);
   begin
      Check (Res.Kind = Success, "aa/bb completes");
      Check (Has_Rule (Res.Rules, "aa", ""), "has aa->''");
      Check (Has_Rule (Res.Rules, "bb", ""), "has bb->''");
      Check (Is_Locally_Confluent (Res.Rules), "aa/bb locally confluent");
      Check (Normal_Form (S ("aabbaa"), Res.Rules) = "", "NF aabbaa");
      Check (Equivalent (S ("abab"), S ("abab"), Res.Rules), "abab ~ itself");
      Check (not Equivalent (S ("ab"), S ("ba"), Res.Rules),
             "ab !~ ba without commutativity");
   end;

   ------------------------------------------------------------------
   Section ("10. Bound exceeded handled cleanly");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("ab", "c"),
         Make_Equation ("bc", "a"),
         Make_Equation ("ca", "b")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 1, Max_Steps => 64);
   begin
      Check (Res.Kind = Did_Not_Complete, "Max_Rules=1 => Did_Not_Complete");
      Check (Res.Count <= 1, "partial count <= 1");
   end;

   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("ab", "c"), Make_Equation ("bc", "a")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 16, Max_Steps => 1);
   begin
      --  May succeed very quickly or fail; either is fine if Kind is valid.
      Check (Res.Kind = Success or else Res.Kind = Did_Not_Complete,
             "Max_Steps=1 returns a defined outcome");
      if Res.Kind = Did_Not_Complete then
         Check (True, "Max_Steps=1 did not complete (expected possible)");
      else
         Check (Res.Count >= 1, "Max_Steps=1 still succeeded with rules");
      end if;
   end;

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Big : constant String (1 .. Max_Word_Len + 1) := [others => 'x'];
            W : constant Word := To_Word (Big);
            pragma Unreferenced (W);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "To_Word oversized raises");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            R : constant Rule := Make_Rule ("", "a");
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Rule empty LHS raises");
   end;

   declare
      Raised : Boolean := False;
      Empty  : Equation_Array (1 .. 0);
   begin
      begin
         declare
            Res : constant Complete_Result := Complete (Empty);
            pragma Unreferenced (Res);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Complete empty equations raises");
   end;

   declare
      Raised : Boolean := False;
      Eqs    : constant Equation_Array := [Make_Equation ("ba", "ab")];
   begin
      begin
         declare
            Res : constant Complete_Result :=
              Complete (Eqs, Max_Rules => Max_Rules_Cap + 1);
            pragma Unreferenced (Res);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Max_Rules > Cap raises");
   end;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            R : constant Rule := Orient (S ("a"), S ("a"));
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Orient equal words raises");
   end;

   ------------------------------------------------------------------
   Section ("12. Confluence on test words after completion");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("ba", "ab"), Make_Equation ("ca", "ac"),
         Make_Equation ("cb", "bc")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 16, Max_Steps => 128);
   begin
      Check (Res.Kind = Success, "3-letter commutativity completes");
      Check (Is_Locally_Confluent (Res.Rules), "3-letter locally confluent");
      Check (Normal_Form (S ("cba"), Res.Rules) = "abc", "NF cba = abc");
      Check (Normal_Form (S ("bca"), Res.Rules) = "abc", "NF bca = abc");
      Check (Normal_Form (S ("cab"), Res.Rules) = "abc", "NF cab = abc");
      Check (Equivalent (S ("cbacba"), S ("aabbcc"), Res.Rules),
             "cbacba ~ aabbcc");
      Check (Equivalent (S ("ccbbaa"), S ("aabbcc"), Res.Rules),
             "ccbbaa ~ aabbcc");
   end;

   ------------------------------------------------------------------
   Section ("13. Rewrite_Step / empty rule set");
   ------------------------------------------------------------------
   declare
      W       : Word := To_Word (S ("ba"));
      Changed : Boolean;
      Rules   : constant Rule_Array := [Make_Rule ("ba", "ab")];
      Empty   : Rule_Array (1 .. 0);
   begin
      Rewrite_Step (W, Rules, Changed);
      Check (Changed and then Image (W) = "ab", "one rewrite_step ba->ab");
      Rewrite_Step (W, Rules, Changed);
      Check (not Changed, "second step no change");
      Check (Reduce (S ("xyz"), Empty) = "xyz", "empty rules identity");
      Check (Is_Locally_Confluent (Empty), "empty rules locally confluent");
   end;

   ------------------------------------------------------------------
   Section ("14. Group-like short relations (aa='', bb='')");
   ------------------------------------------------------------------
   declare
      Eqs : constant Equation_Array :=
        [Make_Equation ("aa", ""), Make_Equation ("bb", ""),
         Make_Equation ("abab", "baba")];
      Res : constant Complete_Result :=
        Complete (Eqs, Max_Rules => 24, Max_Steps => 200);
   begin
      Check (Res.Kind = Success or else Res.Kind = Did_Not_Complete,
             "group-like run finishes with defined kind");
      if Res.Kind = Success then
         Check (Is_Locally_Confluent (Res.Rules),
                "group-like locally confluent when Success");
         Check (Equivalent (S ("aa"), S (""), Res.Rules), "aa ~ ''");
         Check (Equivalent (S ("bb"), S (""), Res.Rules), "bb ~ ''");
      else
         Check (Res.Count >= 1, "partial rules on Did_Not_Complete");
         Check (Res.Steps_Used >= 1, "used some steps before bound");
      end if;
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
