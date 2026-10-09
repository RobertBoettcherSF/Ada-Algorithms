pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based.
--  Arena: a plain counter model; Allocate_Node must hand out Used + 1 and
--  Release must go back to the level of the mark (marks kept on a stack and
--  released LIFO, sometimes skipping several marks at once).
--  Index_Tree: a membership table over -1000 .. 1000; Contains must agree
--  with it for every key tried, Insert answers Ok exactly for new keys and
--  uses one arena slot per new key. Sequences include ascending and
--  descending runs (chains of depth up to 16) and random keys from narrow
--  and wide ranges.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Bump_Arena; use Bump_Arena;
with Index_Tree; use Index_Tree;

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
      Name : constant String := "Ada-SPARK-Bump-Arena";
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

   procedure Arena_Model is
      A      : Arena := Create;
      N      : Natural := 0;
      Marks  : array (1 .. 64) of Mark;
      Levels : array (1 .. 64) of Natural;
      Top    : Natural := 0;
      Id     : Node_Id;
   begin
      for Step in 1 .. 50_000 loop
         case Next mod 8 is
            when 0 .. 3 =>
               if N < Capacity then
                  Allocate_Node (A, Id);
                  N := N + 1;
                  Report (Id = N, "Allocate_Node returns Used + 1");
               end if;
            when 4 | 5 =>
               if Top < Marks'Last then
                  Top := Top + 1;
                  Marks (Top) := Get_Mark (A);
                  Levels (Top) := N;
                  Report (Mark_Level (Marks (Top)) = N, "Mark_Level = Used");
               end if;
            when 6 =>
               if Top > 0 then
                  --  Release to the newest mark or one up to 3 marks older.
                  Top := Top - Natural'Min (Top - 1, Next mod 4);
                  Release (A, Marks (Top));
                  N := Levels (Top);
                  Top := Top - 1;
               end if;
            when others =>
               if Next mod 50 = 0 then
                  Reset (A);
                  N := 0;
                  Top := 0;
               end if;
         end case;
         Report (Used (A) = N and then Remaining (A) = Capacity - N,
                 "Used / Remaining follow the model");
      end loop;
   end Arena_Model;

   procedure Tree_Model is
      Present : array (Key) of Boolean;
      Count   : Natural;
      T       : Tree;
      Ok      : Boolean;
      K       : Key;
      Probe   : Key;
   begin
      for Run in 1 .. 3_000 loop
         Present := [others => False];
         Count := 0;
         Clear (T);
         declare
            Mode  : constant Natural := Run mod 5;
            Base  : constant Integer := Next mod 1_000 - 500;
            Width : constant Positive := (if Run mod 2 = 0 then 24 else 2001);
         begin
            for Step in 1 .. 24 loop
               K := (case Mode is
                       when 0 => Integer'Max (Key'First, Integer'Min (Key'Last, Base + Step)),
                       when 1 => Integer'Max (Key'First, Integer'Min (Key'Last, Base - Step)),
                       when others => Next mod Width - (if Width = 2001 then 1_000 else 12));
               if Count < Capacity or else Present (K) then
                  Insert (T, K, Ok);
                  Report (Ok = not Present (K), "Insert Ok iff key is new");
                  if Ok then
                     Present (K) := True;
                     Count := Count + 1;
                  end if;
                  Report (Used (Arena_Of (T)) = Count
                          and then Remaining_Slots (T) = Capacity - Count,
                          "one arena slot per stored key");
                  Report ((Root_Of (T) = Null_Node) = (Count = 0),
                          "root set once a key is stored");
               end if;
               --  Probe stored keys, neighbours and random keys.
               for J in 1 .. 4 loop
                  Probe := (case J is
                              when 1 => K,
                              when 2 => Integer'Max (Key'First, K - 1),
                              when 3 => Integer'Min (Key'Last, K + 1),
                              when others => Next mod 2001 - 1_000);
                  Report (Contains (T, Probe) = Present (Probe),
                          "Contains agrees with the model");
               end loop;
            end loop;
            for P in Key loop
               if Present (P) then
                  Report (Contains (T, P), "every stored key is found");
               end if;
            end loop;
         end;
      end loop;
   end Tree_Model;
begin
   Arena_Model;
   Tree_Model;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
