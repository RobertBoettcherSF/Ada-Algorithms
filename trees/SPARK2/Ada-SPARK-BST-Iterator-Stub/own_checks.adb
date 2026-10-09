pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Assertions;
with BST_Iterator_Stub; use BST_Iterator_Stub;
--  Own checks (H117): a BST iterator returns the inserted values in
--  ascending order (an in-order walk; equal values all appear). Reference:
--  the same values sorted by insertion sort. Every insertion order of
--  1 .. 7 (with and without duplicates), and 2,000 random sequences of
--  lengths 0 .. 1000 (seed 20261009, Park-Miller generator).
procedure Own_Checks is
   Max_Len : constant := 1_000;
   Fails   : Natural := 0;
   Ops     : Natural := 0;
   Seed    : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Ops := Ops + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   type Int_Array is array (1 .. Max_Len) of Integer;

   procedure Run (Vals : Int_Array; Len : Natural; Tag : String) is
      Want : Int_Array := Vals;
      X    : Integer;
      J    : Natural;
   begin
      for I in 2 .. Len loop
         X := Want (I);
         J := I - 1;
         while J >= 1 and then Want (J) > X loop
            Want (J + 1) := Want (J);
            J := J - 1;
         end loop;
         Want (J + 1) := X;
      end loop;
      declare
         T  : Tree := Empty;
         It : Iterator;
         V  : Value;
      begin
         for I in 1 .. Len loop
            Insert (T, Vals (I));
         end loop;
         Check (Size (T) = Len, "size" & Tag);
         It := Create (T);
         for K in 1 .. Len loop
            if not Has_Next (It) then
               Check (False, "ended early" & Tag);
               return;
            end if;
            Next (It, V);
            if V /= Want (K) then
               Check (False, "value" & K'Image & Tag);
               return;
            end if;
         end loop;
         Check (not Has_Next (It), "extra value" & Tag);
      end;
   exception
      when Constraint_Error | Ada.Assertions.Assertion_Error =>
         Check (False, "rejected" & Tag);
   end Run;

   --  every permutation of 1 .. N (Dup: value I div 2, so duplicates)
   procedure Perms (N : Positive; Dup : Boolean) is
      P    : Int_Array := [others => 0];
      Used : array (1 .. 7) of Boolean := [others => False];
      procedure Place (K : Positive) is
      begin
         if K > N then
            declare
               V : Int_Array := [others => 0];
            begin
               for I in 1 .. N loop
                  V (I) := (if Dup then P (I) / 2 else P (I));
               end loop;
               Run (V, N, " perm N =" & N'Image);
            end;
            return;
         end if;
         for X in 1 .. N loop
            if not Used (X) then
               Used (X) := True;
               P (K) := X;
               Place (K + 1);
               Used (X) := False;
            end if;
         end loop;
      end Place;
   begin
      Place (1);
   end Perms;
begin
   Run ([others => 0], 0, " empty");
   for N in 1 .. 7 loop
      Perms (N, False);
      Perms (N, True);
   end loop;
   for T in 1 .. 2_000 loop
      declare
         Len : constant Natural := Rand (Max_Len + 1);
         V   : Int_Array := [others => 0];
         R   : constant Positive := (if T mod 2 = 0 then 201 else 11);
      begin
         for I in 1 .. Len loop
            V (I) := Rand (R) - (R - 1) / 2;
         end loop;
         Run (V, Len, " random len" & Len'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS BST_Iterator own checks:" & Ops'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Ops'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
