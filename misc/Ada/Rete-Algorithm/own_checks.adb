--  Own checks (see tests/SOURCES.txt). Assume the network is wrong or does
--  nothing. Random networks of 1 .. 3 rules, each a chain of 1 .. 3 joins
--  (alpha tests on attribute / value from a small symbol set, random join
--  conditions or cross joins), random fact sets inserted one by one or in a
--  batch, then random removals. After every step each beta memory's size is
--  compared with a naive count: every tuple (w1, .., wk) of current facts
--  with wi passing the i-th alpha test and the i-th join condition
--  (w_j.Left_Field = w_i.Right_Field for the condition's index j < i;
--  index 0 = no condition; an index >= i never matches) is enumerated.
--  Half of the joins reuse an existing alpha node (shared between rules or
--  used twice in one chain), as Rete networks share alpha memories.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Rete; use Rete;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Failures, Compared, Full_Skips : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   Attrs : constant array (1 .. 2) of Character := ['a', 'b'];
   Vals  : constant array (1 .. 2) of Character := ['x', 'y'];
   Ents  : constant array (1 .. 3) of Character := ['p', 'q', 'x'];   --  'x' also a value

   type Fact_Rec is record
      Id : WME_ID;
      E, A, V : Character;
      Live : Boolean := False;
   end record;
   Facts : array (1 .. 7) of Fact_Rec;
   NF : Natural := 0;

   type Step is record
      Alpha_A, Alpha_V : Character;
      Cond : Join_Condition;
      Beta : Beta_Node_ID;
   end record;
   type Chain is array (1 .. 3) of Step;
   Rules_Of : array (1 .. 3) of Chain;
   Len : array (1 .. 3) of Natural;
   NR : Natural;

   type Alpha_Rec is record
      Id   : Alpha_Node_ID;
      A, V : Character;
   end record;
   Pool : array (1 .. 9) of Alpha_Rec := [others => (0, ' ', ' ')];
   NA : Natural := 0;

   function Field (F : Fact_Rec; S : Field_Selector) return Character is
     (case S is when Select_Entity => F.E, when Select_Attribute => F.A, when Select_Value => F.V);

   type Tuple is array (1 .. 3) of Positive;

   --  naive count of tuples matching the first K steps of rule R
   function Naive (R, K : Positive) return Natural is
      Count : Natural := 0;
      T : Tuple := [others => 1];
      procedure Extend (I : Positive) is
      begin
         if I > K then
            Count := Count + 1;
            return;
         end if;
         for F in 1 .. NF loop
            if Facts (F).Live and then Facts (F).A = Rules_Of (R) (I).Alpha_A
              and then Facts (F).V = Rules_Of (R) (I).Alpha_V
            then
               declare
                  C : constant Join_Condition := Rules_Of (R) (I).Cond;
               begin
                  if C.Left_Token_Index = 0
                    or else (C.Left_Token_Index < I
                             and then Field (Facts (T (C.Left_Token_Index)), C.Left_Field)
                                      = Field (Facts (F), C.Right_Field))
                  then
                     T (I) := F;
                     Extend (I + 1);
                  end if;
               end;
            end if;
         end loop;
      end Extend;
   begin
      Extend (1);
      return Count;
   end Naive;

   procedure Compare (Label : String) is
   begin
      for R in 1 .. NR loop
         for K in 1 .. Len (R) loop
            Compared := Compared + 1;
            if Get_Beta_Match_Count (Rules_Of (R) (K).Beta) /= Naive (R, K) then
               Fail (Label & ": rule" & R'Image & " join" & K'Image & " holds"
                     & Get_Beta_Match_Count (Rules_Of (R) (K).Beta)'Image & " tokens, naive match"
                     & Naive (R, K)'Image);
            end if;
         end loop;
         if Get_Rule_Match_Count (Rule_ID (R)) /= Naive (R, Len (R)) then
            Fail (Label & ": rule" & R'Image & " activations" & Get_Rule_Match_Count (Rule_ID (R))'Image
                  & ", naive" & Naive (R, Len (R))'Image);
         end if;
      end loop;
   end Compare;

   function Sym (C : Character) return Symbol is (To_Symbol ([C]));
   function Sel return Field_Selector is (Field_Selector'Val (Rand (0, 2)));
begin
   for Round in 1 .. 300 loop
      declare
         Batched : constant Boolean := Round mod 2 = 0;
         Label : constant String := "network#" & Round'Image & (if Batched then " (batched)" else "");
      begin
         Initialize_Network;
         NR := Rand (1, 3);
         NA := 0;
         for R in 1 .. NR loop
            Len (R) := Rand (1, 3);
            declare
               Parent : Beta_Node_ID := 0;
            begin
               for K in 1 .. Len (R) loop
                  declare
                     S : Step;
                     Al : Alpha_Node_ID;
                  begin
                     S.Alpha_A := Attrs (Rand (1, 2));
                     S.Alpha_V := Vals (Rand (1, 2));
                     S.Cond := (Left_Token_Index => (if K = 1 or else Rand (0, 2) = 0 then 0 else Rand (1, K - 1)),
                                Left_Field => Sel, Right_Field => Sel);
                     if NA > 0 and then Rand (0, 1) = 0 then   --  share an existing alpha node
                        declare
                           P : constant Positive := Rand (1, NA);
                        begin
                           Al := Pool (P).Id;
                           S.Alpha_A := Pool (P).A;
                           S.Alpha_V := Pool (P).V;
                        end;
                     else
                        Al := Add_Alpha_Node (Sym (S.Alpha_A), Sym (S.Alpha_V));
                        NA := NA + 1;
                        Pool (NA) := (Al, S.Alpha_A, S.Alpha_V);
                     end if;
                     S.Beta := Add_Beta_Node (Parent, Al, S.Cond);
                     Parent := S.Beta;
                     Rules_Of (R) (K) := S;
                  end;
               end loop;
               Add_Rule (Rule_ID (R), Sym ('r'), Parent);
            end;
         end loop;
         NF := Rand (1, 6);
         for F in 1 .. NF loop
            Facts (F) := (Id => WME_ID (F), E => Ents (Rand (1, 3)), A => Attrs (Rand (1, 2)),
                          V => Vals (Rand (1, 2)), Live => True);
         end loop;
         begin
            if Batched then
               declare
                  Arr : WME_Array (1 .. NF);
               begin
                  for F in 1 .. NF loop
                     Arr (F) := (Facts (F).Id, Sym (Facts (F).E), Sym (Facts (F).A), Sym (Facts (F).V));
                  end loop;
                  Insert_WME_Batched (Arr);
               end;
               Compare (Label & " after batch insert");
            else
               for F in 1 .. NF loop
                  Insert_WME ((Facts (F).Id, Sym (Facts (F).E), Sym (Facts (F).A), Sym (Facts (F).V)));
                  for G in F + 1 .. NF loop
                     Facts (G).Live := False;
                  end loop;
                  Compare (Label & " after inserting fact" & F'Image);
                  for G in F + 1 .. NF loop
                     Facts (G).Live := True;
                  end loop;
               end loop;
            end if;
            if Get_Global_WM_Count /= NF then
               Fail (Label & ": working memory count");
            end if;
            for K in 1 .. Rand (1, NF) loop
               declare
                  F : constant Positive := Rand (1, NF);
               begin
                  if Facts (F).Live then
                     Remove_WME (Facts (F).Id);
                     Facts (F).Live := False;
                     Compare (Label & " after removing fact" & F'Image);
                  end if;
               end;
            end loop;
         exception
            when Network_Full => Full_Skips := Full_Skips + 1;
         end;
      end;
   end loop;
   --  Capacity limits (Max_Nodes = 100 nodes / memory entries, 8 facts per
   --  token): filling a structure to its limit must succeed, one more must
   --  raise Network_Full (not any other exception), and removing from a
   --  completely full memory must leave the remaining entries intact.
   declare
      Cross : constant Join_Condition := (0, Select_Entity, Select_Entity);
      function Fact (I : Natural; A : String) return WME is
        (WME'(ID => WME_ID (I), Entity => To_Symbol ("e" & I'Image),
              Attribute => To_Symbol (A), Value => To_Symbol ("v")));
      procedure Expect_Full (Label : String; Ok : Boolean) is
      begin
         if not Ok then
            Fail ("capacity: " & Label & " did not raise Network_Full");
         end if;
      end Expect_Full;
      type Positive_List is array (1 .. 3) of Positive;
      A1, A2 : Alpha_Node_ID;
      B, Prev : Beta_Node_ID;
      Got : Boolean;
   begin
      --  101st alpha node, beta node, rule
      Initialize_Network;
      for I in 1 .. 100 loop
         A1 := Add_Alpha_Node (To_Symbol ("a" & I'Image), To_Symbol ("v"));
      end loop;
      begin
         A1 := Add_Alpha_Node (To_Symbol ("z"), To_Symbol ("v"));
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("101st alpha node", Got);
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      for I in 1 .. 100 loop
         B := Add_Beta_Node (0, A1, Cross);
      end loop;
      begin
         B := Add_Beta_Node (0, A1, Cross);
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("101st beta node", Got);
      for I in 1 .. 100 loop
         Add_Rule (Rule_ID (I), To_Symbol ("r"), 1);
      end loop;
      begin
         Add_Rule (1, To_Symbol ("r"), 1);
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("101st rule", Got);

      --  full working memory, alpha memory and beta memory; then removal
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      B := Add_Beta_Node (0, A1, Cross);
      for I in 1 .. 100 loop
         Insert_WME (Fact (I, "a"));
      end loop;
      begin
         Insert_WME (Fact (101, "a"));
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("101st fact", Got);
      for R of Positive_List'(1, 50, 100) loop
         begin
            Remove_WME (WME_ID (R));
         exception
            when others => Fail ("capacity: removing fact" & R'Image & " from full memories raised");
         end;
         Insert_WME (Fact (R + 1000, "a"));    --  back to 100
         if Get_Global_WM_Count /= 100 or else Get_Alpha_Match_Count (A1) /= 100
           or else Get_Beta_Match_Count (B) /= 100
         then
            Fail ("capacity: counts after removal and re-insertion");
         end if;
         --  every remaining fact must still be removable exactly once
      end loop;
      for I in 1 .. 100 loop
         if I not in 1 | 50 | 100 then
            Remove_WME (WME_ID (I));
         end if;
      end loop;
      for R of Positive_List'(1001, 1050, 1100) loop
         Remove_WME (WME_ID (R));
      end loop;
      if Get_Global_WM_Count /= 0 or else Get_Alpha_Match_Count (A1) /= 0
        or else Get_Beta_Match_Count (B) /= 0
      then
         Fail ("capacity: memories not empty after removing every fact");
      end if;

      --  beta memory overflow alone: a self cross join of 10 facts has
      --  exactly 100 tokens; the 11th fact must overflow it
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      Prev := Add_Beta_Node (0, A1, Cross);
      B := Add_Beta_Node (Prev, A1, Cross);
      for I in 1 .. 10 loop
         Insert_WME (Fact (I, "a"));
      end loop;
      if Get_Beta_Match_Count (B) /= 100 then
         Fail ("capacity: 10 x 10 cross join is not 100 tokens");
      end if;
      begin
         Insert_WME (Fact (11, "a"));
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("beta memory over 100 tokens", Got);
      --  a full beta memory, then removing a fact that is in 19 of its tokens
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      Prev := Add_Beta_Node (0, A1, Cross);
      B := Add_Beta_Node (Prev, A1, Cross);
      for I in 1 .. 10 loop
         Insert_WME (Fact (I, "a"));
      end loop;
      begin
         Remove_WME (10);
      exception
         when others => Fail ("capacity: removal from a full beta memory raised");
      end;
      if Get_Beta_Match_Count (B) /= 81 then
         Fail ("capacity: 9 x 9 tokens expected after removing one of 10 facts");
      end if;

      --  token length: a chain of 9 joins needs 9 facts per token
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      Prev := 0;
      for K in 1 .. 9 loop
         Prev := Add_Beta_Node (Prev, A1, Cross);
      end loop;
      begin
         Insert_WME (Fact (1, "a"));
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("token of 9 facts (left activation)", Got);
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      A2 := Add_Alpha_Node (To_Symbol ("b"), To_Symbol ("v"));
      Prev := 0;
      for K in 1 .. 8 loop
         Prev := Add_Beta_Node (Prev, A1, Cross);
      end loop;
      B := Add_Beta_Node (Prev, A2, Cross);
      Insert_WME (Fact (1, "a"));
      if Get_Beta_Match_Count (Prev) /= 1 or else Get_Beta_Match_Count (B) /= 0 then
         Fail ("capacity: chain of 8 joins on one fact");
      end if;
      begin
         Insert_WME (Fact (2, "b"));
         Got := False;
      exception
         when Network_Full => Got := True;
         when others => Got := False;
      end;
      Expect_Full ("token of 9 facts (right activation)", Got);
   end;
   --  Initialize_Network "clears network and memories" (rete.ads): after a
   --  network with facts in alpha / beta memories 1 .. 3 is reinitialized,
   --  every match count is 0 (also for nodes not yet re-created), and a
   --  rebuilt network counts only the new facts. The root token is empty:
   --  a root join with a condition on token index 1 never matches, even a
   --  fact whose fields are empty symbols.
   declare
      A1, A2 : Alpha_Node_ID;
      B1, B2 : Beta_Node_ID;
      Cond1 : constant Join_Condition := (1, Select_Entity, Select_Entity);
      Cross : constant Join_Condition := (0, Select_Entity, Select_Entity);
   begin
      Initialize_Network;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      A2 := Add_Alpha_Node (To_Symbol ("b"), To_Symbol ("v"));
      B1 := Add_Beta_Node (0, A1, Cross);
      B2 := Add_Beta_Node (B1, A2, Cross);
      Add_Rule (1, To_Symbol ("r"), B2);
      for I in 1 .. 4 loop
         Insert_WME ((WME_ID (I), To_Symbol ("e"), To_Symbol ((if I mod 2 = 0 then "a" else "b")), To_Symbol ("v")));
      end loop;
      if Get_Beta_Match_Count (B2) /= 4 then
         Fail ("init: 2 x 2 cross join is not 4 tokens");
      end if;
      Initialize_Network;
      for N in 1 .. 3 loop
         if Get_Alpha_Match_Count (Alpha_Node_ID (N)) /= 0 or else Get_Beta_Match_Count (Beta_Node_ID (N)) /= 0 then
            Fail ("init: memory of node" & N'Image & " not cleared by Initialize_Network");
         end if;
      end loop;
      if Get_Global_WM_Count /= 0 or else Get_Rule_Match_Count (1) /= 0 then
         Fail ("init: working memory or rule count not cleared");
      end if;
      A1 := Add_Alpha_Node (To_Symbol ("a"), To_Symbol ("v"));
      B1 := Add_Beta_Node (0, A1, Cond1);
      Insert_WME ((10, Empty_Symbol, To_Symbol ("a"), To_Symbol ("v")));
      Insert_WME ((11, To_Symbol ("e"), To_Symbol ("a"), To_Symbol ("v")));
      if Get_Alpha_Match_Count (A1) /= 2 then
         Fail ("init: rebuilt alpha memory does not hold exactly the 2 new facts");
      end if;
      if Get_Beta_Match_Count (B1) /= 0 then
         Fail ("init: root join on token index 1 matched (the root token is empty)");
      end if;
   end;
   Put_Line ("own checks: beta memories compared with naive matching" & Compared'Image
             & " times, networks skipped as full" & Full_Skips'Image);
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
