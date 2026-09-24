--  Standalone test suite for Sorted_List (SPARK port).
--  Preconditions / Success replace exceptions; only valid call paths
--  are exercised. Max_N = 64. Sortedness is proved by SPARK; multiset
--  behaviour and Success paths are checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Sorted_List; use Sorted_List;

procedure Tests
  with SPARK_Mode => Off
is

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);
   function Boo (X : Boolean) return Boolean is (X);

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

   procedure Must_Insert (L : in out List; X : Integer; Label : String) is
      Ok : Boolean;
   begin
      Insert (L, X, Ok);
      Check (Boo (Ok), Label & " Success");
   end Must_Insert;

   -------------------------------------------------------------------------
   -- Empty / Length / Clear
   -------------------------------------------------------------------------

   procedure Test_Empty_Basics is
      L : List := Empty;
   begin
      Section ("Empty / Length / Is_Empty / Clear");
      Check (Nat (Length (L)) = 0, "Empty length 0");
      Check (Boo (Is_Empty (L)), "Empty Is_Empty");
      Check (not Is_Full (L), "Empty not Is_Full");
      Check (not Contains (L, 0), "Empty Contains 0 false");
      Check (Nat (Find (L, 42)) = 0, "Empty Find sentinel 0");
      Clear (L);
      Check (Boo (Is_Empty (L)), "Clear keeps empty");
      Check (Nat (Length (L)) = 0, "Clear length 0");
   end Test_Empty_Basics;

   -------------------------------------------------------------------------
   -- Insert keeps order
   -------------------------------------------------------------------------

   procedure Test_Insert_Order is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Insert keeps nondecreasing order");

      Insert (L, 5, Ok);
      Check (Boo (Ok) and then Length (L) = 1, "Insert one length");
      Check (Int (Element (L, 1)) = 5, "Insert one value");
      Check (Int (Min (L)) = 5 and then Int (Max (L)) = 5, "Insert one min=max");

      Insert (L, 3, Ok);
      Check (Boo (Ok), "Insert before ok");
      Check (Int (Element (L, 1)) = 3 and then Int (Element (L, 2)) = 5,
             "Insert before");
      Check (Is_Nondecreasing (L), "Order after insert before");

      Insert (L, 7, Ok);
      Check (Int (Element (L, 3)) = 7, "Insert after");
      Check (Int (Min (L)) = 3 and then Int (Max (L)) = 7, "Min/Max after three");
      Check (Is_Nondecreasing (L), "Order after insert after");

      Insert (L, 4, Ok);
      Check (Int (Element (L, 1)) = 3, "Middle insert front");
      Check (Int (Element (L, 2)) = 4, "Middle insert mid");
      Check (Int (Element (L, 3)) = 5, "Middle insert mid2");
      Check (Int (Element (L, 4)) = 7, "Middle insert back");
      Check (Is_Nondecreasing (L), "Order after middle insert");

      --  Reverse-order fill
      Clear (L);
      for I in reverse 1 .. 10 loop
         Insert (L, I, Ok);
         Check (Boo (Ok), "Reverse fill insert" & Integer'Image (I));
      end loop;
      Check (Nat (Length (L)) = 10, "Reverse fill length 10");
      Check (Is_Nondecreasing (L), "Reverse fill sorted");
      Check (Int (Min (L)) = 1 and then Int (Max (L)) = 10,
             "Reverse fill min/max");
      for I in 1 .. 10 loop
         Check (Int (Element (L, I)) = I,
                "Reverse fill Element" & Integer'Image (I));
      end loop;
   end Test_Insert_Order;

   -------------------------------------------------------------------------
   -- Duplicates (multiset)
   -------------------------------------------------------------------------

   procedure Test_Duplicates is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Duplicates (multiset)");
      Must_Insert (L, 2, "dup a");
      Must_Insert (L, 2, "dup b");
      Must_Insert (L, 2, "dup c");
      Must_Insert (L, 1, "dup d");
      Must_Insert (L, 3, "dup e");
      Check (Nat (Length (L)) = 5, "Dup length 5");
      Check (Is_Nondecreasing (L), "Dup still sorted");
      Check (Int (Element (L, 1)) = 1, "Dup Element 1");
      Check (Int (Element (L, 2)) = 2, "Dup Element 2");
      Check (Int (Element (L, 3)) = 2, "Dup Element 3");
      Check (Int (Element (L, 4)) = 2, "Dup Element 4");
      Check (Int (Element (L, 5)) = 3, "Dup Element 5");
      Check (Contains (L, 2), "Dup Contains 2");
      Check (Nat (Find (L, 2)) = 2, "Dup Find leftmost 2");
      Delete (L, 2, Ok);
      Check (Boo (Ok), "Dup Delete Success");
      Check (Nat (Length (L)) = 4, "Dup Delete one length");
      Check (Nat (Find (L, 2)) = 2, "Dup still has 2 at 2");
      Check (Is_Nondecreasing (L), "Dup after delete sorted");
   end Test_Duplicates;

   -------------------------------------------------------------------------
   -- Search hits / misses
   -------------------------------------------------------------------------

   procedure Test_Search is
      L    : List := Empty;
      Keys : constant Integer_Array := [1, 3, 5, 7, 9];
      Ok   : Boolean;
   begin
      Section ("Contains / Find hits and misses");
      for I in Keys'Range loop
         Insert (L, Keys (I), Ok);
         Check (Boo (Ok), "Search insert" & Integer'Image (Keys (I)));
      end loop;
      Check (Contains (L, 1), "Hit Contains 1");
      Check (Contains (L, 5), "Hit Contains 5");
      Check (Contains (L, 9), "Hit Contains 9");
      Check (Nat (Find (L, 1)) = 1, "Hit Find 1");
      Check (Nat (Find (L, 5)) = 3, "Hit Find 5");
      Check (Nat (Find (L, 9)) = 5, "Hit Find 9");
      Check (not Contains (L, 0), "Miss Contains 0");
      Check (not Contains (L, 2), "Miss Contains 2");
      Check (not Contains (L, 10), "Miss Contains 10");
      Check (Nat (Find (L, 0)) = 0, "Miss Find 0");
      Check (Nat (Find (L, 2)) = 0, "Miss Find 2");
      Check (Nat (Find (L, 10)) = 0, "Miss Find 10");
      Check (Nat (Find (L, 4)) = 0, "Miss Find 4");
      Check (Nat (Find (L, 8)) = 0, "Miss Find 8");
   end Test_Search;

   -------------------------------------------------------------------------
   -- Delete
   -------------------------------------------------------------------------

   procedure Test_Delete is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Delete / Delete_First");
      for I in 1 .. 5 loop
         Insert (L, I, Ok);
         Check (Boo (Ok), "Delete setup insert" & Integer'Image (I));
      end loop;
      Delete (L, 1, Ok);
      Check (Boo (Ok) and then Length (L) = 4 and then Min (L) = 2,
             "Delete front");
      Check (Is_Nondecreasing (L), "Sorted after delete front");
      Delete (L, 5, Ok);
      Check (Boo (Ok) and then Length (L) = 3 and then Max (L) = 4,
             "Delete back");
      Delete_First (L, 3);
      Check (Nat (Length (L)) = 2, "Delete_First middle length");
      Check (Int (Element (L, 1)) = 2 and then Int (Element (L, 2)) = 4,
             "Delete_First middle values");
      Delete (L, 99, Ok);
      Check (not Ok, "Delete absent fails");
      Delete (L, 3, Ok);
      Check (not Ok, "Delete already-gone fails");
      Delete (L, 2, Ok);
      Check (Boo (Ok), "Delete 2 ok");
      Delete (L, 4, Ok);
      Check (Boo (Ok), "Delete 4 ok");
      Check (Boo (Is_Empty (L)), "Delete until empty");
      Delete (L, 0, Ok);
      Check (not Ok, "Delete on empty fails");
   end Test_Delete;

   -------------------------------------------------------------------------
   -- Min / Max / Element
   -------------------------------------------------------------------------

   procedure Test_Min_Max_Element is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Min / Max / Element");
      Insert (L, 10, Ok);
      Insert (L, -5, Ok);
      Insert (L, 0, Ok);
      Insert (L, 100, Ok);
      Insert (L, -5, Ok);
      Check (Int (Min (L)) = -5, "Min is -5");
      Check (Int (Max (L)) = 100, "Max is 100");
      Check (Int (Element (L, 1)) = -5, "Element 1");
      Check (Int (Element (L, 2)) = -5, "Element 2");
      Check (Int (Element (L, 3)) = 0, "Element 3");
      Check (Int (Element (L, 4)) = 10, "Element 4");
      Check (Int (Element (L, 5)) = 100, "Element 5");
      Check (Nat (Length (L)) = 5, "Length 5 after signed inserts");
   end Test_Min_Max_Element;

   -------------------------------------------------------------------------
   -- Full / Success=False when full
   -------------------------------------------------------------------------

   procedure Test_Full is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Is_Full / Insert Success=False");
      for I in 1 .. Max_N loop
         Insert (L, I, Ok);
         if not Ok then
            Check (False, "Fill insert" & Integer'Image (I));
            return;
         end if;
      end loop;
      Check (Nat (Length (L)) = Max_N, "Full length Max_N");
      Check (Boo (Is_Full (L)), "Is_Full true");
      Check (not Is_Empty (L), "Full not empty");
      Check (Int (Min (L)) = 1 and then Int (Max (L)) = Max_N, "Full min/max");
      Check (Is_Nondecreasing (L), "Full still sorted");
      Insert (L, 0, Ok);
      Check (not Ok, "Insert when full Success=False");
      Check (Nat (Length (L)) = Max_N, "Length unchanged after full insert");
      Check (Boo (Is_Full (L)), "Still full after failed insert");
      --  After deleting one, insert succeeds again
      Delete (L, Max_N, Ok);
      Check (Boo (Ok) and then not Is_Full (L), "Not full after one delete");
      Insert (L, Max_N + 1, Ok);
      Check (Boo (Ok) and then Is_Full (L), "Full again after re-insert");
      Check (Int (Max (L)) = Max_N + 1, "New max after re-insert");
   end Test_Full;

   -------------------------------------------------------------------------
   -- Mixed stress / Clear
   -------------------------------------------------------------------------

   procedure Test_Mixed is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Mixed stress / Clear");
      for X of Integer_Array'(50, 10, 90, 30, 70, 20, 80, 40, 60) loop
         Insert (L, X, Ok);
         Check (Boo (Ok), "Mixed insert" & Integer'Image (X));
      end loop;
      Check (Nat (Length (L)) = 9, "Mixed length 9");
      Check (Is_Nondecreasing (L), "Mixed sorted");
      for I in 1 .. 9 loop
         Check (Int (Element (L, I)) = 10 * I,
                "Mixed Element" & Integer'Image (I));
      end loop;
      Clear (L);
      Check (Boo (Is_Empty (L)), "Clear empties");
      Check (Nat (Length (L)) = 0, "Clear length 0");
      Insert (L, 1, Ok);
      Check (Boo (Ok) and then Length (L) = 1 and then Element (L, 1) = 1,
             "Reuse after Clear");
      Check (Contains (L, 1) and then not Contains (L, 50),
             "Contains after Clear reuse");
   end Test_Mixed;

   -------------------------------------------------------------------------
   -- Many deterministic inserts (bounded by Max_N)
   -------------------------------------------------------------------------

   procedure Test_Many is
      L      : List := Empty;
      X      : Integer := 17;
      Ok     : Boolean;
      Target : Integer;
   begin
      Section ("Many deterministic inserts");
      for K in 1 .. Max_N loop
         X := Integer ((Long_Integer (X) * 1103515245 + 12345) mod 1000);
         Insert (L, X, Ok);
         Check (Boo (Ok), "Many insert" & Integer'Image (K));
      end loop;
      Check (Nat (Length (L)) = Max_N, "Many length Max_N");
      Check (Is_Nondecreasing (L), "Many still sorted");
      Check (Int (Min (L)) <= Int (Max (L)), "Many min <= max");
      Target := Element (L, Max_N / 2);
      Check (Contains (L, Target), "Many mid element present");
      Delete (L, Target, Ok);
      Check (Boo (Ok) and then Length (L) = Max_N - 1,
             "Many after one delete");
      Check (Is_Nondecreasing (L), "Many sorted after delete");
   end Test_Many;

   -------------------------------------------------------------------------
   -- Is_Sorted helper
   -------------------------------------------------------------------------

   procedure Test_Is_Sorted is
      L  : List := Empty;
      Ok : Boolean;
   begin
      Section ("Is_Sorted");
      Check (Boo (Is_Sorted (L)), "empty Is_Sorted");
      Insert (L, 3, Ok);
      Insert (L, 1, Ok);
      Insert (L, 2, Ok);
      Check (Boo (Is_Sorted (L)), "after inserts Is_Sorted");
      Delete_First (L, 1);
      Check (Boo (Is_Sorted (L)), "after Delete_First Is_Sorted");
   end Test_Is_Sorted;

begin
   Put_Line ("Sorted_List (SPARK) ADT tests");
   Put_Line ("Max_N =" & Positive'Image (Max_N));

   Test_Empty_Basics;
   Test_Insert_Order;
   Test_Duplicates;
   Test_Search;
   Test_Delete;
   Test_Min_Max_Element;
   Test_Full;
   Test_Mixed;
   Test_Many;
   Test_Is_Sorted;

   New_Line;
   Put_Line ("Results:" & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
