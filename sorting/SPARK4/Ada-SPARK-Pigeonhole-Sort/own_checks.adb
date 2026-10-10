pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Pigeonhole_Sort; use Pigeonhole_Sort;
--  Own checks (contract_scan: sorted_post_no_permutation): Sort's Post
--  must say the result is a permutation of the input. Is_Perm is checked
--  against an independent multiset comparison (sort both copies by
--  insertion, compare slot by slot) on every pair of arrays of length
--  0 .. 3 over -1 .. 1; Sort is checked to return Is_Perm of its input and
--  the insertion-sorted copy on 2,000 random arrays (seed 20261010) with
--  keys spread up to the 256-hole range, including negative and extreme
--  Integer values.
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261010;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   function Ins (A : Element_Array) return Element_Array is
      B : Element_Array := A;
      T : Integer;
      J : Natural;
   begin
      for I in B'First + 1 .. B'Last loop
         T := B (I);
         J := I;
         while J > B'First and then B (J - 1) > T loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end Ins;

   function Same_Multiset (A, B : Element_Array) return Boolean is
     (A'Length = B'Length and then Ins (A) = Ins (B));
begin
   for LA in 0 .. 3 loop
      for CA in 0 .. 3 ** LA - 1 loop
         for CB in 0 .. 3 ** LA - 1 loop
            declare
               A, B : Element_Array (1 .. LA);
               X : Natural := CA;
               Y : Natural := CB;
            begin
               for I in 1 .. LA loop
                  A (I) := X mod 3 - 1;
                  B (I) := Y mod 3 - 1;
                  X := X / 3;
                  Y := Y / 3;
               end loop;
               Check (Is_Perm (A, B) = Same_Multiset (A, B), "Is_Perm vs multiset, length" & LA'Image);
            end;
         end loop;
      end loop;
   end loop;
   for T in 1 .. 2_000 loop
      declare
         L    : constant Natural := Rand (Max_N + 1);
         Span : constant Positive := 1 + Rand (Max_Range);
         Low  : constant Integer :=
           (case T mod 4 is
              when 0 => Integer'First,
              when 1 => Integer'Last - Span + 1,
              when 2 => -Rand (1_000),
              when others => Rand (1_000));
         A : Element_Array (1 .. L);
         O : Element_Array (1 .. L);
      begin
         for I in A'Range loop
            A (I) := Low + Rand (Span);
         end loop;
         O := A;
         Sort (A);
         Check (Is_Perm (A, O), "Sort result Is_Perm of input" & T'Image);
         Check (A = Ins (O), "Sort = insertion sort" & T'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Pigeonhole_Sort own checks:" & Cases'Image & " checks (seed 20261010)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
