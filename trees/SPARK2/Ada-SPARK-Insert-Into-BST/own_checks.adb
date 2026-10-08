--  Own tests for Insert_Into_BST (see tests/SOURCES.txt).
--  After inserting distinct values, Contains must agree with an own set and Size with its count.
pragma Ada_2022;
with Ada.Text_IO;
with Insert_Into_BST; use Insert_Into_BST;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;
   pragma Warnings (Off, Next);

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);
   Have : array (Value) of Boolean;
   X : Tree;
   N : Natural;
   V : Value;
   Ok : Boolean;
begin
   for Iter in 1 .. 2_000 loop
      Have := [others => False];
      X := Empty;
      N := Next (0, Capacity);
      for I in 1 .. N loop
         loop
            V := Next (Value'First, Value'Last);
            exit when not Have (V);
         end loop;
         Insert (X, V);
         Have (V) := True;
      end loop;
      Ok := Size (X) = N;
      for W in Value loop
         if Contains (X, W) /= Have (W) then Ok := False; end if;
      end loop;
      Report (Ok, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own set-membership reference)");
end Own_Checks;
