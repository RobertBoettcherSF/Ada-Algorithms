pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Tim_Sort_Stub; use Tim_Sort_Stub;
procedure Tests is
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; Name : String) is
   begin
      if Ok then
         Put_Line ("PASS " & Name);
      else
         Put_Line ("FAIL " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

   function Is_Sorted (A : Value_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1));

   function Count (A : Value_Array; X : Value) return Natural is
      N : Natural := 0;
   begin
      for Y of A loop
         if Y = X then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count;

   --  Same multiset: every value occurs equally often in both arrays.
   function Same_Values (A, B : Value_Array) return Boolean is
     (A'Length = B'Length
      and then (for all X of A => Count (A, X) = Count (B, X)));

   procedure Case_Of (Input : Value_Array; Name : String) is
      Result : constant Value_Array := Sort (Input);
   begin
      Check (Result'First = Input'First and then Result'Last = Input'Last
             and then Is_Sorted (Result) and then Same_Values (Input, Result),
             Name);
   end Case_Of;

   Old_Stub : constant Value_Array :=
     [1 => 4, 2 => 1, 3 => 7, 4 => 3, 5 => 2, 6 => 8, 7 => 5, 8 => 6];
   Empty    : constant Value_Array (1 .. 0) := [others => 0];
   Big      : Value_Array (1 .. 120);
   Seed     : Natural := 12_345;
begin
   Case_Of (Old_Stub, "old 8-element case");
   Check (Sort (Old_Stub) = [1, 2, 3, 4, 5, 6, 7, 8], "old case exact");
   Case_Of (Empty, "empty");
   Case_Of ([1 => 42], "one element");
   Case_Of ([10 => 3, 11 => 3, 12 => -1, 13 => 3], "duplicates, offset index");
   Case_Of ([5, 4, 3, 2, 1, 0, -1, -2, -3, -4], "reverse order");
   Case_Of ([Integer'Last, Integer'First, 0, Integer'Last], "extreme values");
   for K in Big'Range loop
      Seed := (Seed * 1_103 + 12_345) mod 65_536;
      Big (K) := Seed - 32_768;
   end loop;
   Case_Of (Big, "120 pseudo-random values");
   if Failures = 0 then
      Put_Line ("PASS Tim_Sort_Stub");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
