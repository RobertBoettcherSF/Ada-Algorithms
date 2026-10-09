--  tests_reference.adb
--  Lookup against a deliberately simple longest-prefix-match reference
--  (try lengths 32 down to 0, first table entry of that length that
--  matches wins) on 3,000 seeded random routing tables (seed 20261009);
--  IPv4_To_String / String_To_IPv4 against direct dotted-quad formatting.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Interfaces; use Interfaces;
with Lulea_Algorithm; use Lulea_Algorithm;

procedure Tests_Reference is
   Fails : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 20 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   State : Unsigned_64 := 20261009;
   function Next return Unsigned_32 is
   begin
      State := State * 6364136223846793005 + 1442695040888963407;
      return Unsigned_32 (Shift_Right (State, 32));
   end Next;
   function Next (M : Positive) return Natural is (Natural (Next mod Unsigned_32 (M)));

   function Prefix_Matches (P : Prefix; A : IPv4_Address) return Boolean is
     (P.Length = 0
      or else Shift_Right (Unsigned_32 (P.Address), 32 - Natural (P.Length))
              = Shift_Right (Unsigned_32 (A), 32 - Natural (P.Length)));

   function Dotted (A : IPv4_Address) return String is
      function Img (N : Unsigned_32) return String is
         S : constant String := N'Image;
      begin
         return S (S'First + 1 .. S'Last);
      end Img;
      U : constant Unsigned_32 := Unsigned_32 (A);
   begin
      return Img (Shift_Right (U, 24)) & "." & Img (Shift_Right (U, 16) and 255) & "."
        & Img (Shift_Right (U, 8) and 255) & "." & Img (U and 255);
   end Dotted;
begin
   Check (IPv4_To_String (0) = "0.0.0.0", "IPv4_To_String (0) = '" & IPv4_To_String (0) & "'");
   for K in 1 .. 5_000 loop
      declare
         A : constant IPv4_Address :=
           IPv4_Address (if K mod 4 = 0 then Next and 16#FF00FF00# else Next);
      begin
         Check (IPv4_To_String (A) = Dotted (A), "format " & Dotted (A));
         Check (String_To_IPv4 (Dotted (A)) = A, "parse " & Dotted (A));
      end;
   end loop;

   for T in 1 .. 3_000 loop
      declare
         N     : constant Positive := 1 + Next (40);
         Base  : constant Unsigned_32 := Next;
         Table : Routing_Table (1 .. N);
      begin
         for I in Table'Range loop
            declare
               L : constant Natural := (case Next (4) is
                                          when 0 => Next (33),
                                          when 1 => 16 + Next (9),
                                          when others => 8 * Next (5));
               --  addresses near Base so prefixes nest and overlap
               A : constant Unsigned_32 := Base xor (Next and Shift_Right (16#FFFF_FFFF#, Next (33) mod 32 + 0));
            begin
               Table (I) := (Pfx => (IPv4_Address (A), Prefix_Length (L)),
                             Info => (Next_Hop => IPv4_Address (I), If_Index => I, Metric => L));
            end;
         end loop;
         declare
            Trie : constant Lulea_Trie := Build_Lulea_Trie (Table);
         begin
            for Q in 1 .. 30 loop
               declare
                  A : constant IPv4_Address :=
                    IPv4_Address ((if Q mod 3 = 0 then Next else Base xor (Next and Shift_Right (16#FFFF_FFFF#, Next (32)))));
                  Want  : Integer := 0;   --  table index, 0 = none
               begin
                  Search :
                  for L in reverse Prefix_Length range 0 .. 32 loop
                     for I in Table'Range loop
                        if Table (I).Pfx.Length = L and then Prefix_Matches (Table (I).Pfx, A) then
                           Want := I;
                           exit Search;
                        end if;
                     end loop;
                  end loop Search;
                  begin
                     declare
                        Got : constant Routing_Info := Lookup (Trie, A);
                     begin
                        Check (Want /= 0 and then Got = Table (Want).Info, "lookup " & Dotted (A));
                     end;
                  exception
                     when Lookup_Failure_Error =>
                        Check (Want = 0, "lookup raised with a match " & Dotted (A));
                  end;
               end;
            end loop;
         end;
      end;
   end loop;

   if Fails = 0 then
      Put_Line ("PASS Lulea reference comparison (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests_Reference;
