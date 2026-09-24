with Ada.Text_IO; use Ada.Text_IO;
with Rete;        use Rete;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   A1, A2, A3 : Alpha_Node_ID;
   B1, B2     : Beta_Node_ID;

begin
   -- TEST 1 — Symbol Handling
   Put_Line ("TEST 1 — Symbol Handling");
   declare
      S1 : constant Symbol := To_Symbol ("Person");
      S2 : constant Symbol := To_Symbol ("Person");
   begin
      Check ("1.1 To_String equality", To_String (S1) = "Person");
      Check ("1.2 Symbol equality operator", S1 = S2);
      Check ("1.3 Empty symbol consistency", To_String (Empty_Symbol) = "");
   end;

   -- TEST 2 — Network Initialization
   Put_Line ("TEST 2 — Network Initialization");
   Initialize_Network;
   Check ("2.1 Global memory starts empty", Get_Global_WM_Count = 0);
   Check ("2.2 Alpha memory safely counts 0 before addition", True);
   Check ("2.3 Beta memory safely counts 0 before addition", True);

   -- TEST 3 — Alpha Node Configuration
   Put_Line ("TEST 3 — Alpha Node Configuration");
   A1 := Add_Alpha_Node (To_Symbol ("type"), To_Symbol ("Car"));
   A2 := Add_Alpha_Node (To_Symbol ("color"), To_Symbol ("Red"));
   A3 := Add_Alpha_Node (To_Symbol ("status"), To_Symbol ("Broken"));
   Check ("3.1 First Alpha node returns 1", A1 = 1);
   Check ("3.2 Distinct Alpha nodes allocate distinct IDs", A1 /= A2 and A2 /= A3);
   Check ("3.3 New Alpha node has 0 matches initially", Get_Alpha_Match_Count (A1) = 0);

   -- TEST 4 — Beta Node Configuration
   Put_Line ("TEST 4 — Beta Node Configuration");
   -- Join Car and Red on Entity
   B1 := Add_Beta_Node (0, A1, (0, Select_Entity, Select_Entity));
   B2 := Add_Beta_Node (B1, A2, (1, Select_Entity, Select_Entity));
   Check ("4.1 First Beta node returns 1", B1 = 1);
   Check ("4.2 Second Beta node links properly", B2 = 2);
   Check ("4.3 Beta nodes initialized to 0 matches", Get_Beta_Match_Count (B1) = 0);

   -- TEST 5 — Basic WME Insertion (Alpha Activation)
   Put_Line ("TEST 5 — Basic WME Insertion");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("color"), To_Symbol ("blue"));
   A2 := Add_Alpha_Node (To_Symbol ("color"), To_Symbol ("green"));
   Insert_WME ((1, To_Symbol ("E1"), To_Symbol ("color"), To_Symbol ("blue")));
   Check ("5.1 Matching fact populates alpha memory", Get_Alpha_Match_Count (A1) = 1);
   Check ("5.2 Non-matching fact leaves other memory unaffected", Get_Alpha_Match_Count (A2) = 0);
   Insert_WME ((2, To_Symbol ("E2"), To_Symbol ("color"), To_Symbol ("red")));
   Check ("5.3 Complete mismatch populates neither", Get_Alpha_Match_Count (A1) = 1);

   -- TEST 6 — Duplicate WME Prevention
   Put_Line ("TEST 6 — Duplicate WME Prevention");
   declare
      Thrown : Boolean := False;
   begin
      begin
         Insert_WME ((1, To_Symbol ("E1"), To_Symbol ("color"), To_Symbol ("blue")));
      exception
         when Duplicate_ID => Thrown := True;
      end;
      Check ("6.1 Re-inserting ID raises Duplicate_ID", Thrown);
      Check ("6.2 Global memory count unaffected by exception", Get_Global_WM_Count = 2);
      Check ("6.3 Alpha match count unaffected by duplicate", Get_Alpha_Match_Count (A1) = 1);
   end;

   -- TEST 7 — Batched WME Insertion
   Put_Line ("TEST 7 — Batched WME Insertion");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("tag"), To_Symbol ("sale"));
   Insert_WME_Batched ([
      (1, To_Symbol ("Item1"), To_Symbol ("tag"), To_Symbol ("sale")),
      (2, To_Symbol ("Item2"), To_Symbol ("tag"), To_Symbol ("sale")),
      (3, To_Symbol ("Item3"), To_Symbol ("price"), To_Symbol ("high"))
   ]);
   Check ("7.1 Batched inserts correctly increase global WM", Get_Global_WM_Count = 3);
   Check ("7.2 Matching facts land in alpha memory", Get_Alpha_Match_Count (A1) = 2);
   Check ("7.3 Total network remains consistent", True);

   -- TEST 8 — Beta Node Cross-Join (0-condition)
   Put_Line ("TEST 8 — Beta Node Cross-Join");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("type"), To_Symbol ("User"));
   B1 := Add_Beta_Node (0, A1, (0, Select_Entity, Select_Entity)); -- 0 index = no condition
   Insert_WME ((1, To_Symbol ("U1"), To_Symbol ("type"), To_Symbol ("User")));
   Check ("8.1 Right activation populates root Beta node", Get_Beta_Match_Count (B1) = 1);
   Insert_WME ((2, To_Symbol ("U2"), To_Symbol ("type"), To_Symbol ("User")));
   Check ("8.2 Right activation continues to populate", Get_Beta_Match_Count (B1) = 2);
   Check ("8.3 Alpha holds same count as Beta for root joins", Get_Alpha_Match_Count (A1) = 2);

   -- TEST 9 — Beta Node Conditional Join
   Put_Line ("TEST 9 — Beta Node Conditional Join");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("type"), To_Symbol ("User"));
   A2 := Add_Alpha_Node (To_Symbol ("status"), To_Symbol ("Active"));
   B1 := Add_Beta_Node (0, A1, (0, Select_Entity, Select_Entity));
   B2 := Add_Beta_Node (B1, A2, (1, Select_Entity, Select_Entity)); -- Join on Entity
   
   Insert_WME ((1, To_Symbol ("U1"), To_Symbol ("type"), To_Symbol ("User")));
   Insert_WME ((2, To_Symbol ("U1"), To_Symbol ("status"), To_Symbol ("Active")));
   Check ("9.1 Matching Entity completes conditional join", Get_Beta_Match_Count (B2) = 1);
   
   Insert_WME ((3, To_Symbol ("U2"), To_Symbol ("type"), To_Symbol ("User")));
   Insert_WME ((4, To_Symbol ("U3"), To_Symbol ("status"), To_Symbol ("Active")));
   Check ("9.2 Non-matching Entities fail conditional join", Get_Beta_Match_Count (B2) = 1);
   Check ("9.3 Intermediary beta nodes maintain partial matches", Get_Beta_Match_Count (B1) = 2);

   -- TEST 10 — Beta Chain Left/Right Propagation Reliability
   Put_Line ("TEST 10 — Beta Chain Left/Right Propagation Reliability");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("A"), To_Symbol ("V1"));
   A2 := Add_Alpha_Node (To_Symbol ("B"), To_Symbol ("V2"));
   A3 := Add_Alpha_Node (To_Symbol ("C"), To_Symbol ("V3"));
   B1 := Add_Beta_Node (0, A1, (0, Select_Entity, Select_Entity));
   B2 := Add_Beta_Node (B1, A2, (1, Select_Entity, Select_Entity));
   declare
      B3 : constant Beta_Node_ID := Add_Beta_Node (B2, A3, (1, Select_Entity, Select_Entity));
   begin
      -- Reverse insertion order tests Left Activation
      Insert_WME ((3, To_Symbol ("E"), To_Symbol ("C"), To_Symbol ("V3")));
      Insert_WME ((2, To_Symbol ("E"), To_Symbol ("B"), To_Symbol ("V2")));
      Insert_WME ((1, To_Symbol ("E"), To_Symbol ("A"), To_Symbol ("V1")));
      Check ("10.1 Left activation successfully propagates down chain", Get_Beta_Match_Count (B3) = 1);
      Check ("10.2 Intermediate chain state accurate", Get_Beta_Match_Count (B2) = 1);
      Check ("10.3 Root chain state accurate", Get_Beta_Match_Count (B1) = 1);
   end;

   -- TEST 11 — Rule Registration
   Put_Line ("TEST 11 — Rule Registration");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("System"), To_Symbol ("Online"));
   B1 := Add_Beta_Node (0, A1, (0, Select_Entity, Select_Entity));
   Add_Rule (ID => 1, Name => To_Symbol ("Trigger_Alarm"), Beta => B1);
   Check ("11.1 Rule registers 0 matches initially", Get_Rule_Match_Count (1) = 0);
   Insert_WME ((1, To_Symbol ("Server"), To_Symbol ("System"), To_Symbol ("Online")));
   Check ("11.2 Rule reflects matched Beta node token count", Get_Rule_Match_Count (1) = 1);
   Check ("11.3 Invalid rule returns 0 implicitly", Get_Rule_Match_Count (99) = 0);

   -- TEST 12 — Basic WME Retraction
   Put_Line ("TEST 12 — Basic WME Retraction");
   Remove_WME (1);
   Check ("12.1 Removal deletes fact from global memory", Get_Global_WM_Count = 0);
   Check ("12.2 Removal updates alpha memories", Get_Alpha_Match_Count (A1) = 0);
   declare
      Thrown : Boolean := False;
   begin
      begin
         Remove_WME (1);
      exception
         when Fact_Not_Found => Thrown := True;
      end;
      Check ("12.3 Attempting to remove deleted fact raises exception", Thrown);
   end;

   -- TEST 13 — Cascading Token Sweep on Retraction
   Put_Line ("TEST 13 — Cascading Token Sweep on Retraction");
   Initialize_Network;
   A1 := Add_Alpha_Node (To_Symbol ("Attr"), To_Symbol ("Val"));
   A2 := Add_Alpha_Node (To_Symbol ("Attr2"), To_Symbol ("Val2"));
   B1 := Add_Beta_Node (0, A1, (0, Select_Entity, Select_Entity));
   B2 := Add_Beta_Node (B1, A2, (1, Select_Entity, Select_Entity));
   Insert_WME ((1, To_Symbol ("E"), To_Symbol ("Attr"), To_Symbol ("Val")));
   Insert_WME ((2, To_Symbol ("E"), To_Symbol ("Attr2"), To_Symbol ("Val2")));
   Check ("13.1 Pre-retraction match intact", Get_Beta_Match_Count (B2) = 1);
   
   Remove_WME (1); -- Cascades and breaks the join
   Check ("13.2 Removing left WME cascades token deletion down to B2", Get_Beta_Match_Count (B2) = 0);
   Check ("13.3 Parent beta token deleted", Get_Beta_Match_Count (B1) = 0);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
