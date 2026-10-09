pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with UTF_8_Validation; use UTF_8_Validation;
procedure Tests is
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

   --  Reference decoder (RFC 3629 definition, written independently of the
   --  library): read the lead's bit pattern, accumulate the code point from
   --  10xxxxxx continuations, then reject overlong forms, surrogates and
   --  values above 16#10FFFF#.
   function Ref (A : Byte_Array) return Boolean is
      I : Integer := A'First;
   begin
      while I <= A'Last loop
         declare
            B    : constant Natural := A (I);
            N    : Natural;
            CP   : Natural;
            Least : Natural;
         begin
            if B < 16#80# then
               N := 0; CP := B; Least := 0;
            elsif B / 32 = 2#110# then
               N := 1; CP := B mod 32; Least := 16#80#;
            elsif B / 16 = 2#1110# then
               N := 2; CP := B mod 16; Least := 16#800#;
            elsif B / 8 = 2#11110# then
               N := 3; CP := B mod 8; Least := 16#1_0000#;
            else
               return False;
            end if;
            if A'Last - I < N then
               return False;
            end if;
            for K in 1 .. N loop
               if A (I + K) / 64 /= 2#10# then
                  return False;
               end if;
               CP := CP * 64 + A (I + K) mod 64;
            end loop;
            if CP < Least or else CP in 16#D800# .. 16#DFFF# or else CP > 16#10FFFF# then
               return False;
            end if;
            I := I + N + 1;
         end;
      end loop;
      return True;
   end Ref;

   procedure Compare (A : Byte_Array; Name : String := "") is
   begin
      Check (Is_Valid (A) = Ref (A), "compare" & Name);
   end Compare;


   Seed  : constant := 20261009;
   State : Long_Long_Integer := Seed;
   function Next (M : Positive) return Natural is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Natural (State / 65536 mod Long_Long_Integer (M));
   end Next;

   --  Bytes near the boundaries of the UTF-8 tables
   Edge : constant array (Natural range <>) of Byte :=
     [16#00#, 16#41#, 16#7F#, 16#80#, 16#8F#, 16#90#, 16#9F#, 16#A0#, 16#BF#,
      16#C0#, 16#C1#, 16#C2#, 16#DF#, 16#E0#, 16#E1#, 16#EC#, 16#ED#, 16#EE#,
      16#EF#, 16#F0#, 16#F1#, 16#F3#, 16#F4#, 16#F5#, 16#F8#, 16#FE#, 16#FF#];
   Tail : constant array (1 .. 4) of Byte := [16#7F#, 16#80#, 16#BF#, 16#C0#];
   Count : Natural := 0;
begin
   Check (Is_Valid ([1 .. 0 => 0]), "empty");
   Check (Is_Valid ([16#48#, 16#69#]), "ASCII Hi");
   Check (Is_Valid ([16#C3#, 16#A9#]), "U+00E9");
   Check (Is_Valid ([16#E2#, 16#82#, 16#AC#]), "U+20AC");
   Check (Is_Valid ([16#F0#, 16#9F#, 16#98#, 16#80#]), "U+1F600");
   Check (Is_Valid ([16#F4#, 16#8F#, 16#BF#, 16#BF#]), "U+10FFFF");
   Check (not Is_Valid ([16#F4#, 16#90#, 16#80#, 16#80#]), "U+110000");
   Check (not Is_Valid ([16#C0#, 16#80#]), "overlong NUL");
   Check (not Is_Valid ([16#E0#, 16#80#, 16#80#]), "overlong 3-byte");
   Check (not Is_Valid ([16#F0#, 16#80#, 16#80#, 16#80#]), "overlong 4-byte");
   Check (not Is_Valid ([16#ED#, 16#A0#, 16#80#]), "surrogate U+D800");
   Check (Is_Valid ([16#ED#, 16#9F#, 16#BF#]), "U+D7FF");
   Check (Is_Valid ([16#EE#, 16#80#, 16#80#]), "U+E000");
   Check (not Is_Valid ([16#80#]), "lone continuation");
   Check (not Is_Valid ([16#C3#]), "truncated 2-byte");
   Check (not Is_Valid ([16#E2#, 16#82#]), "truncated 3-byte");
   Check (not Is_Valid ([16#C3#, 16#41#]), "lead + ASCII");
   Check (not Is_Valid ([16#FF#]), "FF");
   Check (Is_Valid ([5 => 16#C3#, 6 => 16#A9#]), "lower bound 5");
   Check (not Is_Valid ([5 => 16#A9#, 6 => 16#C3#]), "lower bound 5, reversed");

   --  Exhaustive: every array of 1, 2 and 3 bytes (16,843,008 arrays)
   for B1 in Byte loop
      Compare ([B1]);
      for B2 in Byte loop
         Compare ([B1, B2]);
         for B3 in Byte loop
            if Is_Valid ([B1, B2, B3]) /= Ref ([B1, B2, B3]) then
               Count := Count + 1;
            end if;
         end loop;
      end loop;
   end loop;
   Check (Count = 0, " exhaustive 3-byte arrays:" & Count'Image & " differ");

   --  Every 4-byte array whose bytes come from Edge (27**4 = 531,441)
   Count := 0;
   for B1 of Edge loop
      for B2 of Edge loop
         for B3 of Edge loop
            for B4 of Edge loop
               if Is_Valid ([B1, B2, B3, B4]) /= Ref ([B1, B2, B3, B4]) then
                  Count := Count + 1;
               end if;
            end loop;
         end loop;
      end loop;
   end loop;
   Check (Count = 0, " edge-byte 4-byte arrays:" & Count'Image & " differ");

   --  Every 4-byte lead F0 .. FF x every second byte 00 .. FF, with third
   --  and fourth bytes at the continuation edges and just outside them
   Count := 0;
   for B1 in Byte range 16#F0# .. 16#FF# loop
      for B2 in Byte loop
         for B3 of Tail loop
            for B4 of Tail loop
               if Is_Valid ([B1, B2, B3, B4]) /= Ref ([B1, B2, B3, B4]) then
                  Count := Count + 1;
               end if;
            end loop;
         end loop;
      end loop;
   end loop;
   Check (Count = 0, " 4-byte leads x all second bytes:" & Count'Image & " differ");

   --  Seeded random (seed 20261009): 200,000 arrays of length 0 .. 16, at a
   --  random lower bound; bytes from Edge, from the full range, or built from
   --  encoded code points
   Count := 0;
   for K in 1 .. 200_000 loop
      declare
         N  : constant Natural := Next (17);
         Lo : constant Positive := 1 + Next (50);
         A  : Byte_Array (Lo .. Lo + N - 1) := [others => 0];
         P  : Integer := Lo;
      begin
         while P <= A'Last loop
            case Next (3) is
               when 0 => A (P) := Edge (Next (Edge'Length)); P := P + 1;
               when 1 => A (P) := Next (256); P := P + 1;
               when others =>
                  declare
                     CP : constant Natural := Next (16#11_0000#);
                  begin
                     if CP < 16#80# then
                        A (P) := CP; P := P + 1;
                     elsif CP < 16#800# and then P + 1 <= A'Last then
                        A (P) := 16#C0# + CP / 64; A (P + 1) := 16#80# + CP mod 64; P := P + 2;
                     elsif CP < 16#1_0000# and then P + 2 <= A'Last then
                        A (P) := 16#E0# + CP / 4096; A (P + 1) := 16#80# + CP / 64 mod 64;
                        A (P + 2) := 16#80# + CP mod 64; P := P + 3;
                     elsif P + 3 <= A'Last then
                        A (P) := 16#F0# + CP / 262144; A (P + 1) := 16#80# + CP / 4096 mod 64;
                        A (P + 2) := 16#80# + CP / 64 mod 64; A (P + 3) := 16#80# + CP mod 64; P := P + 4;
                     else
                        A (P) := 16#41#; P := P + 1;
                     end if;
                  end;
            end case;
         end loop;
         if Is_Valid (A) /= Ref (A) then
            Count := Count + 1;
         end if;
      end;
   end loop;
   Check (Count = 0, " random arrays (seed 20261009):" & Count'Image & " differ");

   if Fails = 0 then
      Put_Line ("PASS Ada-SPARK-UTF-8-Validation");
   else
      Put_Line ("FAILED" & Fails'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
