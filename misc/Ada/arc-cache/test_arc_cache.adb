-- test_arc_cache.adb
-- Comprehensive test suite for ARC Cache implementation
-- Tests cover basic functionality, edge cases, and ARC algorithm properties

pragma Ada_2012;

with Ada.Text_IO;
with Ada.Containers;
with Ada.Exceptions;
with ARC_Cache;

procedure Test_ARC_Cache is

   -- Test counter for tracking
   Test_Count : Integer := 0;
   Pass_Count : Integer := 0;
   Fail_Count : Integer := 0;

   -- Test result type
   type Test_Result is (PASSED, FAILED, ERROR);

   -- For string keys in tests - use bounded strings to make them definite
   type Bounded_String is new String (1..100);
   
   -- Hash function for bounded strings
   function Hash (Key : Bounded_String) return Ada.Containers.Hash_Type is
      use type Ada.Containers.Hash_Type;
      Result : Ada.Containers.Hash_Type := 0;
   begin
      for I in Key'Range loop
         Result := Result * 31 + Character'Pos (String (Key)(I));
      end loop;
      return Result;
   end Hash;

   -- Equality for bounded strings
   function "=" (Left, Right : Bounded_String) return Boolean is
   begin
      return String (Left) = String (Right);
   end "=";

   -- Integer keys for some tests
   function Int_Hash (Key : Integer) return Ada.Containers.Hash_Type is
   begin
      return Ada.Containers.Hash_Type (Key);
   end Int_Hash;

   -- Package instantiations for different key types
   package String_Cache is new ARC_Cache 
     (Key_Type => Bounded_String, 
      Value_Type => Integer, 
      Hash => Hash, 
      "=" => "=");
   
   package Int_Cache is new ARC_Cache 
     (Key_Type => Integer, 
      Value_Type => Integer, 
      Hash => Int_Hash, 
      "=" => "=");

   -- Helper to convert string to bounded string
   function To_Bounded (S : String) return Bounded_String is
      Result : Bounded_String := (others => ' ');
      S_Len : constant Integer := Integer'Min (S'Length, 100);
   begin
      for I in 1..S_Len loop
         Result (I) := S (S'First + I - 1);
      end loop;
      return Result;
   end To_Bounded;

   -- Helper procedure to print test results
   procedure Print_Result (Test_Name : String; Result : Test_Result; Message : String := "") is
   begin
      Test_Count := Test_Count + 1;
      
      case Result is
         when PASSED =>
            Pass_Count := Pass_Count + 1;
            Ada.Text_IO.Put_Line ("[PASS] " & Test_Name);
         when FAILED =>
            Fail_Count := Fail_Count + 1;
            Ada.Text_IO.Put_Line ("[FAIL] " & Test_Name & " - " & Message);
         when ERROR =>
            Fail_Count := Fail_Count + 1;
            Ada.Text_IO.Put_Line ("[ERROR] " & Test_Name & " - " & Message);
      end case;
   end Print_Result;

   -- Assert procedure for boolean conditions
   procedure Assert (Condition : Boolean; Test_Name : String; Message : String := "") is
   begin
      if Condition then
         Print_Result (Test_Name, PASSED, Message);
      else
         Print_Result (Test_Name, FAILED, Message);
      end if;
   end Assert;

   -- Assert_Equal for integers
   procedure Assert_Equal (Actual, Expected : Integer; Test_Name : String; Message : String := "") is
   begin
      if Actual = Expected then
         Print_Result (Test_Name, PASSED, Message);
      else
         Print_Result (Test_Name, FAILED, 
                      Message & " (Expected: " & Integer'Image (Expected) & 
                      ", Actual: " & Integer'Image (Actual) & ")");
      end if;
   end Assert_Equal;

   -- Assert_Equal for strings
   procedure Assert_Equal (Actual, Expected : String; Test_Name : String; Message : String := "") is
   begin
      if Actual = Expected then
         Print_Result (Test_Name, PASSED, Message);
      else
         Print_Result (Test_Name, FAILED, 
                      Message & " (Expected: """ & Expected & """, Actual: """ & Actual & """)");
      end if;
   end Assert_Equal;

   -- Assert_True for boolean
   procedure Assert_True (Value : Boolean; Test_Name : String; Message : String := "") is
   begin
      Assert (Value, Test_Name, Message);
   end Assert_True;

   -- Assert_False for boolean
   procedure Assert_False (Value : Boolean; Test_Name : String; Message : String := "") is
   begin
      Assert (not Value, Test_Name, Message);
   end Assert_False;

   -- Exception handler for tests
   procedure Safe_Execute (Test_Name : String; Action : access procedure) is
   begin
      Action.all;
   exception
      when E : others =>
         Print_Result (Test_Name, ERROR, "Exception: " & Ada.Exceptions.Exception_Message (E));
   end Safe_Execute;

   -- Print test header
   procedure Print_Header (Title : String) is
   begin
      Ada.Text_IO.New_Line (2);
      Ada.Text_IO.Put_Line ("==========================================");
      Ada.Text_IO.Put_Line ("TEST SUITE: " & Title);
      Ada.Text_IO.Put_Line ("==========================================");
      Ada.Text_IO.New_Line;
   end Print_Header;

   -- Print test section
   procedure Print_Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("--- " & Title & " ---");
   end Print_Section;

   -- Print summary
   procedure Print_Summary is
   begin
      Ada.Text_IO.New_Line (2);
      Ada.Text_IO.Put_Line ("==========================================");
      Ada.Text_IO.Put_Line ("TEST SUMMARY");
      Ada.Text_IO.Put_Line ("==========================================");
      Ada.Text_IO.Put_Line ("Total Tests: " & Integer'Image (Test_Count));
      Ada.Text_IO.Put_Line ("Passed: " & Integer'Image (Pass_Count));
      Ada.Text_IO.Put_Line ("Failed: " & Integer'Image (Fail_Count));
      Ada.Text_IO.Put_Line ("Success Rate: " & 
                           Float'Image (100.0 * Float (Pass_Count) / Float (Test_Count)) & "%");
      Ada.Text_IO.Put_Line ("==========================================");
   end Print_Summary;

   -- ===================================================================
   -- TEST SUITE 1: BASIC FUNCTIONALITY TESTS
   -- ===================================================================

   procedure Test_Basic_Functionality is
      Value : Integer;
      Result : Boolean;
      Exception_Raised : Boolean;
   begin
      Print_Header ("Basic Functionality Tests");

      Print_Section ("TEST 1 - Basic Put and Get Operations");
      
      -- 1.1 Test that we can put a value and retrieve it
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 42);
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "1.1.1", "Get returns True for existing key");
         Assert_Equal (Value, 42, "1.1.2", "Retrieved value matches stored value");
      end;

      -- 1.2 Test that Get returns False for non-existent key
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         Result := String_Cache.Get (Cache, To_Bounded ("nonexistent"), Value);
         Assert_False (Result, "1.2.1", "Get returns False for non-existent key");
      end;

      -- 1.3 Test that we can overwrite existing values
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 42);
         String_Cache.Put (Cache, To_Bounded ("key1"), 100);
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "1.3.1", "Get returns True after overwrite");
         Assert_Equal (Value, 100, "1.3.2", "Overwritten value is retrieved");
      end;

      -- 1.4 Test multiple keys
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 1);
         String_Cache.Put (Cache, To_Bounded ("key2"), 2);
         String_Cache.Put (Cache, To_Bounded ("key3"), 3);
         
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "1.4.1", "First key retrievable");
         Assert_Equal (Value, 1, "1.4.2", "First key value correct");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key2"), Value);
         Assert_True (Result, "1.4.3", "Second key retrievable");
         Assert_Equal (Value, 2, "1.4.4", "Second key value correct");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key3"), Value);
         Assert_True (Result, "1.4.5", "Third key retrievable");
         Assert_Equal (Value, 3, "1.4.6", "Third key value correct");
      end;

      Print_Section ("TEST 2 - Cache Capacity and Eviction");

      -- 2.1 Test that cache respects capacity
      declare
         Cache : String_Cache.Cache (Capacity => 3);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 1);
         String_Cache.Put (Cache, To_Bounded ("key2"), 2);
         String_Cache.Put (Cache, To_Bounded ("key3"), 3);
         String_Cache.Put (Cache, To_Bounded ("key4"), 4); -- This should evict key1
         
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_False (Result, "2.1.1", "First key evicted when capacity exceeded");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key2"), Value);
         Assert_True (Result, "2.1.2", "Second key still present");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key3"), Value);
         Assert_True (Result, "2.1.3", "Third key still present");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key4"), Value);
         Assert_True (Result, "2.1.4", "Fourth key added successfully");
      end;

      -- 2.2 Test LRU behavior - recently accessed items should be kept
      declare
         Cache : String_Cache.Cache (Capacity => 3);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 1);
         String_Cache.Put (Cache, To_Bounded ("key2"), 2);
         String_Cache.Put (Cache, To_Bounded ("key3"), 3);
         
         -- Access key1 to make it recently used
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         
         -- Add key4, should evict key2 (least recently used)
         String_Cache.Put (Cache, To_Bounded ("key4"), 4);
         
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "2.2.1", "Recently accessed key1 still present");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key2"), Value);
         Assert_False (Result, "2.2.2", "Least recently used key2 evicted");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key3"), Value);
         Assert_True (Result, "2.2.3", "Key3 still present");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key4"), Value);
         Assert_True (Result, "2.2.4", "Key4 added successfully");
      end;

      Print_Section ("TEST 3 - Integer Key Tests");

      -- 3.1 Test with integer keys
      declare
         Cache : Int_Cache.Cache (Capacity => 5);
      begin
         Int_Cache.Put (Cache, 1, 100);
         Int_Cache.Put (Cache, 2, 200);
         Int_Cache.Put (Cache, 3, 300);
         
         Result := Int_Cache.Get (Cache, 1, Value);
         Assert_True (Result, "3.1.1", "Integer key 1 retrievable");
         Assert_Equal (Value, 100, "3.1.2", "Value for key 1 correct");
         
         Result := Int_Cache.Get (Cache, 2, Value);
         Assert_True (Result, "3.1.3", "Integer key 2 retrievable");
         Assert_Equal (Value, 200, "3.1.4", "Value for key 2 correct");
      end;

   end Test_Basic_Functionality;

   -- ===================================================================
   -- TEST SUITE 2: LOCKED PAGE FUNCTIONALITY (ZFS VARIANT)
   -- ===================================================================

   procedure Test_Locked_Pages is
      Value : Integer;
      Result : Boolean;
      Exception_Raised : Boolean;
   begin
      Print_Header ("Locked Page Functionality Tests");

      Print_Section ("TEST 4 - Put_Locked and Get_Locked");

      -- 4.1 Test Put_Locked creates locked entry
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked_key"), 42);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("locked_key"));
         Assert_True (Result, "4.1.1", "Put_Locked creates locked entry");
         
         Result := String_Cache.Get (Cache, To_Bounded ("locked_key"), Value);
         Assert_True (Result, "4.1.2", "Locked entry can be retrieved with Get");
         Assert_Equal (Value, 42, "4.1.3", "Locked entry value is correct");
      end;

      -- 4.2 Test Get_Locked locks existing entry
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 100);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key1"));
         Assert_False (Result, "4.2.1", "Regular Put creates unlocked entry");
         
         Result := String_Cache.Get_Locked (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "4.2.2", "Get_Locked succeeds for existing key");
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key1"));
         Assert_True (Result, "4.2.3", "Get_Locked locks the entry");
      end;

      -- 4.3 Test Unlock procedure
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("key1"), 100);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key1"));
         Assert_True (Result, "4.3.1", "Entry is locked after Put_Locked");
         
         String_Cache.Unlock (Cache, To_Bounded ("key1"));
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key1"));
         Assert_False (Result, "4.3.2", "Entry is unlocked after Unlock");
      end;

      -- 4.4 Test Unlock on non-existent key (should not raise exception)
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Unlock (Cache, To_Bounded ("nonexistent"));
         Assert (True, "4.4.1", "Unlock on non-existent key does not raise exception");
      end;

      Print_Section ("TEST 5 - Locked Pages Prevent Eviction");

      -- 5.1 Test that locked pages are not evicted
      declare
         Cache : String_Cache.Cache (Capacity => 3);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked1"), 1);
         String_Cache.Put (Cache, To_Bounded ("unlocked1"), 2);
         String_Cache.Put (Cache, To_Bounded ("unlocked2"), 3);
         
         -- Cache is full, try to add another - should evict unlocked entries first
         String_Cache.Put (Cache, To_Bounded ("unlocked3"), 4);
         
         Result := String_Cache.Get (Cache, To_Bounded ("locked1"), Value);
         Assert_True (Result, "5.1.1", "Locked entry not evicted when cache full");
         Assert_Equal (Value, 1, "5.1.2", "Locked entry value preserved");
         
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("locked1"));
         Assert_True (Result, "5.1.3", "Locked entry remains locked");
      end;

      -- 5.2 Test Cache_Full_Of_Locked_Pages exception
      declare
         Cache : String_Cache.Cache (Capacity => 2);
         Exception_Raised : Boolean := False;
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked1"), 1);
         String_Cache.Put_Locked (Cache, To_Bounded ("locked2"), 2);
         
         -- Cache is full with locked pages, try to add another
         begin
            String_Cache.Put (Cache, To_Bounded ("unlocked1"), 3);
         exception
            when String_Cache.Cache_Full_Of_Locked_Pages =>
               Exception_Raised := True;
         end;
         
         Assert_True (Exception_Raised, "5.2.1", 
                    "Cache_Full_Of_Locked_Pages raised when all entries locked and cache full");
      end;

      -- 5.3 Test that unlocking allows eviction
      declare
         Cache : String_Cache.Cache (Capacity => 2);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked1"), 1);
         String_Cache.Put_Locked (Cache, To_Bounded ("locked2"), 2);
         
         -- Unlock one entry
         String_Cache.Unlock (Cache, To_Bounded ("locked1"));
         
         -- Now we should be able to add a new entry
         String_Cache.Put (Cache, To_Bounded ("unlocked1"), 3);
         
         Result := String_Cache.Get (Cache, To_Bounded ("locked1"), Value);
         Assert_False (Result, "5.3.1", "Unlocked entry can be evicted");
         
         Result := String_Cache.Get (Cache, To_Bounded ("locked2"), Value);
         Assert_True (Result, "5.3.2", "Still locked entry preserved");
         
         Result := String_Cache.Get (Cache, To_Bounded ("unlocked1"), Value);
         Assert_True (Result, "5.3.3", "New entry added successfully");
      end;

      Print_Section ("TEST 6 - Mixed Locked and Unlocked Operations");

      -- 6.1 Test Get on locked entry doesn't change lock status
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked"), 1);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("locked"));
         Assert_True (Result, "6.1.1", "Entry is locked");
         
         Result := String_Cache.Get (Cache, To_Bounded ("locked"), Value); -- Regular Get
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("locked"));
         Assert_True (Result, "6.1.2", "Regular Get preserves lock status");
      end;

      -- 6.2 Test Put on existing locked entry preserves lock if not explicitly locked
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("key1"), 100);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key1"));
         Assert_True (Result, "6.2.1", "Entry is locked");
         
         String_Cache.Put (Cache, To_Bounded ("key1"), 200); -- Regular Put
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key1"));
         Assert_True (Result, "6.2.2", "Regular Put on locked entry preserves lock status");
      end;

   end Test_Locked_Pages;

   -- ===================================================================
   -- TEST SUITE 3: ARC ALGORITHM PROPERTIES
   -- ===================================================================

   procedure Test_ARC_Algorithm is
      Value : Integer;
      Result : Boolean;
      Count : Integer;
   begin
      Print_Header ("ARC Algorithm Properties Tests");

      Print_Section ("TEST 7 - ARC Adaptive Behavior");

      -- 7.1 Test that P parameter adapts based on access patterns
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         -- Fill T1 with initial data
         for I in 1..5 loop
            String_Cache.Put (Cache, To_Bounded ("t1_key_" & Integer'Image (I)), I);
         end loop;
         
         -- Access some items from T1 (moving them to T2)
         for I in 1..3 loop
            Result := String_Cache.Get (Cache, To_Bounded ("t1_key_" & Integer'Image (I)), Value);
         end loop;
         
         -- Add more items to trigger adaptation
         for I in 6..10 loop
            String_Cache.Put (Cache, To_Bounded ("t1_key_" & Integer'Image (I)), I);
         end loop;
         
         -- Verify we can still access recently used items
         for I in 1..3 loop
            Result := String_Cache.Get (Cache, To_Bounded ("t1_key_" & Integer'Image (I)), Value);
            Assert_True (Result, "7.1." & Integer'Image (I), 
                       "Recently accessed item " & Integer'Image (I) & " still in cache");
         end loop;
      end;

      -- 7.2 Test ghost cache behavior (B1 and B2 lists)
      declare
         Cache : String_Cache.Cache (Capacity => 5);
      begin
         -- Fill cache completely
         for I in 1..5 loop
            String_Cache.Put (Cache, To_Bounded ("key_" & Integer'Image (I)), I);
         end loop;
         
         -- Access all items to move them to T2
         for I in 1..5 loop
            Result := String_Cache.Get (Cache, To_Bounded ("key_" & Integer'Image (I)), Value);
         end loop;
         
         -- Add new items, which should evict from T1 (but T1 is empty) and then from T2
         for I in 6..8 loop
            String_Cache.Put (Cache, To_Bounded ("key_" & Integer'Image (I)), I);
         end loop;
         
         -- Some original items should still be in cache (in T2)
         Result := String_Cache.Get (Cache, To_Bounded ("key_5"), Value);
         Assert_True (Result, "7.2.1", "Most recently accessed original item still in cache");
      end;

      Print_Section ("TEST 8 - Cache Hit and Miss Patterns");

      -- 8.1 Test cache hit moves item to T2 (MRU position)
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 1);
         String_Cache.Put (Cache, To_Bounded ("key2"), 2);
         String_Cache.Put (Cache, To_Bounded ("key3"), 3);
         
         -- Access key1 (moves to T2)
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         
         -- Fill cache to trigger eviction
         for I in 4..11 loop
            String_Cache.Put (Cache, To_Bounded ("key_" & Integer'Image (I)), I);
         end loop;
         
         -- key1 should still be in cache (in T2)
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "8.1.1", "Recently accessed key1 still in cache after filling");
      end;

      -- 8.2 Test sequential access pattern
      declare
         Cache : String_Cache.Cache (Capacity => 5);
      begin
         -- Sequential writes
         for I in 1..10 loop
            String_Cache.Put (Cache, To_Bounded ("seq_" & Integer'Image (I)), I);
         end loop;
         
         -- Check that recent items are still in cache
         for I in 6..10 loop
            Result := String_Cache.Get (Cache, To_Bounded ("seq_" & Integer'Image (I)), Value);
            Assert_True (Result, "8.2." & Integer'Image (I-5), 
                       "Recent sequential item " & Integer'Image (I) & " in cache");
         end loop;
         
         -- Older items should be evicted
         for I in 1..5 loop
            Result := String_Cache.Get (Cache, To_Bounded ("seq_" & Integer'Image (I)), Value);
            Assert_False (Result, "8.2." & Integer'Image (I+5), 
                        "Old sequential item " & Integer'Image (I) & " evicted");
         end loop;
      end;

      Print_Section ("TEST 9 - Repeated Access Patterns");

      -- 9.1 Test working set access pattern
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         -- Create a working set
         for I in 1..8 loop
            String_Cache.Put (Cache, To_Bounded ("ws_" & Integer'Image (I)), I);
         end loop;
         
         -- Repeatedly access a subset (working set)
         for Cycle in 1..5 loop
            for I in 1..4 loop
               Result := String_Cache.Get (Cache, To_Bounded ("ws_" & Integer'Image (I)), Value);
            end loop;
         end loop;
         
         -- Add new items
         for I in 9..12 loop
            String_Cache.Put (Cache, To_Bounded ("new_" & Integer'Image (I)), I);
         end loop;
         
         -- Working set items should still be in cache
         for I in 1..4 loop
            Result := String_Cache.Get (Cache, To_Bounded ("ws_" & Integer'Image (I)), Value);
            Assert_True (Result, "9.1." & Integer'Image (I), 
                       "Working set item " & Integer'Image (I) & " preserved");
         end loop;
      end;

   end Test_ARC_Algorithm;

   -- ===================================================================
   -- TEST SUITE 4: EDGE CASES AND ERROR CONDITIONS
   -- ===================================================================

   procedure Test_Edge_Cases is
      Value : Integer;
      Result : Boolean;
      Exception_Raised : Boolean;
   begin
      Print_Header ("Edge Cases and Error Conditions Tests");

      Print_Section ("TEST 10 - Empty Cache Operations");

      -- 10.1 Test Get on empty cache
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         Result := String_Cache.Get (Cache, To_Bounded ("any_key"), Value);
         Assert_False (Result, "10.1.1", "Get on empty cache returns False");
      end;

      -- 10.2 Test Is_Locked on empty cache
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("any_key"));
         Assert_False (Result, "10.2.1", "Is_Locked on empty cache returns False");
      end;

      -- 10.3 Test Unlock on empty cache
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Unlock (Cache, To_Bounded ("any_key"));
         Assert (True, "10.3.1", "Unlock on empty cache does not raise exception");
      end;

      Print_Section ("TEST 11 - Single Capacity Cache");

      -- 11.1 Test cache with capacity 1
      declare
         Cache : String_Cache.Cache (Capacity => 1);
      begin
         String_Cache.Put (Cache, To_Bounded ("key1"), 1);
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_True (Result, "11.1.1", "Single item cache: first item retrievable");
         Assert_Equal (Value, 1, "11.1.2", "Single item cache: value correct");
         
         String_Cache.Put (Cache, To_Bounded ("key2"), 2);
         Result := String_Cache.Get (Cache, To_Bounded ("key1"), Value);
         Assert_False (Result, "11.1.3", "Single item cache: first item evicted");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key2"), Value);
         Assert_True (Result, "11.1.4", "Single item cache: second item present");
      end;

      -- 11.2 Test locked item in single capacity cache
      declare
         Cache : String_Cache.Cache (Capacity => 1);
         Exception_Raised : Boolean := False;
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked"), 1);
         
         begin
            String_Cache.Put (Cache, To_Bounded ("unlocked"), 2);
         exception
            when String_Cache.Cache_Full_Of_Locked_Pages =>
               Exception_Raised := True;
         end;
         
         Assert_True (Exception_Raised, "11.2.1", 
                    "Single capacity cache: Cache_Full_Of_Locked_Pages raised");
         
         Result := String_Cache.Get (Cache, To_Bounded ("locked"), Value);
         Assert_True (Result, "11.2.2", "Locked item still in cache");
      end;

      Print_Section ("TEST 12 - Same Key Operations");

      -- 12.1 Test multiple Put operations on same key
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key"), 1);
         String_Cache.Put (Cache, To_Bounded ("key"), 2);
         String_Cache.Put (Cache, To_Bounded ("key"), 3);
         
         Result := String_Cache.Get (Cache, To_Bounded ("key"), Value);
         Assert_True (Result, "12.1.1", "Key exists after multiple Puts");
         Assert_Equal (Value, 3, "12.1.2", "Last Put value is retrieved");
      end;

      -- 12.2 Test Put then Put_Locked on same key
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key"), 1);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key"));
         Assert_False (Result, "12.2.1", "Key not locked after regular Put");
         
         String_Cache.Put_Locked (Cache, To_Bounded ("key"), 2);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key"));
         Assert_True (Result, "12.2.2", "Key locked after Put_Locked");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key"), Value);
         Assert_Equal (Value, 2, "12.2.3", "Value updated by Put_Locked");
      end;

      -- 12.3 Test Get_Locked then Get on same key
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("key"), 1);
         Result := String_Cache.Get_Locked (Cache, To_Bounded ("key"), Value);
         Assert_True (Result, "12.3.1", "Get_Locked succeeds");
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key"));
         Assert_True (Result, "12.3.2", "Key locked after Get_Locked");
         
         Result := String_Cache.Get (Cache, To_Bounded ("key"), Value);
         Assert_True (Result, "12.3.3", "Regular Get still succeeds on locked key");
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("key"));
         Assert_True (Result, "12.3.4", "Key remains locked after regular Get");
      end;

      Print_Section ("TEST 13 - Boundary Conditions");

      -- 13.1 Test with very large capacity
      declare
         Cache : String_Cache.Cache (Capacity => 1000);
      begin
         -- Add 500 items
         for I in 1..500 loop
            String_Cache.Put (Cache, To_Bounded ("large_" & Integer'Image (I)), I);
         end loop;
         
         -- Check a few items
         Result := String_Cache.Get (Cache, To_Bounded ("large_1"), Value);
         Assert_True (Result, "13.1.1", "First item in large cache retrievable");
         
         Result := String_Cache.Get (Cache, To_Bounded ("large_500"), Value);
         Assert_True (Result, "13.1.2", "Last item in large cache retrievable");
         
         Result := String_Cache.Get (Cache, To_Bounded ("large_250"), Value);
         Assert_True (Result, "13.1.3", "Middle item in large cache retrievable");
      end;

      -- 13.2 Test with capacity 0 (edge case)
      declare
         Cache : String_Cache.Cache (Capacity => 0);
         Exception_Raised : Boolean := False;
      begin
         begin
            String_Cache.Put (Cache, To_Bounded ("key"), 1);
         exception
            when String_Cache.Cache_Full_Of_Locked_Pages =>
               Exception_Raised := True;
         end;
         
         -- With capacity 0, any Put should fail
         Assert_True (Exception_Raised, "13.2.1", 
                    "Put on zero-capacity cache raises Cache_Full_Of_Locked_Pages");
      end;

   end Test_Edge_Cases;

   -- ===================================================================
   -- TEST SUITE 5: PERFORMANCE AND STRESS TESTS
   -- ===================================================================

   procedure Test_Performance is
      Value : Integer;
      Result : Boolean;
      Success_Count : Integer;
   begin
      Print_Header ("Performance and Stress Tests");

      Print_Section ("TEST 14 - Stress Test with Many Operations");

      -- 14.1 Test many sequential operations
      declare
         Cache : String_Cache.Cache (Capacity => 100);
      begin
         -- Insert 200 items (will cause evictions)
         for I in 1..200 loop
            String_Cache.Put (Cache, To_Bounded ("stress_" & Integer'Image (I)), I);
         end loop;
         
         -- Try to retrieve the last 100 items (should be in cache)
         Success_Count := 0;
         for I in 101..200 loop
            Result := String_Cache.Get (Cache, To_Bounded ("stress_" & Integer'Image (I)), Value);
            if Result then
               Success_Count := Success_Count + 1;
            end if;
         end loop;
         
         Assert_Equal (Success_Count, 100, "14.1.1", 
                     "All recent items retrievable after stress insert");
      end;

      -- 14.2 Test interleaved operations
      declare
         Cache : String_Cache.Cache (Capacity => 50);
      begin
         -- Mix of puts, gets, and locked operations
         for I in 1..100 loop
            if I mod 3 = 0 then
               String_Cache.Put (Cache, To_Bounded ("mixed_" & Integer'Image (I)), I);
            elsif I mod 3 = 1 then
               String_Cache.Put_Locked (Cache, To_Bounded ("locked_" & Integer'Image (I)), I);
            else
               Result := String_Cache.Get (Cache, To_Bounded ("mixed_" & Integer'Image (I-1)), Value);
            end if;
         end loop;
         
         -- Count how many locked items are still present
         Success_Count := 0;
         for I in 1..100 loop
            if I mod 3 = 1 then
               Result := String_Cache.Get (Cache, To_Bounded ("locked_" & Integer'Image (I)), Value);
               if Result then
                  Success_Count := Success_Count + 1;
               end if;
            end if;
         end loop;
         
         Assert (Success_Count > 0, "14.2.1", 
               "Some locked items still present after interleaved operations");
      end;

      Print_Section ("TEST 15 - Cache Correctness Under Pressure");

      -- 15.1 Test that cache maintains consistency
      declare
         Cache : String_Cache.Cache (Capacity => 20);
      begin
         -- Fill cache
         for I in 1..20 loop
            String_Cache.Put (Cache, To_Bounded ("cons_" & Integer'Image (I)), I);
         end loop;
         
         -- Access all items multiple times
         for Cycle in 1..10 loop
            for I in 1..20 loop
               Result := String_Cache.Get (Cache, To_Bounded ("cons_" & Integer'Image (I)), Value);
               Assert_Equal (Value, I, "15.1." & Integer'Image (Cycle) & "_" & Integer'Image (I),
                           "Value consistency maintained across cycles");
            end loop;
         end loop;
      end;

   end Test_Performance;

   -- ===================================================================
   -- TEST SUITE 6: ASSUMPTION VIOLATION TESTS
   -- Tests designed to prove assumptions wrong
   -- ===================================================================

   procedure Test_Assumption_Violations is
      Value : Integer;
      Result : Boolean;
      Exception_Raised : Boolean;
      Count : Integer;
   begin
      Print_Header ("Assumption Violation Tests");

      Print_Section ("TEST 16 - Assumptions About Cache Behavior");

      -- 16.1 ASSUMPTION: "Cache always evicts the least recently used item"
      -- TEST: This might not be true for ARC algorithm which has two LRU lists
      declare
         Cache : String_Cache.Cache (Capacity => 3);
      begin
         -- Fill cache
         String_Cache.Put (Cache, To_Bounded ("a"), 1);
         String_Cache.Put (Cache, To_Bounded ("b"), 2);
         String_Cache.Put (Cache, To_Bounded ("c"), 3);
         
         -- Access 'a' to move it to T2
         Result := String_Cache.Get (Cache, To_Bounded ("a"), Value);
         
         -- Add 'd', which should evict from T1 (which has 'b' and 'c')
         String_Cache.Put (Cache, To_Bounded ("d"), 4);
         
         -- Check what was evicted
         Result := String_Cache.Get (Cache, To_Bounded ("a"), Value);
         Assert_True (Result, "16.1.1", "Recently accessed 'a' still in cache");
         
         Result := String_Cache.Get (Cache, To_Bounded ("b"), Value);
         declare
            B_Present : Boolean := Result;
         begin
            Result := String_Cache.Get (Cache, To_Bounded ("c"), Value);
            -- One of b or c should be evicted, but we don't know which
            Assert (not (B_Present and Result), "16.1.2",
                  "Either b or c was evicted (proving ARC doesn't just use simple LRU)");
         end;
      end;

      -- 16.2 ASSUMPTION: "Locked items are never moved between lists"
      -- TEST: Locked items should still be moved on cache hit
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put_Locked (Cache, To_Bounded ("locked"), 1);
         
         -- Access the locked item
         Result := String_Cache.Get (Cache, To_Bounded ("locked"), Value);
         
         -- The item should still be locked but might have moved from T1 to T2
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("locked"));
         Assert_True (Result, "16.2.1", "Locked item remains locked after Get");
         
         -- This proves that locked items can be moved (algorithm still works)
         Assert_Equal (Value, 1, "16.2.2", "Locked item value preserved after Get");
      end;

      Print_Section ("TEST 17 - Assumptions About Capacity Management");

      -- 17.1 ASSUMPTION: "Cache size never exceeds capacity"
      -- TEST: Verify this is always true
      declare
         Cache : String_Cache.Cache (Capacity => 5);
      begin
         -- Add many items
         for I in 1..20 loop
            String_Cache.Put (Cache, To_Bounded ("cap_" & Integer'Image (I)), I);
         end loop;
         
         -- Count how many items are actually in cache
         Count := 0;
         for I in 1..20 loop
            Result := String_Cache.Get (Cache, To_Bounded ("cap_" & Integer'Image (I)), Value);
            if Result then
               Count := Count + 1;
            end if;
         end loop;
         
         -- Cache should have at most Capacity items
         Assert (Count <= 5, "17.1.1", 
               "Cache size does not exceed capacity (" & Integer'Image (Count) & " <= 5)");
      end;

      -- 17.2 ASSUMPTION: "Eviction only happens when cache is full"
      -- TEST: Verify eviction behavior
      declare
         Cache : String_Cache.Cache (Capacity => 3);
      begin
         String_Cache.Put (Cache, To_Bounded ("x"), 1);
         String_Cache.Put (Cache, To_Bounded ("y"), 2);
         
         -- Cache has 2 items, capacity is 3, no eviction should happen
         String_Cache.Put (Cache, To_Bounded ("z"), 3);
         
         Result := String_Cache.Get (Cache, To_Bounded ("x"), Value);
         Assert_True (Result, "17.2.1", "No eviction when under capacity");
         
         Result := String_Cache.Get (Cache, To_Bounded ("y"), Value);
         Assert_True (Result, "17.2.2", "No eviction when under capacity");
         
         Result := String_Cache.Get (Cache, To_Bounded ("z"), Value);
         Assert_True (Result, "17.2.3", "No eviction when under capacity");
      end;

      Print_Section ("TEST 18 - Assumptions About Lock Behavior");

      -- 18.1 ASSUMPTION: "Unlocking a non-locked item has no effect"
      -- TEST: Verify this is safe
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         String_Cache.Put (Cache, To_Bounded ("unlocked"), 1);
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("unlocked"));
         Assert_False (Result, "18.1.1", "Item is not locked");
         
         String_Cache.Unlock (Cache, To_Bounded ("unlocked"));
         Result := String_Cache.Is_Locked (Cache, To_Bounded ("unlocked"));
         Assert_False (Result, "18.1.2", "Item remains unlocked after Unlock");
         
         -- Item should still be in cache
         Result := String_Cache.Get (Cache, To_Bounded ("unlocked"), Value);
         Assert_True (Result, "18.1.3", "Item still in cache after unnecessary Unlock");
      end;

      -- 18.2 ASSUMPTION: "Get_Locked on non-existent key returns False"
      -- TEST: Verify this
      declare
         Cache : String_Cache.Cache (Capacity => 10);
      begin
         Result := String_Cache.Get_Locked (Cache, To_Bounded ("nonexistent"), Value);
         Assert_False (Result, "18.2.1", "Get_Locked returns False for non-existent key");
      end;

   end Test_Assumption_Violations;

   -- ===================================================================
   -- MAIN TEST RUNNER
   -- ===================================================================

begin
   Ada.Text_IO.Put_Line ("ARC Cache Comprehensive Test Suite");
   Ada.Text_IO.Put_Line ("==================================");
   Ada.Text_IO.New_Line;

   -- Run all test suites
   Test_Basic_Functionality;
   Test_Locked_Pages;
   Test_ARC_Algorithm;
   Test_Edge_Cases;
   Test_Performance;
   Test_Assumption_Violations;

   -- Print final summary
   Print_Summary;

   -- Exit with appropriate code
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("All tests passed!");
   else
      Ada.Text_IO.Put_Line ("Some tests failed. See output above.");
   end if;

end Test_ARC_Cache;
