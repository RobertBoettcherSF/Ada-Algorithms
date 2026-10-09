pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based: seeded random sequences
--  of Initialize / Push_Front / Push_Back / Pop_Front / Pop_Back are
--  applied both to the deque and to a plain array model kept in order
--  front .. back (Model (1 .. N), shifted on every front operation, no
--  ring buffer). After every step Length, Is_Empty and Is_Full are
--  compared with the model, and every Pop must return the model's front /
--  back value. Operations are only issued when their precondition holds.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Deque_Bounded; use Deque_Bounded;

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
      Name : constant String := "Ada-SPARK-Deque-Bounded";
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

   function Any_Value return Integer is
     (case Next mod 6 is
        when 0 => Integer'First, when 1 => Integer'Last, when 2 => 0,
        when 3 => Next mod 9 - 4, when others => Next - 1_073_741_823);

   Model : array (1 .. Capacity) of Integer := [others => 0];
   N     : Natural := 0;
   D     : Deque;
   V, W  : Integer;
begin
   for Run in 1 .. 300 loop
      Initialize (D);
      N := 0;
      for Step in 1 .. 200 loop
         case Next mod 9 is
            when 0 | 1 =>
               if N < Capacity then
                  W := Any_Value;
                  Push_Front (D, W);
                  Model (2 .. N + 1) := Model (1 .. N);
                  Model (1) := W;
                  N := N + 1;
               end if;
            when 2 | 3 =>
               if N < Capacity then
                  W := Any_Value;
                  Push_Back (D, W);
                  N := N + 1;
                  Model (N) := W;
               end if;
            when 4 | 5 =>
               if N > 0 then
                  Pop_Front (D, V);
                  Report (V = Model (1), "Pop_Front returns the front value");
                  Model (1 .. N - 1) := Model (2 .. N);
                  N := N - 1;
               end if;
            when 6 | 7 =>
               if N > 0 then
                  Pop_Back (D, V);
                  Report (V = Model (N), "Pop_Back returns the back value");
                  N := N - 1;
               end if;
            when others =>
               if Next mod 15 = 0 then
                  Initialize (D);
                  N := 0;
               end if;
         end case;
         Report (Length (D) = N, "Length");
         Report (Is_Empty (D) = (N = 0), "Is_Empty");
         Report (Is_Full (D) = (N = Capacity), "Is_Full");
      end loop;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
