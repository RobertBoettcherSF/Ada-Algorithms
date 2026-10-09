pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Independent model: second chance as a
--  FIFO queue of resident pages with a reference bit each. A hit sets the
--  page's bit. A fault with a free frame appends the page (bit set); with
--  no free frame, the queue head is inspected: a set bit is cleared and the
--  page moves to the tail, a clear bit evicts it, and the new page is
--  appended (bit set). After every access the resident pages and their
--  bits must match the frames (as sets), and the fault count must match.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Clock_Page_Replacement; use Clock_Page_Replacement;

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
      Name : constant String := "Ada-SPARK-Clock-Page-Replacement";
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

   type Entry_T is record
      P   : Natural;
      Bit : Boolean;
   end record;
   Q      : array (1 .. Capacity) of Entry_T;
   Len    : Natural;
   Faults : Natural;

   procedure Model_Access (P : Natural) is
      Head : Entry_T;
   begin
      for I in 1 .. Len loop
         if Q (I).P = P then
            Q (I).Bit := True;
            return;
         end if;
      end loop;
      Faults := Faults + 1;
      if Len < Capacity then
         Len := Len + 1;
         Q (Len) := (P, True);
         return;
      end if;
      loop
         Head := Q (1);
         Q (1 .. Capacity - 1) := Q (2 .. Capacity);
         if Head.Bit then
            Q (Capacity) := (Head.P, False);
         else
            Q (Capacity) := (P, True);
            return;
         end if;
      end loop;
   end Model_Access;

   function Matches (S : State) return Boolean is
      Found : Boolean;
      Count : Natural := 0;
   begin
      for F in Frame_Id loop
         if S.Slots (F).Used then
            Count := Count + 1;
         end if;
      end loop;
      if Count /= Len then
         return False;
      end if;
      for I in 1 .. Len loop
         Found := False;
         for F in Frame_Id loop
            if S.Slots (F).Used and then S.Slots (F).Value = Q (I).P
              and then S.Slots (F).Referenced = Q (I).Bit
            then
               Found := True;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Matches;

   S : State;
   P : Natural;
begin
   for Run in 1 .. 4_000 loop
      S := (others => <>);
      Len := 0;
      Faults := 0;
      declare
         Pages : constant Positive :=
           (case Run mod 4 is when 0 => 5, when 1 => 6, when 2 => 9, when others => 101);
      begin
         for Step in 1 .. 60 loop
            P := (if Next mod 5 = 0 and then Len > 0 then Q (Next mod Len + 1).P
                  else Next mod Pages);
            Access_Page (S, P);
            Model_Access (P);
            Report (Fault_Count (S) = Faults, "fault count");
            Report (Matches (S), "resident pages and reference bits");
         end loop;
      end;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
