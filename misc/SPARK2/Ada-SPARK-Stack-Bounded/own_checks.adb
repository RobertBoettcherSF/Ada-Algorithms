pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based: seeded random sequences
--  of Initialize / Push / Pop / Top are applied both to the stack and to a
--  plain array model (Model (1 .. N), last pushed value at Model (N)).
--  After every step Depth, Is_Empty, Is_Full and Top are compared with the
--  model; every Pop must return the model's last value. Operations are only
--  issued when their precondition holds.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Stack_Bounded; use Stack_Bounded;

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
      Name : constant String := "Ada-SPARK-Stack-Bounded";
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

   --  Values drawn from small numbers, both extremes and arbitrary ones.
   function Any_Value return Integer is
      R : constant Natural := Next mod 8;
   begin
      case R is
         when 0      => return Integer'First;
         when 1      => return Integer'Last;
         when 2      => return 0;
         when 3 | 4  => return Next mod 7 - 3;
         when others => return Next - 1_073_741_823;
      end case;
   end Any_Value;

   Model : array (1 .. Capacity) of Integer := [others => 0];
   N     : Natural := 0;
   S     : Stack;
   V     : Integer;

   procedure Compare (Label : String) is
   begin
      Report (Depth (S) = N, Label & ": Depth");
      Report (Is_Empty (S) = (N = 0), Label & ": Is_Empty");
      Report (Is_Full (S) = (N = Capacity), Label & ": Is_Full");
      if N > 0 then
         Report (Top (S) = Model (N), Label & ": Top");
      end if;
   end Compare;
begin
   for Run in 1 .. 200 loop
      Initialize (S);
      N := 0;
      Compare ("after Initialize");
      for Step in 1 .. 200 loop
         case Next mod 10 is
            when 0 .. 4 =>
               if N < Capacity then
                  V := Any_Value;
                  Push (S, V);
                  N := N + 1;
                  Model (N) := V;
                  Compare ("Push");
               end if;
            when 5 .. 8 =>
               if N > 0 then
                  Pop (S, V);
                  Report (V = Model (N), "Pop returns the last pushed value");
                  N := N - 1;
                  Compare ("Pop");
               end if;
            when others =>
               if Next mod 20 = 0 then
                  Initialize (S);
                  N := 0;
                  Compare ("re-Initialize");
               end if;
         end case;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
