pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based: seeded random sequences
--  of Enqueue / Dequeue / Front are applied both to the queue and to a
--  shift model (Model (1 .. N), front first: Enqueue appends at N + 1,
--  Dequeue moves every item up one place). The model shares no code or
--  layout with the package's ring buffer. A call whose precondition fails
--  (Enqueue on a full queue, Dequeue / Front on an empty one) must raise
--  Assertion_Error (tests run with -gnata) and change nothing. After
--  every step Length and every Element are compared with the model, and
--  Front with Model (1).
with Ada.Text_IO;
with Ada.Assertions;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Design_Circular_Queue; use Design_Circular_Queue;

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
      Name : constant String := "Ada-SPARK-Design-Circular-Queue";
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
   function Next (N : Positive) return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Next;

   Model : array (1 .. 16) of Integer := [others => 0];
   N     : Natural := 0;
   Q     : Queue;

   procedure Compare (Label : String) is
      Ok : Boolean := Length (Q) = N;
   begin
      if Ok then
         for I in 1 .. N loop
            Ok := Ok and then Element (Q, I) = Model (I);
         end loop;
         if N > 0 then
            Ok := Ok and then Front (Q) = Model (1);
         end if;
      end if;
      Report (Ok, Label);
   end Compare;

   Refused : Natural := 0;
   Wraps   : Natural := 0;
   Served  : Natural := 0;
begin
   for Run in 1 .. 2_000 loop
      Q := Empty;
      N := 0;
      Served := 0;
      Compare ("empty");
      for Step in 1 .. 40 loop
         declare
            --  Enqueue more often in some runs, Dequeue in others, so that
            --  both the full and the empty refusals and many wraps occur.
            Bias    : constant Natural := Run mod 3;
            R       : constant Natural := Next (10);
            Op      : constant Natural :=
              (if R < 3 + 2 * Bias then 0 elsif R < 9 then 1 else 2);
            V       : constant Value :=
              (if Next (4) = 0 then Value'First + Next (3) * 100
               else Value'First + Next (201));
            Allowed : Boolean;
            Raised  : Boolean := False;
            Got     : Integer := 0;
         begin
            case Op is
               when 0 =>
                  Allowed := N < Capacity;
                  begin
                     Enqueue (Q, V);
                  exception
                     when Ada.Assertions.Assertion_Error => Raised := True;
                  end;
                  if Allowed then
                     N := N + 1;
                     Model (N) := V;
                  end if;
               when 1 =>
                  Allowed := N > 0;
                  begin
                     Dequeue (Q);
                  exception
                     when Ada.Assertions.Assertion_Error => Raised := True;
                  end;
                  if Allowed then
                     for I in 1 .. N - 1 loop
                        Model (I) := Model (I + 1);
                     end loop;
                     N := N - 1;
                     Served := Served + 1;
                     if Served mod Capacity = 0 then
                        Wraps := Wraps + 1;
                     end if;
                  end if;
               when others =>
                  Allowed := N > 0;
                  begin
                     Got := Front (Q);
                  exception
                     when Ada.Assertions.Assertion_Error => Raised := True;
                  end;
                  if Allowed then
                     Report (Got = Model (1), "Front = oldest item");
                  end if;
            end case;
            if Raised then
               Refused := Refused + 1;
            end if;
            Report (Raised = not Allowed,
                    "refused exactly when not allowed, op" & Op'Image);
            Compare ("after op" & Op'Image);
         end;
      end loop;
   end loop;
   Report (Refused > 0, "some calls were refused");
   Report (Wraps > 0, "the head wrapped around the ring");
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures (" & Refused'Image & " refused calls," & Wraps'Image
      & " full turns of the head)");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
