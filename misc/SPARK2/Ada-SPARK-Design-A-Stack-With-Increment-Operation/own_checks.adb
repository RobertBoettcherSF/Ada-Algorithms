pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based: seeded random sequences
--  of Push / Pop / Increment are applied both to the stack and to a plain
--  array model (Model (1 .. N), bottom first). Increment (Bottom, By) adds
--  By to Model (1 .. min (Bottom, N)); when that would take a value above
--  1000 the call must raise Assertion_Error (precondition, tests run with
--  -gnata) and the model is left unchanged. Size is compared after every
--  step and every Pop must return the model's top value. Values are drawn
--  near 0 and near 1000 so that both outcomes of Fits occur.
with Ada.Text_IO;
with Ada.Assertions;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Design_A_Stack_With_Increment_Operation;
use Design_A_Stack_With_Increment_Operation;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Design-A-Stack-With-Increment-Operation";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   Model : array (1 .. Capacity) of Integer := [others => 0];
   N     : Natural := 0;
   S     : Stack;
   V     : Value;
   Refused, Want_Ok : Boolean;
   Increments_Done, Increments_Refused : Natural := 0;
begin
   for Run in 1 .. 400 loop
      S := Empty;
      N := 0;
      for Step in 1 .. 100 loop
         case Next mod 7 is
            when 0 | 1 | 2 =>
               if N < Capacity then
                  V := (if Next mod 2 = 0 then Next mod 21 else 980 + Next mod 21);
                  Push (S, V);
                  N := N + 1;
                  Model (N) := V;
               end if;
            when 3 | 4 =>
               if N > 0 then
                  Pop (S, V);
                  Report (V = Model (N), "Pop returns the top value");
                  N := N - 1;
               end if;
            when others =>
               declare
                  Bottom : constant Index := Next mod (Capacity + 1);
                  By     : constant Amount := Next mod 11;
                  Limit  : constant Natural := Natural'Min (Bottom, N);
               begin
                  Want_Ok := (for all I in 1 .. Limit => Model (I) + By <= 1000);
                  Refused := False;
                  begin
                     Increment (S, Bottom, By);
                  exception
                     when Ada.Assertions.Assertion_Error => Refused := True;
                  end;
                  Report (Refused = not Want_Ok, "Increment refused exactly when a value would exceed 1000");
                  if Want_Ok then
                     Increments_Done := Increments_Done + 1;
                     for I in 1 .. Limit loop
                        Model (I) := Model (I) + By;
                     end loop;
                  else
                     Increments_Refused := Increments_Refused + 1;
                  end if;
               end;
         end case;
         Report (Size (S) = N, "Size");
      end loop;
      --  Drain: every remaining value in top-to-bottom order.
      while N > 0 loop
         Pop (S, V);
         Report (V = Model (N), "drain");
         N := N - 1;
      end loop;
   end loop;
   Report (Increments_Done > 1_000 and then Increments_Refused > 100,
           "both outcomes of Fits exercised");
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
