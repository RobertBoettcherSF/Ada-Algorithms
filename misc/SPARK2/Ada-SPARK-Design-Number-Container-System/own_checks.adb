--  Own checks (see tests/SOURCES.txt): the container against an own stack model,
--  and full / empty operations must be rejected, not ignored.
with Ada.Assertions;
with Ada.Text_IO;
with Design_Number_Container_System; use Design_Number_Container_System;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   function Next (Bound : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Natural (Seed mod Long_Long_Integer (Bound));
   end Next;
   type Model_Array is array (1 .. Capacity) of Integer;
   C : Container;
   M : Model_Array := [others => 0];
   N : Natural := 0;
   V : Integer;
   procedure Check (Ok : Boolean; Label : String) is
   begin
      if not Ok then
         Ada.Text_IO.Put_Line ("FAIL own check: " & Label);
         raise Program_Error;
      end if;
   end Check;
   function Model_Has (X : Integer) return Boolean is
     (for some I in 1 .. N => M (I) = X);
begin
   for Run in 1 .. 1000 loop
      Initialize (C); N := 0;
      for Op in 1 .. 60 loop
         if N < Capacity and then (N = 0 or else Next (3) > 0) then
            V := Next (25);
            Add (C, V); N := N + 1; M (N) := V;
         elsif N > 0 then
            Remove_Last (C, V);
            Check (V = M (N), "Remove_Last returned the wrong value");
            N := N - 1;
         end if;
         Check (Length (C) = N, "Length differs from the model");
         for X in 0 .. 24 loop
            Check (Contains (C, X) = Model_Has (X), "Contains differs from the model");
         end loop;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks: 1000 random runs x 60 operations (own stack model)");

   Initialize (C);
   for I in 1 .. Capacity loop Add (C, I); end loop;
   begin
      Add (C, 99);
      Ada.Text_IO.Put_Line ("FAIL own check: Add on a full container accepted (value dropped)");
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Add on a full container rejected");
   end;
   Initialize (C);
   begin
      Remove_Last (C, V);
      Ada.Text_IO.Put_Line ("FAIL own check: Remove_Last on an empty container answered" & Integer'Image (V));
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Remove_Last on an empty container rejected");
   end;
end Own_Checks;
