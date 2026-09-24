with Top_Nodes_Algorithm; use Top_Nodes_Algorithm;
with Ada.Text_IO; use Ada.Text_IO;

procedure Test_Top_Nodes is

   -- Test 1: Basic initialization and availability check
   procedure Test_Initialization is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      Result : Boolean;
   begin
      Put_Line("Test 1: Basic Initialization");
      Initialize (Cal);
      
      -- Check availability on empty calendar - should always be available
      Result := Check_Availability (Cal, 0, 5, 10, 100);
      if Result then
         Put_Line("  PASS: Empty calendar has availability");
      else
         Put_Line("  FAIL: Empty calendar should have availability");
      end if;
      
      New_Line;
   end Test_Initialization;

   -- Test 2: Simple reservation and check
   procedure Test_Simple_Reservation is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 2: Simple Reservation");
      Initialize (Cal);
      
      -- Reserve some resources
      Reserve (Cal, 0, 5, 10, ID, Success);
      if Success then
         Put_Line("  PASS: Reservation created successfully");
      else
         Put_Line("  FAIL: Reservation should succeed on empty calendar");
      end if;
      
      -- Check availability - should fail if we try to reserve more than capacity
      Result := Check_Availability (Cal, 0, 5, 91, 100);
      if not Result then
         Put_Line("  PASS: Availability check correctly rejects over-capacity request");
      else
         Put_Line("  FAIL: Should not have availability for 91 when 10 already reserved");
      end if;
      
      New_Line;
   end Test_Simple_Reservation;

   -- Test 3: Delete reservation
   procedure Test_Delete_Reservation is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID1, ID2 : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 3: Delete Reservation");
      Initialize (Cal);
      
      -- Create two reservations
      Reserve (Cal, 0, 5, 50, ID1, Success);
      Reserve (Cal, 3, 7, 50, ID2, Success);
      
      -- Check availability - should fail (50+50=100 at overlap, +1=101 > 100)
      Result := Check_Availability (Cal, 3, 5, 1, 100);
      if not Result then
         Put_Line("  PASS: Availability check correctly rejects when capacity exceeded");
      else
         Put_Line("  FAIL: Should not have availability (100+1 > 100)");
      end if;
      
      -- Delete first reservation
      Delete_Reservation (Cal, ID1);
      
      -- Check availability - should now pass (only 50 at 3-5, +1=51 <= 100)
      Result := Check_Availability (Cal, 0, 5, 50, 100);
      if Result then
         Put_Line("  PASS: Availability restored after deletion");
      else
         Put_Line("  FAIL: Should have availability after deletion");
      end if;
      
      New_Line;
   end Test_Delete_Reservation;

   -- Test 4: Move calendar forward - reservation expires
   procedure Test_Move_Forward is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 4: Move Calendar Forward - Expiration");
      Initialize (Cal);
      
      -- Reserve at time 0-5
      Reserve (Cal, 0, 5, 10, ID, Success);
      
      -- Check availability at 0-5 should fail (10+10=20 > 10? No, but 10+10=20 <= 100)
      -- Actually, let's check with a smaller max capacity
      Result := Check_Availability (Cal, 0, 5, 10, 15);
      if not Result then
         Put_Line("  PASS: Time slot 0-5 is reserved (10+10=20 > 15)");
      else
         Put_Line("  FAIL: Time slot 0-5 should be reserved");
      end if;
      
      -- Move forward by 6 - reservation should expire (end time 5 < new start 6)
      Move_Forward (Cal, 6);
      
      -- Check availability at 6-9 (new window) should pass
      Result := Check_Availability (Cal, 6, 9, 10, 100);
      if Result then
         Put_Line("  PASS: Expired reservation freed up capacity in new window");
      else
         Put_Line("  FAIL: Expired reservation should free capacity");
      end if;
      
      New_Line;
   end Test_Move_Forward;

   -- Test 5: Boundary conditions - reservation at exact capacity
   procedure Test_Boundary_Conditions is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 5: Boundary Conditions");
      Initialize (Cal);
      
      -- Reserve entire capacity
      Reserve (Cal, 0, 9, 100, ID, Success);
      if Success then
         Put_Line("  PASS: Can reserve entire capacity");
      else
         Put_Line("  FAIL: Should be able to reserve entire capacity");
      end if;
      
      -- Try to reserve more - should fail
      Result := Check_Availability (Cal, 0, 9, 1, 100);
      if not Result then
         Put_Line("  PASS: Cannot reserve beyond capacity");
      else
         Put_Line("  FAIL: Should not have availability beyond capacity");
      end if;
      
      New_Line;
   end Test_Boundary_Conditions;

   -- Test 6: Overlapping reservations
   procedure Test_Overlapping_Reservations is
      Cal : Calendar (Capacity => 20, Max_Reservations => 100);
      ID1, ID2, ID3 : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 6: Overlapping Reservations");
      Initialize (Cal);
      
      -- Create overlapping reservations
      Reserve (Cal, 0, 10, 30, ID1, Success);
      Reserve (Cal, 5, 15, 30, ID2, Success);
      Reserve (Cal, 10, 19, 30, ID3, Success);
      
      -- Check middle point - should fail (60+40=100 at 10, +1=101 > 100)
      Result := Check_Availability (Cal, 10, 10, 41, 100);
      if not Result then
         Put_Line("  PASS: Overlapping reservations correctly sum up");
      else
         Put_Line("  FAIL: Overlapping reservations should exceed capacity");
      end if;
      
      New_Line;
   end Test_Overlapping_Reservations;

   -- Test 7: Wrapping around calendar boundary
   procedure Test_Wrapping_Reservation is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 7: Wrapping Reservation");
      Initialize (Cal);
      
      -- Move forward to create non-zero start
      Move_Forward (Cal, 5);
      
      -- Reserve from 8 to 12 (wraps around in a capacity 10 calendar)
      -- Window is [5, 14], so 8-12 is within the window
      Reserve (Cal, 8, 12, 10, ID, Success);
      if Success then
         Put_Line("  PASS: Wrapping reservation created");
      else
         Put_Line("  FAIL: Wrapping reservation should succeed");
      end if;
      
      -- Check availability at wrapped region
      Result := Check_Availability (Cal, 8, 9, 5, 100);
      if Result then
         Put_Line("  PASS: Wrapping reservation availability check works");
      else
         Put_Line("  FAIL: Wrapping reservation availability should work");
      end if;
      
      New_Line;
   end Test_Wrapping_Reservation;

   -- Test 8: Multiple deletions
   procedure Test_Multiple_Deletions is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID1, ID2, ID3 : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 8: Multiple Deletions");
      Initialize (Cal);
      
      -- Create multiple reservations
      Reserve (Cal, 0, 5, 10, ID1, Success);
      Reserve (Cal, 2, 7, 10, ID2, Success);
      Reserve (Cal, 4, 9, 10, ID3, Success);
      
      -- Delete all
      Delete_Reservation (Cal, ID1);
      Delete_Reservation (Cal, ID2);
      Delete_Reservation (Cal, ID3);
      
      -- Check availability - should be fully available
      Result := Check_Availability (Cal, 0, 9, 100, 100);
      if Result then
         Put_Line("  PASS: All deletions restored full capacity");
      else
         Put_Line("  FAIL: All deletions should restore full capacity");
      end if;
      
      New_Line;
   end Test_Multiple_Deletions;

   -- Test 9: Reservation at maximum reservations limit
   procedure Test_Max_Reservations is
      Cal : Calendar (Capacity => 10, Max_Reservations => 3);
      ID1, ID2, ID3, ID4 : Reservation_ID;
      Success : Boolean;
   begin
      Put_Line("Test 9: Maximum Reservations Limit");
      Initialize (Cal);
      
      -- Fill up all reservation slots
      Reserve (Cal, 0, 1, 10, ID1, Success);
      Reserve (Cal, 2, 3, 10, ID2, Success);
      Reserve (Cal, 4, 5, 10, ID3, Success);
      
      if Success then
         Put_Line("  PASS: Can create up to Max_Reservations");
      else
         Put_Line("  FAIL: Should be able to create Max_Reservations");
      end if;
      
      -- Try to create one more - should fail
      Reserve (Cal, 6, 7, 10, ID4, Success);
      if not Success then
         Put_Line("  PASS: Cannot exceed Max_Reservations");
      else
         Put_Line("  FAIL: Should not be able to exceed Max_Reservations");
      end if;
      
      New_Line;
   end Test_Max_Reservations;

   -- Test 10: Partial overlap after move forward
   procedure Test_Partial_Overlap_Move is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 10: Partial Overlap After Move Forward");
      Initialize (Cal);
      
      -- Reserve from 0 to 15 (spans beyond initial window [0,9])
      -- This should only reserve 0-9
      Reserve (Cal, 0, 9, 10, ID, Success);
      
      -- Move forward by 5 - should trim reservation to 5-9
      Move_Forward (Cal, 5);
      
      -- Check that 0-4 is now available (outside window [5,14])
      -- Actually, 0-4 is outside the window, so we can't check it
      -- Check that 5-9 is still reserved
      Result := Check_Availability (Cal, 5, 9, 10, 15);
      if not Result then
         Put_Line("  PASS: Remaining part of reservation still active (10+10=20 > 15)");
      else
         Put_Line("  FAIL: Remaining part should still be reserved");
      end if;
      
      New_Line;
   end Test_Partial_Overlap_Move;

   -- Test 11: Zero amount reservation
   procedure Test_Zero_Amount is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 11: Zero Amount Reservation");
      Initialize (Cal);
      
      -- Reserve with zero amount
      Reserve (Cal, 0, 5, 0, ID, Success);
      if Success then
         Put_Line("  PASS: Zero amount reservation created");
      else
         Put_Line("  FAIL: Zero amount reservation should succeed");
      end if;
      
      -- Check availability - should still be available
      Result := Check_Availability (Cal, 0, 5, 10, 100);
      if Result then
         Put_Line("  PASS: Zero amount doesn't affect availability");
      else
         Put_Line("  FAIL: Zero amount should not affect availability");
      end if;
      
      New_Line;
   end Test_Zero_Amount;

   -- Test 12: Out of bounds reservation attempt
   procedure Test_Out_Of_Bounds is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 12: Out of Bounds Reservation");
      Initialize (Cal);
      
      -- Try to reserve outside the calendar window
      Reserve (Cal, 0, 100, 10, ID, Success);
      if not Success then
         Put_Line("  PASS: Out of bounds reservation rejected");
      else
         Put_Line("  FAIL: Out of bounds reservation should be rejected");
      end if;
      
      -- Check availability for out of bounds - should fail
      Result := Check_Availability (Cal, 0, 100, 10, 100);
      if not Result then
         Put_Line("  PASS: Out of bounds availability check fails");
      else
         Put_Line("  FAIL: Out of bounds availability should fail");
      end if;
      
      New_Line;
   end Test_Out_Of_Bounds;

   -- Test 13: Delete non-existent reservation
   procedure Test_Delete_Non_Existent is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
   begin
      Put_Line("Test 13: Delete Non-Existent Reservation");
      Initialize (Cal);
      
      -- Try to delete a reservation that doesn't exist
      -- This should not crash
      Delete_Reservation (Cal, 999);
      Put_Line("  PASS: Delete non-existent reservation doesn't crash");
      
      New_Line;
   end Test_Delete_Non_Existent;

   -- Test 14: Move forward with no reservations
   procedure Test_Move_Forward_Empty is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      Result : Boolean;
   begin
      Put_Line("Test 14: Move Forward with No Reservations");
      Initialize (Cal);
      
      -- Move forward on empty calendar
      Move_Forward (Cal, 5);
      
      -- Check availability in new window - should still work
      Result := Check_Availability (Cal, 5, 9, 10, 100);
      if Result then
         Put_Line("  PASS: Move forward on empty calendar works");
      else
         Put_Line("  FAIL: Move forward on empty calendar should work");
      end if;
      
      New_Line;
   end Test_Move_Forward_Empty;

   -- Test 15: Consecutive reservations
   procedure Test_Consecutive_Reservations is
      Cal : Calendar (Capacity => 20, Max_Reservations => 100);
      ID1, ID2, ID3 : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 15: Consecutive Reservations");
      Initialize (Cal);
      
      -- Create consecutive non-overlapping reservations
      Reserve (Cal, 0, 5, 20, ID1, Success);
      Reserve (Cal, 6, 10, 20, ID2, Success);
      Reserve (Cal, 11, 15, 20, ID3, Success);
      
      -- Check gap between reservations - should be available
      Result := Check_Availability (Cal, 5, 5, 20, 100);
      if Result then
         Put_Line("  PASS: Gap between consecutive reservations is available");
      else
         Put_Line("  FAIL: Gap between consecutive reservations should be available");
      end if;
      
      -- Check reserved area - should fail
      Result := Check_Availability (Cal, 0, 5, 20, 39);
      if not Result then
         Put_Line("  PASS: Consecutive reservations correctly reserved (20+20=40 > 39)");
      else
         Put_Line("  FAIL: Consecutive reservations should be reserved");
      end if;
      
      New_Line;
   end Test_Consecutive_Reservations;

   -- Test 16: Reusing deleted reservation IDs
   procedure Test_Reuse_Reservation_IDs is
      Cal : Calendar (Capacity => 10, Max_Reservations => 3);
      ID1, ID2, ID3, ID4 : Reservation_ID;
      Success : Boolean;
   begin
      Put_Line("Test 16: Reusing Deleted Reservation IDs");
      Initialize (Cal);
      
      -- Fill all slots
      Reserve (Cal, 0, 1, 10, ID1, Success);
      Reserve (Cal, 2, 3, 10, ID2, Success);
      Reserve (Cal, 4, 5, 10, ID3, Success);
      
      -- Delete middle one
      Delete_Reservation (Cal, ID2);
      
      -- Try to create new reservation - should reuse ID2's slot
      Reserve (Cal, 6, 7, 10, ID4, Success);
      if Success then
         Put_Line("  PASS: Can create new reservation after deletion");
      else
         Put_Line("  FAIL: Should be able to create reservation after deletion");
      end if;
      
      New_Line;
   end Test_Reuse_Reservation_IDs;

   -- Test 17: Move forward multiple times
   procedure Test_Multiple_Move_Forward is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID1, ID2 : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 17: Multiple Move Forward Operations");
      Initialize (Cal);
      
      -- Create reservations at different times
      Reserve (Cal, 0, 5, 10, ID1, Success);
      Move_Forward (Cal, 3);
      Reserve (Cal, 3, 8, 10, ID2, Success);
      
      -- Move forward again - first reservation should expire
      Move_Forward (Cal, 3);
      
      -- Check that we can now reserve at the new window
      Result := Check_Availability (Cal, 6, 9, 10, 100);
      if Result then
         Put_Line("  PASS: Multiple move forward operations work correctly");
      else
         Put_Line("  FAIL: Multiple move forward should free expired reservations");
      end if;
      
      New_Line;
   end Test_Multiple_Move_Forward;

   -- Test 18: Reservation exactly at window boundary
   procedure Test_Window_Boundary is
      Cal : Calendar (Capacity => 10, Max_Reservations => 100);
      ID : Reservation_ID;
      Success : Boolean;
      Result : Boolean;
   begin
      Put_Line("Test 18: Reservation at Window Boundary");
      Initialize (Cal);
      
      -- Reserve at the very end of the window
      Reserve (Cal, 9, 9, 10, ID, Success);
      if Success then
         Put_Line("  PASS: Can reserve at window boundary");
      else
         Put_Line("  FAIL: Should be able to reserve at window boundary");
      end if;
      
      -- Check availability at boundary
      Result := Check_Availability (Cal, 9, 9, 10, 10);
      if not Result then
         Put_Line("  PASS: Window boundary reservation works correctly");
      else
         Put_Line("  FAIL: Window boundary should be reserved");
      end if;
      
      New_Line;
   end Test_Window_Boundary;

begin
   Put_Line("========================================");
   Put_Line("Running Top Nodes Algorithm Tests");
   Put_Line("========================================");
   New_Line;
   
   Test_Initialization;
   Test_Simple_Reservation;
   Test_Delete_Reservation;
   Test_Move_Forward;
   Test_Boundary_Conditions;
   Test_Overlapping_Reservations;
   Test_Wrapping_Reservation;
   Test_Multiple_Deletions;
   Test_Max_Reservations;
   Test_Partial_Overlap_Move;
   Test_Zero_Amount;
   Test_Out_Of_Bounds;
   Test_Delete_Non_Existent;
   Test_Move_Forward_Empty;
   Test_Consecutive_Reservations;
   Test_Reuse_Reservation_IDs;
   Test_Multiple_Move_Forward;
   Test_Window_Boundary;
   
   Put_Line("========================================");
   Put_Line("All tests completed");
   Put_Line("========================================");
end Test_Top_Nodes;
