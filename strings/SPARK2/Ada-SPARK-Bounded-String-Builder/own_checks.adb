pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Model-based: seeded random sequences
--  of Clear / Append / Append_Integer / To_String / Slice are applied both
--  to the builder and to a plain String model; after every step the length,
--  every Element, Equals, To_String and a random Slice are compared with
--  the model. Append_Integer is compared with Integer'Image (Ada runtime).
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Bounded_String_Builder;

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
      Name : constant String := "Ada-SPARK-Bounded-String-Builder";
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

   function Decimal (V : Integer) return String is
      S : constant String := Integer'Image (V);
   begin
      return (if V < 0 then S else S (S'First + 1 .. S'Last));
   end Decimal;

   function Random_Integer return Integer is
      Pick : constant Natural := Next mod 12;
   begin
      case Pick is
         when 0 => return 0;
         when 1 => return Integer'First;
         when 2 => return Integer'Last;
         when 3 => return Integer'First + 1;
         when 4 => return (if Next mod 2 = 0 then 1 else -1) * 10 ** (Next mod 10);
         when 5 => return (if Next mod 2 = 0 then 1 else -1) * (10 ** (Next mod 10) - 1);
         when 6 => return Next mod 10 - 5;
         when 7 => return -(Next mod 1000);
         when others =>
            return Integer (Long_Long_Integer (Next) - 1_073_741_823) * 2 + Next mod 2;
      end case;
   end Random_Integer;

   function Random_Char return Character is
     (Character'Val (32 + Next mod 95));

   generic
      Cap : Positive;
      Steps : Positive;
   procedure Run_Model;

   procedure Run_Model is
      package S is new Bounded_String_Builder (Capacity => Cap);
      B     : S.Builder;
      Model : String (1 .. Cap) := [others => ' '];
      ML    : Natural := 0;
      Ok    : Boolean;
      Label : constant String := "Capacity" & Cap'Image;

      procedure Compare (What : String) is
         Buf  : String (1 .. Cap + 3);
         Last : Natural;
      begin
         Report (S.Length (B) = ML, Label & " " & What & " Length");
         if S.Length (B) /= ML then
            return;
         end if;
         for K in 1 .. ML loop
            Report (S.Element (B, K) = Model (K), Label & " " & What & " Element");
         end loop;
         Report (S.Equals (B, Model (1 .. ML)), Label & " " & What & " Equals");
         if ML > 0 then
            declare
               Other : String := Model (1 .. ML);
               K     : constant Positive := 1 + Next mod ML;
            begin
               Other (K) := (if Other (K) = 'a' then 'b' else 'a');
               Report (not S.Equals (B, Other), Label & " " & What & " Equals (changed char)");
               Report (not S.Equals (B, Model (1 .. ML - 1)), Label & " " & What & " Equals (shorter)");
            end;
         end if;
         if ML < Cap then
            Report (not S.Equals (B, Model (1 .. ML) & 'z'), Label & " " & What & " Equals (longer)");
         end if;
         S.To_String (B, Buf, Last);
         Report (Last = ML and then Buf (1 .. Last) = Model (1 .. ML),
                 Label & " " & What & " To_String");
         declare
            Low  : constant Positive := 1 + Next mod (ML + 1);
            High : constant Natural := Low - 1 + Next mod (ML - Low + 2);
         begin
            S.Slice (B, Low, High, Buf, Last);
            Report (Last = High - Low + 1 and then Buf (1 .. Last) = Model (Low .. High),
                    Label & " " & What & " Slice" & Low'Image & High'Image);
         end;
      end Compare;
   begin
      S.Clear (B);
      Report (S.Max_Capacity = Cap, Label & " Max_Capacity");
      Compare ("Clear");
      for Step in 1 .. Steps loop
         case Next mod 10 is
            when 0 =>
               S.Clear (B);
               ML := 0;
               Compare ("Clear");
            when 1 .. 3 =>
               declare
                  C : constant Character := Random_Char;
               begin
                  S.Append (B, C, Ok);
                  Report (Ok = (ML < Cap), Label & " Append char status");
                  if ML < Cap then
                     ML := ML + 1;
                     Model (ML) := C;
                  end if;
                  Compare ("Append char");
               end;
            when 4 .. 6 =>
               declare
                  N    : constant Integer :=
                    (if Next mod 4 = 0 then Cap - ML + Next mod 3 - 1 else Next mod (Cap + 3));
                  Item : String (1 .. Natural'Max (N, 0));
               begin
                  for C of Item loop
                     C := Random_Char;
                  end loop;
                  S.Append (B, Item, Ok);
                  Report (Ok = (Item'Length <= Cap - ML), Label & " Append string status");
                  if Item'Length <= Cap - ML then
                     Model (ML + 1 .. ML + Item'Length) := Item;
                     ML := ML + Item'Length;
                  end if;
                  Compare ("Append string");
               end;
            when others =>
               declare
                  V    : constant Integer := Random_Integer;
                  Text : constant String := Decimal (V);
               begin
                  S.Append_Integer (B, V, Ok);
                  Report (Ok = (Text'Length <= Cap - ML), Label & " Append_Integer status" & V'Image);
                  if Text'Length <= Cap - ML then
                     Model (ML + 1 .. ML + Text'Length) := Text;
                     ML := ML + Text'Length;
                  end if;
                  Compare ("Append_Integer" & V'Image);
               end;
         end case;
      end loop;
   end Run_Model;

   procedure Run_1 is new Run_Model (Cap => 1, Steps => 3_000);
   procedure Run_11 is new Run_Model (Cap => 11, Steps => 6_000);
   procedure Run_16 is new Run_Model (Cap => 16, Steps => 6_000);
   procedure Run_64 is new Run_Model (Cap => 64, Steps => 6_000);
begin
   Run_1;
   Run_11;
   Run_16;
   Run_64;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
