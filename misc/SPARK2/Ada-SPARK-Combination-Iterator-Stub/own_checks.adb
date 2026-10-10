pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Assertions;
with Combination_Iterator_Stub; use Combination_Iterator_Stub;
--  Own checks (H111): for every item count N in 1 .. 20 and every
--  Choose K in 1 .. N, the iterator must return exactly the K-element
--  combinations of the N items in lexicographic order of positions; the
--  expected list is built by an independent recursive enumeration.
--  Item values are random (seed 20261009, Park-Miller generator).
--  Before every Next the public positions Pos (It, 1 .. K) must equal the
--  expected combination and Pivot (It) the rightmost position that can
--  still move right (0 for the last one), from the same enumeration.
procedure Own_Checks is
   Max_N : constant := 20;
   Fails : Natural := 0;
   Ops   : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

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

   type Int_Array is array (1 .. Max_N) of Integer;

   procedure Run (N, K : Positive) is
      Vals : Int_Array := [others => 0];
      Tag  : constant String := " N =" & N'Image & " K =" & K'Image;
   begin
      for I in 1 .. N loop
         Vals (I) := Rand (201) - 100;
      end loop;
      declare
         Items : Value_Array := [others => 0];
      begin
         for I in 1 .. N loop
            Items (I) := Vals (I);
         end loop;
         declare
            It  : Iterator := Create (Items, N, K);
            Cur : Int_Array := [others => 0];
            Ok  : Boolean := True;

            --  Next expected combination: positions Cur (1 .. K), filled
            --  in increasing order from position First.
            procedure Expect (J : Positive; First : Positive) is
               C : Combination;
            begin
               if J > K then
                  if not Has_Next (It) then
                     Check (False, "ended early" & Tag);
                     Ok := False;
                     return;
                  end if;
                  --  Before Next: the iterator's positions are Cur, and Pivot
                  --  is the rightmost J with Cur (J) < N - K + J (0: last).
                  declare
                     Want_Pivot : Natural := 0;
                  begin
                     for L in 1 .. K loop
                        Check (Pos (It, L) = Cur (L), "positions" & Tag);
                        if Cur (L) < N - K + L then
                           Want_Pivot := L;
                        end if;
                     end loop;
                     Check (Pivot (It) = Want_Pivot, "pivot" & Tag);
                  end;
                  Next (It, C);
                  Check (C.Size = K, "size" & Tag);
                  for L in 1 .. K loop
                     if C.Values (L) /= Vals (Cur (L)) then
                        Check (False, "values" & Tag);
                        return;
                     end if;
                  end loop;
                  Check (True, "");
                  return;
               end if;
               for P in First .. N - (K - J) loop
                  exit when not Ok;
                  Cur (J) := P;
                  Expect (J + 1, P + 1);
               end loop;
            end Expect;
         begin
            Expect (1, 1);
            Check (not Has_Next (It), "extra combination" & Tag);
         end;
      end;
   exception
      when Constraint_Error | Ada.Assertions.Assertion_Error =>
         Check (False, "rejected" & Tag);
   end Run;
begin
   for N in 1 .. Max_N loop
      for K in 1 .. N loop
         Run (N, K);
      end loop;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Combination_Iterator own checks:" & Ops'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Ops'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
