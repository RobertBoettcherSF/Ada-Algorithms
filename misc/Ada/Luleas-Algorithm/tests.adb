--  tests.adb
--  
--  Test suite for the Luleå Algorithm implementation.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2025
--  
--  Description:
--  This file contains tests for the Luleå Algorithm.
--  
--  Usage:
--  Compile with: gnatmake tests.adb
--  Run with: ./tests

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions; use Ada.Exceptions;
with Ada.Command_Line;
with Lulea_Algorithm; use Lulea_Algorithm;

procedure Tests is
   Fail_Count : Natural := 0;

   -- ========================================================================
   --  Helper Procedures for Testing
   -- ========================================================================

   procedure Print_Test_Header (Test_Name : String) is
   begin
      New_Line;
      Put_Line("========================================");
      Put_Line("TEST - " & Test_Name);
      Put_Line("========================================");
   end Print_Test_Header;

   procedure Print_Assertion (Assertion_Name : String) is
   begin
      Put_Line("  " & Assertion_Name);
   end Print_Assertion;

   procedure Print_Result (Passed : Boolean; Message : String := "") is
   begin
      if Passed then
         Put_Line("     PASS" & (if Message /= "" then " - " & Message else ""));
      else
         Put_Line("     FAILED" & (if Message /= "" then " - " & Message else ""));
         Fail_Count := Fail_Count + 1;
      end if;
   end Print_Result;

   -- ========================================================================
   --  Test 1: IPv4 Address Conversion
   -- ========================================================================

   procedure Test_IPv4_Conversion is
   begin
      Print_Test_Header("IPv4 Address Conversion");

      Print_Assertion("1.1 Assert IPv4_To_String(0) = 0.0.0.0");
      declare
         Result : constant String := IPv4_To_String(0);
      begin
         Assert (Result = "0.0.0.0", "IPv4_To_String(0) failed");
         Print_Result(True, "IPv4_To_String(0) = " & Result);
      end;

      Print_Assertion("1.2 Assert IPv4_To_String(16#FFFFFFFF#) = 255.255.255.255");
      declare
         Max_IPv4 : constant IPv4_Address := 16#FFFFFFFF#;
         Result : constant String := IPv4_To_String(Max_IPv4);
      begin
         Assert (Result = "255.255.255.255", "IPv4_To_String(16#FFFFFFFF#) failed");
         Print_Result(True, "IPv4_To_String(16#FFFFFFFF#) = " & Result);
      end;

      Print_Assertion("1.3 Assert String_To_IPv4(192.168.1.1) = 3232235777");
      declare
         Result : constant IPv4_Address := String_To_IPv4("192.168.1.1");
         Expected : constant IPv4_Address := 3232235777;
      begin
         Assert (Result = Expected, "String_To_IPv4(192.168.1.1) failed");
         Print_Result(True, "String_To_IPv4(192.168.1.1) = " & Result'Image);
      end;
   exception
      when E : others =>
         Print_Result(False, "Exception: " & Exception_Message(E));
   end Test_IPv4_Conversion;

   -- ========================================================================
   --  Test 2: Prefix Validation
   -- ========================================================================

   procedure Test_Prefix_Validation is
   begin
      Print_Test_Header("Prefix Validation");

      Print_Assertion("2.1 Assert Is_Valid_Prefix(Address => 0, Length => 24) = True");
      declare
         Result : constant Boolean := Is_Valid_Prefix((Address => 0, Length => 24));
      begin
         Assert (Result, "Is_Valid_Prefix failed for valid prefix");
         Print_Result(True, "Is_Valid_Prefix(Address => 0, Length => 24) = " & Result'Image);
      end;

      Print_Assertion("2.2 Assert Is_Valid_Prefix(Address => 0, Length => 33) = False");
      declare
         Result : constant Boolean := Is_Valid_Prefix((Address => 0, Length => 33));
      begin
         Assert (not Result, "Is_Valid_Prefix failed for invalid prefix");
         Print_Result(True, "Is_Valid_Prefix(Address => 0, Length => 33) = " & Result'Image);
      end;

      Print_Assertion("2.3 Assert Is_Valid_Prefix(Address => 0, Length => 0) = True");
      declare
         Result : constant Boolean := Is_Valid_Prefix((Address => 0, Length => 0));
      begin
         Assert (Result, "Is_Valid_Prefix failed for length = 0");
         Print_Result(True, "Is_Valid_Prefix(Address => 0, Length => 0) = " & Result'Image);
      end;
   exception
      when E : others =>
         Print_Result(False, "Exception: " & Exception_Message(E));
   end Test_Prefix_Validation;

   -- ========================================================================
   --  Test 3: Basic Routing Table
   -- ========================================================================

   procedure Test_Basic_Routing_Table is
      P1 : constant Prefix := (Address => 0, Length => 8);  -- 0.0.0.0/8; 255.255.255.255 must miss
      NH : constant IPv4_Address := 0;
      I1 : constant Routing_Info := (NH, 0, 0);
      Entry1 : constant Route_Entry := (Pfx => P1, Info => I1);
   begin
      Print_Test_Header("Basic Routing Table");

      Print_Assertion("3.1 Assert Build_Lulea_Trie(single entry) succeeds");
      declare
         Single_Entry : constant Routing_Table(1..1) := [1 => Entry1];
      begin
         declare
            Built : constant Lulea_Trie := Build_Lulea_Trie(Single_Entry);
         begin
            Print_Lulea_Trie (Built);
            Print_Result(True, "Build_Lulea_Trie(single entry) succeeds");
         end;
      end;

      Print_Assertion("3.2 Assert Lookup(single entry, 0.0.0.0) succeeds");
      declare
         Single_Entry : constant Routing_Table(1..1) := [1 => Entry1];
      begin
         declare
            Trie : constant Lulea_Trie := Build_Lulea_Trie(Single_Entry);
            Got : constant Routing_Info := Lookup(Trie, 0);
         begin
            if Got.Metric < 0 then raise Program_Error; end if;
            Print_Result(True, "Lookup(single entry, 0.0.0.0) succeeds");
         end;
      end;

      Print_Assertion("3.3 Assert Lookup(trie, 255.255.255.255) raises Lookup_Failure_Error (outside 0/8)");
      begin
         declare
            Single_Entry : constant Routing_Table(1..1) := [1 => Entry1];
         begin
            declare
               Trie : constant Lulea_Trie := Build_Lulea_Trie(Single_Entry);
            begin
               declare
                  Ignored : constant Routing_Info := Lookup(Trie, 16#FFFFFFFF#);
               begin
                  if Ignored.Metric = Ignored.Metric then
                     Assert (False, "Expected Lookup_Failure_Error not raised");
                     Print_Result(False, "Lookup_Failure_Error not raised");
                  end if;
               end;
            end;
         end;
      exception
         when Lookup_Failure_Error =>
            Print_Result(True, "Lookup_Failure_Error raised as expected");
      end;
   exception
      when E : others =>
         Print_Result(False, "Exception: " & Exception_Message(E));
   end Test_Basic_Routing_Table;

   -- ========================================================================
   --  Main Test Procedure
   -- ========================================================================

begin
   Put_Line("========================================");
   Put_Line("Luleå Algorithm Test Suite");
   Put_Line("========================================");
   Put_Line("Assuming the code is broken. PASS = assumption disproven.");
   New_Line;

   Test_IPv4_Conversion;
   Test_Prefix_Validation;
   Test_Basic_Routing_Table;

   New_Line;
   Put_Line("========================================");
   Put_Line("Test Suite Complete");
   Put_Line("========================================");
   Put_Line("All tests completed. Failed:" & Fail_Count'Image);
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
