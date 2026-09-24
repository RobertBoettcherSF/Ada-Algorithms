-- main.adb
-- 
-- Simple demonstration executable for the Vector Clocks Algorithm.
-- 
-- This procedure serves as a basic entry point to verify that the
-- Vector_Clocks package compiles and initializes correctly.
-- 
-- For comprehensive testing, run 'make test' to execute the full
-- test suite in tests.adb.
--
-- Author: Robert Boettcher
-- License: MIT

with Ada.Text_IO; use Ada.Text_IO;
with Vector_Clocks; use Vector_Clocks;

procedure Main is
begin
   -- Display initialization message
   Put_Line ("Vector Clocks Algorithm implementation initialized.");
   
   -- Direct users to the comprehensive test suite
   Put_Line ("Please run 'make test' to execute the comprehensive V&V test suite.");
end Main;
