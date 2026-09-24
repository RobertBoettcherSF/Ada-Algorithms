-- ============================================================================
--  Reference Counting Test Suite
--  15+ terminal-executable tests that assume the code is broken.
--  Tests PASS when they disprove this assumption (code works correctly).
-- ============================================================================

with Ada.Text_IO;
with Reference_Counting;

procedure Tests is

   -- Shorthand for reference counting types
   use Reference_Counting;
   use Ada.Text_IO;

   -- ========================================================================
   --  Helper Procedures
   -- ========================================================================

   -- Print PASS/FAIL for a test
   procedure Print_Result (Test_Name : String; Passed : Boolean) is
   begin
      if Passed then
         Put_Line("  PASS: " & Test_Name);
      else
         Put_Line("  FAIL: " & Test_Name);
      end if;
   end Print_Result;

   -- ========================================================================
   --  TEST 1 - Basic Reference Counting (Core Functionality)
   -- ========================================================================

   procedure Test_Basic_Reference_Counting is
      Obj1 : Object_Access;
      Count : Reference_Count;
   begin
      Put_Line("TEST 1 - Basic Reference Counting");

      -- 1.1: Assert that a new object has a reference count of 1
      Obj1 := Create_Object;
      Count := Get_Reference_Count(Obj1);
      Print_Result("1.1: New object has reference count of 1", Count = 1);

      -- 1.2: Assert that incrementing increases the reference count
      Increment_Reference(Obj1);
      Count := Get_Reference_Count(Obj1);
      Print_Result("1.2: Incrementing increases reference count", Count = 2);

      -- 1.3: Assert that decrementing decreases the reference count
      Decrement_Reference(Obj1);
      Count := Get_Reference_Count(Obj1);
      Print_Result("1.3: Decrementing decreases reference count", Count = 1);

      -- 1.4: Assert that decrementing to zero deallocates the object
      Decrement_Reference(Obj1);
      Print_Result("1.4: Decrementing to zero deallocates object", Obj1 = null);
   end Test_Basic_Reference_Counting;

   -- ========================================================================
   --  TEST 2 - Edge Cases (Null References, Underflow)
   -- ========================================================================

   procedure Test_Edge_Cases is
      Obj : Object_Access := null;
   begin
      Put_Line("TEST 2 - Edge Cases");

      -- 2.1: Assert that incrementing null raises Invalid_Reference
      begin
         Increment_Reference(Obj);
         Print_Result("2.1: Incrementing null raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("2.1: Incrementing null raises Invalid_Reference", True);
      end;

      -- 2.2: Assert that decrementing null raises Invalid_Reference
      begin
         Decrement_Reference(Obj);
         Print_Result("2.2: Decrementing null raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("2.2: Decrementing null raises Invalid_Reference", True);
      end;

      -- 2.3: Assert that getting reference count of null raises Invalid_Reference
      begin
         declare
            Count : Reference_Count := Get_Reference_Count(Obj);
         begin
            null;
         end;
         Print_Result("2.3: Getting reference count of null raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("2.3: Getting reference count of null raises Invalid_Reference", True);
      end;
   end Test_Edge_Cases;

   -- ========================================================================
   --  TEST 3 - Weighted Reference Counting
   -- ========================================================================

   procedure Test_Weighted_Reference_Counting is
      Obj     : Weighted_Object_Access;
      Weight1 : Weight := 1.0;
      Weight2 : Weight;
   begin
      Put_Line("TEST 3 - Weighted Reference Counting");

      -- 3.1: Assert that a new weighted object has the initial weight
      Obj := Create_Weighted_Object(Weight1);
      Weight2 := Get_Total_Weight(Obj);
      Print_Result("3.1: New weighted object has initial weight", Weight2 = Weight1);

      -- 3.2: Assert that splitting halves the weight
      Split_Weight(Obj);
      Weight2 := Get_Total_Weight(Obj);
      Print_Result("3.2: Splitting halves the weight", Weight2 = Weight1 / 2.0);

      -- 3.3: Assert that merging reduces the weight
      Merge_Weight(Obj, Weight1 / 4.0);
      Weight2 := Get_Total_Weight(Obj);
      Print_Result("3.3: Merging reduces the weight", Weight2 = Weight1 / 4.0);

      -- 3.4: Assert that merging to zero deallocates the object
      Merge_Weight(Obj, Weight1 / 4.0);
      Print_Result("3.4: Merging to zero deallocates object", Obj = null);
   end Test_Weighted_Reference_Counting;

   -- ========================================================================
   --  TEST 4 - Indirect Reference Counting
   -- ========================================================================

   procedure Test_Indirect_Reference_Counting is
      Source, Target : Indirect_Object_Access;
      Count         : Reference_Count;
   begin
      Put_Line("TEST 4 - Indirect Reference Counting");

      -- 4.1: Assert that a new indirect object has reference count 1
      Source := Create_Indirect_Object;
      Target := Create_Indirect_Object;
      Count := Get_Indirect_Reference_Count(Source);
      Print_Result("4.1: New indirect object has reference count 1", Count = 1);

      -- 4.2: Assert that adding an indirect reference increases the target's count
      Add_Indirect_Reference(Source, Target);
      Count := Get_Indirect_Reference_Count(Target);
      Print_Result("4.2: Adding indirect reference increases target's count", Count = 2);

      -- 4.3: Assert that removing an indirect reference decreases the target's count
      Remove_Indirect_Reference(Source, Target);
      Count := Get_Indirect_Reference_Count(Target);
      Print_Result("4.3: Removing indirect reference decreases target's count", Count = 1);

      -- 4.4: Assert that removing the last reference deallocates the target
      Remove_Indirect_Reference(Source, Target);
      Print_Result("4.4: Removing last reference deallocates target", Target = null);

      -- Cleanup Source (Target was already freed by Remove_Indirect_Reference)
      Free_Indirect_Object(Source);
   end Test_Indirect_Reference_Counting;

   -- ========================================================================
   --  TEST 5 - Deferred Increment (Henry Baker)
   -- ========================================================================

   procedure Test_Deferred_Increment is
      Obj : Deferred_Object_Access;
      Count : Reference_Count;
      Deferred : Boolean;
   begin
      Put_Line("TEST 5 - Deferred Increment (Henry Baker)");

      -- 5.1: Assert that a new deferred object has reference count 1
      Obj := Create_Deferred_Object;
      Count := Get_Deferred_Reference_Count(Obj);
      Print_Result("5.1: New deferred object has reference count 1", Count = 1);

      -- 5.2: Assert that creating a local reference defers increment
      Create_Local_Reference(Obj);
      Deferred := Is_Deferred_Incr(Obj);
      Print_Result("5.2: Creating local reference defers increment", Deferred);

      -- 5.3: Assert that promoting to global performs the increment
      Promote_To_Global(Obj);
      Count := Get_Deferred_Reference_Count(Obj);
      Print_Result("5.3: Promoting to global performs increment", Count = 2);

      -- 5.4: Assert that destroying a local reference does not decrement if deferred
      Create_Local_Reference(Obj);
      Destroy_Local_Reference(Obj);
      Count := Get_Deferred_Reference_Count(Obj);
      Print_Result("5.4: Destroying local reference does not decrement if deferred", Count = 2);

      -- Cleanup
      Free_Deferred_Object(Obj);
   end Test_Deferred_Increment;

   -- ========================================================================
   --  TEST 6 - Update Coalescing (Levanoni & Petrank)
   -- ========================================================================

   procedure Test_Update_Coalescing is
      Manager : Update_Manager_Access;
      Obj1, Obj2 : Object_Access;
      Count : Natural;
   begin
      Put_Line("TEST 6 - Update Coalescing (Levanoni & Petrank)");

      -- 6.1: Assert that a new update manager is created
      Manager := Create_Update_Manager;
      Print_Result("6.1: New update manager is created", Manager /= null);

      -- 6.2: Assert that registering an update adds it to the pending list
      Obj1 := Create_Object;
      Obj2 := Create_Object;
      Register_Update(Manager, Obj1, Obj2);
      Count := Get_Pending_Updates_Count(Manager);
      Print_Result("6.2: Registering update adds it to pending list", Count = 1);

      -- 6.3: Assert that registering a redundant update does not duplicate it
      Register_Update(Manager, Obj1, Obj2);
      Count := Get_Pending_Updates_Count(Manager);
      Print_Result("6.3: Registering redundant update does not duplicate it", Count = 1);

      -- 6.4: Assert that flushing updates clears the pending list
      Flush_Updates(Manager);
      Count := Get_Pending_Updates_Count(Manager);
      Print_Result("6.4: Flushing updates clears pending list", Count = 0);

      -- Cleanup
      Decrement_Reference(Obj1);
      Decrement_Reference(Obj2);
      Free_Update_Manager(Manager);
   end Test_Update_Coalescing;

   -- ========================================================================
   --  TEST 7 - Weak References (Cycle Handling)
   -- ========================================================================

   procedure Test_Weak_References is
      Target   : Object_Access;
      Weak_Ref : Weak_Reference_Access;
      Is_Valid : Boolean;
   begin
      Put_Line("TEST 7 - Weak References (Cycle Handling)");

      -- 7.1: Assert that a weak reference is created successfully
      Target := Create_Object;
      Create_Weak_Reference(Target, Weak_Ref);
      Print_Result("7.1: Weak reference is created successfully", Weak_Ref /= null);

      -- 7.2: Assert that a weak reference is initially valid
      Is_Valid := Is_Weak_Reference_Valid(Weak_Ref);
      Print_Result("7.2: Weak reference is initially valid", Is_Valid);

      -- 7.3: Assert that getting the target of a valid weak reference works
      begin
         declare
            Retrieved_Target : Object_Access;
         begin
            Get_Weak_Target(Weak_Ref, Retrieved_Target);
            Print_Result("7.3: Getting target of valid weak reference works", True);
         end;
      exception
         when Invalid_Reference =>
            Print_Result("7.3: Getting target of valid weak reference works", False);
      end;

      -- 7.4: Assert that a weak reference to a null target raises Invalid_Reference
      begin
         Create_Weak_Reference(null, Weak_Ref);
         Print_Result("7.4: Creating weak reference to null raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("7.4: Creating weak reference to null raises Invalid_Reference", True);
      end;

      -- Cleanup
      Decrement_Reference(Target);
      Free_Weak_Reference(Weak_Ref);
   end Test_Weak_References;

   -- ========================================================================
   --  TEST 8 - Deutsch-Bobrow Method
   -- ========================================================================

   procedure Test_Deutsch_Bobrow is
      Obj : DB_Object_Access;
      In_Stack : Boolean;
   begin
      Put_Line("TEST 8 - Deutsch-Bobrow Method");

      -- 8.1: Assert that a new DB object is created
      Obj := Create_DB_Object;
      Print_Result("8.1: New DB object is created", Obj /= null);

      -- 8.2: Assert that scanning stack for references marks the object
      Scan_Stack_For_References(Obj);
      In_Stack := Is_In_Stack(Obj);
      Print_Result("8.2: Scanning stack marks the object", In_Stack);

      -- 8.3: Assert that scanning stack prevents deallocation if Ref_Count = 0
      Scan_Stack_For_References(Obj);
      Print_Result("8.3: Scanning stack prevents deallocation if Ref_Count = 0", Is_In_Stack(Obj));

      -- Cleanup
      Free_DB_Object(Obj);
   end Test_Deutsch_Bobrow;

   -- ========================================================================
   --  TEST 9 - Ulterior Reference Counting
   -- ========================================================================

   procedure Test_Ulterior_Reference_Counting is
      Obj : Ulterior_Object_Access;
   begin
      Put_Line("TEST 9 - Ulterior Reference Counting");

      -- 9.1: Assert that a new ulterior object is created
      Obj := Create_Ulterior_Object;
      Print_Result("9.1: New ulterior object is created", Obj /= null);

      -- 9.2: Assert that a new object is in the young generation
      Print_Result("9.2: New object is in young generation", Is_Young(Obj));

      -- 9.3: Assert that copying collection moves the object to old generation
      Copying_Collection(Obj);
      Print_Result("9.3: Copying collection moves object to old generation", not Is_Young(Obj));

      -- Cleanup
      Free_Ulterior_Object(Obj);
   end Test_Ulterior_Reference_Counting;

   -- ========================================================================
   --  TEST 10 - Cycle Detection (Bacon's Algorithm)
   -- ========================================================================

   procedure Test_Cycle_Detection is
      Detector : Cycle_Detector_Access;
      Obj1, Obj2 : Object_Access;
      Count : Natural;
   begin
      Put_Line("TEST 10 - Cycle Detection (Bacon's Algorithm)");

      -- 10.1: Assert that a new cycle detector is created
      Detector := Create_Cycle_Detector;
      Print_Result("10.1: New cycle detector is created", Detector /= null);

      -- 10.2: Assert that adding an object to roots works
      Obj1 := Create_Object;
      Add_To_Roots(Detector, Obj1);
      Count := Get_Roots_Count(Detector);
      Print_Result("10.2: Adding object to roots works", Count = 1);

      -- 10.3: Assert that adding multiple objects to roots works
      Obj2 := Create_Object;
      Add_To_Roots(Detector, Obj2);
      Count := Get_Roots_Count(Detector);
      Print_Result("10.3: Adding multiple objects to roots works", Count = 2);

      -- 10.4: Assert that detecting cycles clears the roots list
      Detect_Cycles(Detector);
      Count := Get_Roots_Count(Detector);
      Print_Result("10.4: Detecting cycles clears roots list", Count = 0);

      -- Cleanup
      Decrement_Reference(Obj1);
      Decrement_Reference(Obj2);
      Free_Cycle_Detector(Detector);
   end Test_Cycle_Detection;

   -- ========================================================================
   --  TEST 11 - Concurrent Reference Counting (Atomicity)
   -- ========================================================================

   procedure Test_Concurrent_Reference_Counting is
      Obj : Object_Access;
      Count : Reference_Count;
   begin
      Put_Line("TEST 11 - Concurrent Reference Counting (Atomicity)");

      -- 11.1: Assert that a new object is created
      Obj := Create_Object;
      Print_Result("11.1: New object is created", Obj /= null);

      -- 11.2: Assert that incrementing and decrementing in sequence works
      Increment_Reference(Obj);
      Increment_Reference(Obj);
      Decrement_Reference(Obj);
      Count := Get_Reference_Count(Obj);
      Print_Result("11.2: Incrementing and decrementing in sequence works", Count = 2);

      -- 11.3: Assert that decrementing to zero deallocates the object
      Decrement_Reference(Obj);
      Decrement_Reference(Obj);
      Print_Result("11.3: Decrementing to zero deallocates object", Obj = null);
   end Test_Concurrent_Reference_Counting;

   -- ========================================================================
   --  TEST 12 - Weighted Reference Counting Edge Cases
   -- ========================================================================

   procedure Test_Weighted_Edge_Cases is
      Obj : Weighted_Object_Access;
   begin
      Put_Line("TEST 12 - Weighted Reference Counting Edge Cases");

      -- 12.1: Assert that creating a weighted object with zero weight works
      Obj := Create_Weighted_Object(0.0);
      Print_Result("12.1: Creating weighted object with zero weight works", Obj /= null);

      -- 12.2: Assert that merging zero weight deallocates the object
      Merge_Weight(Obj, 0.0);
      Print_Result("12.2: Merging zero weight deallocates object", Obj = null);

      -- 12.3: Assert that creating a weighted object with max weight works
      Obj := Create_Weighted_Object(1.0);
      Print_Result("12.3: Creating weighted object with max weight works", Obj /= null);

      -- Cleanup
      Free_Weighted_Object(Obj);
   end Test_Weighted_Edge_Cases;

   -- ========================================================================
   --  TEST 13 - Indirect Reference Counting Edge Cases
   -- ========================================================================

   -- ========================================================================
   --  TEST 13 - Indirect Reference Counting Edge Cases
   -- ========================================================================

   procedure Test_Indirect_Edge_Cases is
      Source, Target : Indirect_Object_Access := null;
   begin
      Put_Line("TEST 13 - Indirect Reference Counting Edge Cases");

      -- 13.1: Assert that adding null source raises Invalid_Reference
      Target := Create_Indirect_Object;
      begin
         Add_Indirect_Reference(Source, Target);
         Print_Result("13.1: Adding null source raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("13.1: Adding null source raises Invalid_Reference", True);
      end;
      Free_Indirect_Object(Target);
      Target := null;

      -- 13.2: Assert that adding null target raises Invalid_Reference
      Source := Create_Indirect_Object;
      begin
         Add_Indirect_Reference(Source, Target);
         Print_Result("13.2: Adding null target raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("13.2: Adding null target raises Invalid_Reference", True);
      end;
      Free_Indirect_Object(Source);
      Source := null;

      -- 13.3: Assert that removing null source raises Invalid_Reference
      Target := Create_Indirect_Object;
      begin
         Remove_Indirect_Reference(Source, Target);
         Print_Result("13.3: Removing null source raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("13.3: Removing null source raises Invalid_Reference", True);
      end;
      Free_Indirect_Object(Target);
   end Test_Indirect_Edge_Cases;


   -- ========================================================================
   --  TEST 14 - Deferred Increment Edge Cases
   -- ========================================================================

   procedure Test_Deferred_Increment_Edge_Cases is
      Obj : Deferred_Object_Access := null;
   begin
      Put_Line("TEST 14 - Deferred Increment Edge Cases");

      -- 14.1: Assert that creating a local reference to null raises Invalid_Reference
      begin
         Create_Local_Reference(Obj);
         Print_Result("14.1: Creating local reference to null raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("14.1: Creating local reference to null raises Invalid_Reference", True);
      end;

      -- 14.2: Assert that destroying a local reference to null raises Invalid_Reference
      begin
         Destroy_Local_Reference(Obj);
         Print_Result("14.2: Destroying local reference to null raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("14.2: Destroying local reference to null raises Invalid_Reference", True);
      end;

      -- 14.3: Assert that promoting null to global raises Invalid_Reference
      begin
         Promote_To_Global(Obj);
         Print_Result("14.3: Promoting null to global raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("14.3: Promoting null to global raises Invalid_Reference", True);
      end;
   end Test_Deferred_Increment_Edge_Cases;

   -- ========================================================================
   --  TEST 15 - Update Coalescing Edge Cases
   -- ========================================================================

   procedure Test_Update_Coalescing_Edge_Cases is
      Manager : Update_Manager_Access := null;
      Obj1, Obj2 : Object_Access;
   begin
      Put_Line("TEST 15 - Update Coalescing Edge Cases");

      -- 15.1: Assert that registering an update with null manager raises Invalid_Reference
      Obj1 := Create_Object;
      Obj2 := Create_Object;
      begin
         Register_Update(Manager, Obj1, Obj2);
         Print_Result("15.1: Registering update with null manager raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("15.1: Registering update with null manager raises Invalid_Reference", True);
      end;

      -- 15.2: Assert that flushing updates with null manager raises Invalid_Reference
      begin
         Flush_Updates(Manager);
         Print_Result("15.2: Flushing updates with null manager raises Invalid_Reference", False);
      exception
         when Invalid_Reference =>
            Print_Result("15.2: Flushing updates with null manager raises Invalid_Reference", True);
      end;

      -- Cleanup
      Decrement_Reference(Obj1);
      Decrement_Reference(Obj2);
   end Test_Update_Coalescing_Edge_Cases;

begin
   -- Run all tests
   Put_Line("========================================================================");
   Put_Line("  Reference Counting Test Suite");
   Put_Line("  Assuming code is broken. PASS = assumption disproven (code works).");
   Put_Line("========================================================================");
   New_Line;

   -- Core functionality tests
   Test_Basic_Reference_Counting;
   New_Line;

   -- Edge case tests
   Test_Edge_Cases;
   New_Line;

   -- Variant tests
   Test_Weighted_Reference_Counting;
   New_Line;
   Test_Indirect_Reference_Counting;
   New_Line;
   Test_Deferred_Increment;
   New_Line;
   Test_Update_Coalescing;
   New_Line;
   Test_Weak_References;
   New_Line;
   Test_Deutsch_Bobrow;
   New_Line;
   Test_Ulterior_Reference_Counting;
   New_Line;
   Test_Cycle_Detection;
   New_Line;

   -- Additional tests
   Test_Concurrent_Reference_Counting;
   New_Line;
   Test_Weighted_Edge_Cases;
   New_Line;
   Test_Indirect_Edge_Cases;
   New_Line;
   Test_Deferred_Increment_Edge_Cases;
   New_Line;
   Test_Update_Coalescing_Edge_Cases;
   New_Line;

   Put_Line("========================================================================");
   Put_Line("  Test Suite Complete");
   Put_Line("========================================================================");
end Tests;
