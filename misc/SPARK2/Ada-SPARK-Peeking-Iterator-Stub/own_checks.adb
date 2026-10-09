pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Peeking_Iterator_Stub; use Peeking_Iterator_Stub;
--  Own checks (H113): random sequences of Has_Next / Peek / Next / Reset on
--  lists of 0 .. 1000 values, compared with a plain reference cursor over
--  the same values (seed 20261009, Park-Miller generator); plus every
--  length 0 .. 1000 walked to the end.
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

   type Ref_Array is array (1 .. Max_Len) of Integer;

   --  One trace: Len values, Steps random operations.
   procedure Trace (Len : Natural; Steps : Natural; Walk_Only : Boolean) is
      Ref  : Ref_Array := [others => 0];
      Pos  : Natural := 0;   --  reference cursor: values 1 .. Pos consumed
   begin
      for I in 1 .. Len loop
         Ref (I) := Rand (201) - 100;
      end loop;
      declare
         Data : Value_Array := [others => 0];
      begin
         for I in 1 .. Len loop
            Data (I) := Ref (I);
         end loop;
         declare
            It : Iterator := Create (Data, Len);
            V  : Value;
         begin
            if Walk_Only then
               while Pos < Len loop
                  Check (Has_Next (It), "walk Has_Next len" & Len'Image);
                  Next (It, V);
                  Pos := Pos + 1;
                  Check (V = Ref (Pos), "walk Next len" & Len'Image);
               end loop;
               Check (not Has_Next (It), "walk end len" & Len'Image);
               return;
            end if;
            for S in 1 .. Steps loop
               case Rand (4) is
                  when 0 =>
                     Check (Has_Next (It) = (Pos < Len), "Has_Next");
                  when 1 =>
                     if Pos < Len then
                        Check (Peek (It) = Ref (Pos + 1), "Peek");
                     end if;
                  when 2 =>
                     if Pos < Len then
                        Next (It, V);
                        Pos := Pos + 1;
                        Check (V = Ref (Pos), "Next");
                     end if;
                  when others =>
                     if Rand (8) = 0 then
                        Reset (It);
                        Pos := 0;
                     end if;
               end case;
            end loop;
         end;
      end;
   exception
      when Constraint_Error =>
         Check (False, "length" & Len'Image & " rejected");
   end Trace;
begin
   for Len in 0 .. Max_Len loop
      Trace (Len, 0, Walk_Only => True);
   end loop;
   for T in 1 .. 2_000 loop
      Trace (Rand (Max_Len + 1), 3 * Max_Len, Walk_Only => False);
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Peeking_Iterator own checks:" & Ops'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Ops'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
