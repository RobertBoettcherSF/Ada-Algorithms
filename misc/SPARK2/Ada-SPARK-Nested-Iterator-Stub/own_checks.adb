pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Assertions;
with Nested_Iterator_Stub; use Nested_Iterator_Stub;
--  Own checks (H112): a nested list (integers and nested lists, built with
--  Add / Open_List / Close_List) must be returned flattened, left to right, with empty
--  lists skipped (Has_Next false when only empty lists remain). Reference:
--  the integers in the order they were added. Every well-formed sequence of
--  up to 9 Open_List / Close_List / Add steps, and 2,000 random structures of up to
--  1000 entries (seed 20261009, Park-Miller generator).
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

   type Step is (S_Add, S_Open, S_Close);
   type Step_Array is array (1 .. Max_Len) of Step;
   type Int_Array is array (1 .. Max_Len) of Integer;

   --  Build from steps (Close only when a list is open; every open list is
   --  closed at the end), then compare the iterator with the added values.
   procedure Run (S : Step_Array; Len : Natural; Tag : String) is
      Want : Int_Array := [others => 0];
      NW   : Natural := 0;
      N    : Nested_Data := Empty;
      It   : Iterator;
      V    : Value;
   begin
      for I in 1 .. Len loop
         case S (I) is
            when S_Add =>
               NW := NW + 1;
               Want (NW) := Rand (201) - 100;
               Add (N, Want (NW));
            when S_Open => Open_List (N);
            when S_Close => Close_List (N);
         end case;
      end loop;
      It := Create (N);
      for K in 1 .. NW loop
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
   exception
      when Constraint_Error | Ada.Assertions.Assertion_Error =>
         Check (False, "rejected" & Tag);
   end Run;

   --  all well-formed step sequences of length L (depth never negative,
   --  zero at the end)
   procedure All_Of (L : Natural) is
      S : Step_Array := [others => S_Add];
      procedure Gen (K : Positive; Depth : Natural) is
      begin
         if K > L then
            if Depth = 0 then
               Run (S, L, " exhaustive len" & L'Image);
            end if;
            return;
         end if;
         if Depth > L - K + 1 then
            return;
         end if;
         S (K) := S_Add;
         Gen (K + 1, Depth);
         S (K) := S_Open;
         Gen (K + 1, Depth + 1);
         if Depth > 0 then
            S (K) := S_Close;
            Gen (K + 1, Depth - 1);
         end if;
      end Gen;
   begin
      Gen (1, 0);
   end All_Of;
begin
   for L in 0 .. 9 loop
      All_Of (L);
   end loop;
   for T in 1 .. 2_000 loop
      declare
         Len   : constant Natural := Rand (Max_Len + 1);
         S     : Step_Array := [others => S_Add];
         Depth : Natural := 0;
         K     : Natural := 0;
      begin
         --  random steps, leaving room to close every open list
         while K + Depth < Len loop
            K := K + 1;
            case Rand (5) is
               when 0 | 1 => S (K) := S_Add;
               when 2 | 3 =>
                  if K + Depth + 2 <= Len then
                     S (K) := S_Open;
                     Depth := Depth + 1;
                  else
                     S (K) := S_Add;
                  end if;
               when others =>
                  if Depth > 0 then
                     S (K) := S_Close;
                     Depth := Depth - 1;
                  else
                     S (K) := S_Add;
                  end if;
            end case;
         end loop;
         while Depth > 0 loop
            K := K + 1;
            S (K) := S_Close;
            Depth := Depth - 1;
         end loop;
         Run (S, K, " random len" & K'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Nested_Iterator own checks:" & Ops'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Ops'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
