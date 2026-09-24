--  Standalone test suite for Sorted_List (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Sorted_List; use Sorted_List;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   type Integer_Array is array (Positive range <>) of Integer;

   procedure Check (Condition : Boolean; Message : String) is
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

   function Is_Nondecreasing (L : List) return Boolean is
   begin
      if Length (L) <= 1 then
         return True;
      end if;
      for I in 1 .. Length (L) - 1 loop
         if Element (L, I) > Element (L, I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Nondecreasing;

   function Insert_Raises_Overflow (L : in out List; X : Integer) return Boolean is
   begin
      Insert (L, X);
      return False;
   exception
      when Overflow =>
         return True;
   end Insert_Raises_Overflow;

   function Delete_Raises (L : in out List; X : Integer) return Boolean is
   begin
      Delete (L, X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Delete_Raises;

   function Min_Raises (L : List) return Boolean is
      Unused : Integer;
   begin
      Unused := Min (L);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Min_Raises;

   function Max_Raises (L : List) return Boolean is
      Unused : Integer;
   begin
      Unused := Max (L);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Max_Raises;

   function Element_Raises (L : List; Index : Positive) return Boolean is
      Unused : Integer;
   begin
      Unused := Element (L, Index);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Element_Raises;

   -------------------------------------------------------------------------
   -- Empty / Length / Clear
   -------------------------------------------------------------------------

   procedure Test_Empty_Basics is
      L : List := Empty;
   begin
      Section ("Empty / Length / Is_Empty / Clear");
      Check (Length (L) = 0, "Empty length 0");
      Check (Is_Empty (L), "Empty Is_Empty");
      Check (not Is_Full (L), "Empty not Is_Full");
      Check (not Contains (L, 0), "Empty Contains 0 false");
      Check (Find (L, 42) = 0, "Empty Find sentinel 0");
      Check (Min_Raises (L), "Empty Min raises");
      Check (Max_Raises (L), "Empty Max raises");
      Check (Element_Raises (L, 1), "Empty Element(1) raises");
      Clear (L);
      Check (Is_Empty (L), "Clear keeps empty");
      Check (Length (L) = 0, "Clear length 0");
   end Test_Empty_Basics;

   -------------------------------------------------------------------------
   -- Insert keeps order
   -------------------------------------------------------------------------

   procedure Test_Insert_Order is
      L : List := Empty;
   begin
      Section ("Insert keeps nondecreasing order");

      Insert (L, 5);
      Check (Length (L) = 1, "Insert one length");
      Check (Element (L, 1) = 5, "Insert one value");
      Check (Min (L) = 5 and Max (L) = 5, "Insert one min=max");

      Insert (L, 3);
      Check (Element (L, 1) = 3 and Element (L, 2) = 5, "Insert before");
      Check (Is_Nondecreasing (L), "Order after insert before");

      Insert (L, 7);
      Check (Element (L, 3) = 7, "Insert after");
      Check (Min (L) = 3 and Max (L) = 7, "Min/Max after three");
      Check (Is_Nondecreasing (L), "Order after insert after");

      Insert (L, 4);
      Check (Element (L, 1) = 3, "Middle insert front");
      Check (Element (L, 2) = 4, "Middle insert mid");
      Check (Element (L, 3) = 5, "Middle insert mid2");
      Check (Element (L, 4) = 7, "Middle insert back");
      Check (Is_Nondecreasing (L), "Order after middle insert");

      --  Reverse-order fill
      Clear (L);
      for I in reverse 1 .. 10 loop
         Insert (L, I);
      end loop;
      Check (Length (L) = 10, "Reverse fill length 10");
      Check (Is_Nondecreasing (L), "Reverse fill sorted");
      Check (Min (L) = 1 and Max (L) = 10, "Reverse fill min/max");
      for I in 1 .. 10 loop
         Check (Element (L, I) = I, "Reverse fill Element" & Integer'Image (I));
      end loop;
   end Test_Insert_Order;

   -------------------------------------------------------------------------
   -- Duplicates (multiset)
   -------------------------------------------------------------------------

   procedure Test_Duplicates is
      L : List := Empty;
   begin
      Section ("Duplicates (multiset)");
      Insert (L, 2);
      Insert (L, 2);
      Insert (L, 2);
      Insert (L, 1);
      Insert (L, 3);
      Check (Length (L) = 5, "Dup length 5");
      Check (Is_Nondecreasing (L), "Dup still sorted");
      Check (Element (L, 1) = 1, "Dup Element 1");
      Check (Element (L, 2) = 2, "Dup Element 2");
      Check (Element (L, 3) = 2, "Dup Element 3");
      Check (Element (L, 4) = 2, "Dup Element 4");
      Check (Element (L, 5) = 3, "Dup Element 5");
      Check (Contains (L, 2), "Dup Contains 2");
      Check (Find (L, 2) = 2, "Dup Find leftmost 2");
      Delete (L, 2);
      Check (Length (L) = 4, "Dup Delete one length");
      Check (Find (L, 2) = 2, "Dup still has 2 at 2");
      Check (Is_Nondecreasing (L), "Dup after delete sorted");
   end Test_Duplicates;

   -------------------------------------------------------------------------
   -- Search hits / misses
   -------------------------------------------------------------------------

   procedure Test_Search is
      L : List := Empty;
      Keys : constant Integer_Array := [1, 3, 5, 7, 9];
   begin
      Section ("Contains / Find hits and misses");
      for I in Keys'Range loop
         Insert (L, Keys (I));
      end loop;
      Check (Contains (L, 1), "Hit Contains 1");
      Check (Contains (L, 5), "Hit Contains 5");
      Check (Contains (L, 9), "Hit Contains 9");
      Check (Find (L, 1) = 1, "Hit Find 1");
      Check (Find (L, 5) = 3, "Hit Find 5");
      Check (Find (L, 9) = 5, "Hit Find 9");
      Check (not Contains (L, 0), "Miss Contains 0");
      Check (not Contains (L, 2), "Miss Contains 2");
      Check (not Contains (L, 10), "Miss Contains 10");
      Check (Find (L, 0) = 0, "Miss Find 0");
      Check (Find (L, 2) = 0, "Miss Find 2");
      Check (Find (L, 10) = 0, "Miss Find 10");
      Check (Find (L, 4) = 0, "Miss Find 4");
      Check (Find (L, 8) = 0, "Miss Find 8");
   end Test_Search;

   -------------------------------------------------------------------------
   -- Delete
   -------------------------------------------------------------------------

   procedure Test_Delete is
      L : List := Empty;
   begin
      Section ("Delete / Delete_First");
      for I in 1 .. 5 loop
         Insert (L, I);
      end loop;
      Delete (L, 1);
      Check (Length (L) = 4 and Min (L) = 2, "Delete front");
      Check (Is_Nondecreasing (L), "Sorted after delete front");
      Delete (L, 5);
      Check (Length (L) = 3 and Max (L) = 4, "Delete back");
      Delete_First (L, 3);
      Check (Length (L) = 2, "Delete_First middle length");
      Check (Element (L, 1) = 2 and Element (L, 2) = 4, "Delete_First middle values");
      Check (Delete_Raises (L, 99), "Delete absent raises");
      Check (Delete_Raises (L, 3), "Delete already-gone raises");
      Delete (L, 2);
      Delete (L, 4);
      Check (Is_Empty (L), "Delete until empty");
      Check (Delete_Raises (L, 0), "Delete on empty raises");
   end Test_Delete;

   -------------------------------------------------------------------------
   -- Min / Max / Element
   -------------------------------------------------------------------------

   procedure Test_Min_Max_Element is
      L : List := Empty;
   begin
      Section ("Min / Max / Element");
      Insert (L, 10);
      Insert (L, -5);
      Insert (L, 0);
      Insert (L, 100);
      Insert (L, -5);
      Check (Min (L) = -5, "Min is -5");
      Check (Max (L) = 100, "Max is 100");
      Check (Element (L, 1) = -5, "Element 1");
      Check (Element (L, 2) = -5, "Element 2");
      Check (Element (L, 3) = 0, "Element 3");
      Check (Element (L, 4) = 10, "Element 4");
      Check (Element (L, 5) = 100, "Element 5");
      Check (Element_Raises (L, 6), "Element past end raises");
      Check (Element_Raises (L, 100), "Element far raises");
   end Test_Min_Max_Element;

   -------------------------------------------------------------------------
   -- Full / Overflow
   -------------------------------------------------------------------------

   procedure Test_Overflow is
      L : List := Empty;
   begin
      Section ("Is_Full / Overflow");
      for I in 1 .. Max_N loop
         Insert (L, I);
      end loop;
      Check (Length (L) = Max_N, "Full length Max_N");
      Check (Is_Full (L), "Is_Full true");
      Check (not Is_Empty (L), "Full not empty");
      Check (Min (L) = 1 and Max (L) = Max_N, "Full min/max");
      Check (Is_Nondecreasing (L), "Full still sorted");
      Check (Insert_Raises_Overflow (L, 0), "Insert when full raises Overflow");
      Check (Length (L) = Max_N, "Length unchanged after Overflow");
      Check (Is_Full (L), "Still full after Overflow");
      --  After deleting one, insert succeeds again
      Delete (L, Max_N);
      Check (not Is_Full (L), "Not full after one delete");
      Insert (L, Max_N + 1);
      Check (Is_Full (L), "Full again after re-insert");
      Check (Max (L) = Max_N + 1, "New max after re-insert");
   end Test_Overflow;

   -------------------------------------------------------------------------
   -- Mixed stress / Clear
   -------------------------------------------------------------------------

   procedure Test_Mixed is
      L : List := Empty;
   begin
      Section ("Mixed stress / Clear");
      Insert (L, 50);
      Insert (L, 10);
      Insert (L, 90);
      Insert (L, 30);
      Insert (L, 70);
      Insert (L, 20);
      Insert (L, 80);
      Insert (L, 40);
      Insert (L, 60);
      Check (Length (L) = 9, "Mixed length 9");
      Check (Is_Nondecreasing (L), "Mixed sorted");
      for I in 1 .. 9 loop
         Check (Element (L, I) = 10 * I, "Mixed Element" & Integer'Image (I));
      end loop;
      Clear (L);
      Check (Is_Empty (L), "Clear empties");
      Check (Length (L) = 0, "Clear length 0");
      Insert (L, 1);
      Check (Length (L) = 1 and Element (L, 1) = 1, "Reuse after Clear");
      Check (Contains (L, 1) and not Contains (L, 50), "Contains after Clear reuse");
   end Test_Mixed;

   -------------------------------------------------------------------------
   -- Many deterministic inserts
   -------------------------------------------------------------------------

   procedure Test_Many is
      L : List := Empty;
      X : Integer := 17;
   begin
      Section ("Many deterministic inserts");
      for K in 1 .. 200 loop
         X := Integer ((Long_Integer (X) * 1103515245 + 12345)
                       mod 1000);
         Insert (L, X);
      end loop;
      Check (Length (L) = 200, "Many length 200");
      Check (Is_Nondecreasing (L), "Many still sorted");
      Check (Min (L) <= Max (L), "Many min <= max");
      declare
         Target : constant Integer := Element (L, 100);
      begin
         Check (Contains (L, Target), "Many mid element present");
         Delete (L, Target);
         Check (Length (L) = 199, "Many after one delete");
         Check (Is_Nondecreasing (L), "Many sorted after delete");
      end;
   end Test_Many;

begin
   Put_Line ("Sorted_List ADT tests (Ada 2023)");
   Put_Line ("Max_N =" & Positive'Image (Max_N));

   Test_Empty_Basics;
   Test_Insert_Order;
   Test_Duplicates;
   Test_Search;
   Test_Delete;
   Test_Min_Max_Element;
   Test_Overflow;
   Test_Mixed;
   Test_Many;

   New_Line;
   Put_Line ("Results:" & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
