pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Restore_IP_Addresses; use Restore_IP_Addresses;
--  Own checks (H123): Restore (D, Len, List, Count) must list every way to
--  put 3 dots into the digit string D (1 .. Len) so that each of the 4
--  parts is 0 .. 255 without a leading zero, once each, in lexicographic
--  order of the part lengths. Reference: every choice of dot positions
--  I < J < K (parts of any length), each part converted to a number
--  (brute force). Exhaustive: every string of length 0 .. 7 over the
--  digits {0, 1, 2, 5, 6, 9}; known cases; 20,000 random strings of length
--  0 .. 20 (seed 20261009).
procedure Own_Checks is
   Fails : Natural := 0;
   Cases : Natural := 0;
   Seed  : Long_Long_Integer := 20261009;

   function Rand (N : Positive) return Natural is
   begin
      Seed := (Seed * 16807) mod 2_147_483_647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      Cases := Cases + 1;
      if not Cond then
         Fails := Fails + 1;
         if Fails <= 5 then
            Put_Line ("FAIL " & Name);
         end if;
      end if;
   end Check;

   function Part_Ok (D : Digit_String; From, To : Positive) return Boolean is
      V : Natural := 0;
   begin
      if From > To or else (To > From and then D (From) = 0) then
         return False;
      end if;
      for I in From .. To loop
         V := V * 10 + D (I);
         if V > 255 then
            return False;
         end if;
      end loop;
      return True;
   end Part_Ok;

   procedure Run (D : Digit_String; Len : String_Length; Tag : String; Expect : Integer := -1) is
      List  : Address_List;
      Count : Natural;
      Want  : array (1 .. 81) of Address;
      NW    : Natural := 0;
   begin
      for I in 1 .. Len - 1 loop
         for J in I + 1 .. Len - 1 loop
            for K in J + 1 .. Len - 1 loop
               if Part_Ok (D, 1, I) and then Part_Ok (D, I + 1, J)
                 and then Part_Ok (D, J + 1, K) and then Part_Ok (D, K + 1, Len)
               then
                  NW := NW + 1;
                  Want (NW) := [I, J - I, K - J, Len - K];
               end if;
            end loop;
         end loop;
      end loop;
      --  the loops above already run in lexicographic order of the lengths
      Restore (D, Len, List, Count);
      Check (Count = NW, "count" & Tag & " got" & Count'Image & " want" & NW'Image);
      for K in 1 .. Natural'Min (Count, NW) loop
         Check (List (K) = Want (K), "address" & K'Image & Tag);
      end loop;
      if Expect >= 0 then
         Check (NW = Expect, "known count" & Tag);
      end if;
   end Run;

   function Of_Text (S : String) return Digit_String is
      D : Digit_String := [others => 0];
   begin
      for I in S'Range loop
         D (I - S'First + 1) := Character'Pos (S (I)) - Character'Pos ('0');
      end loop;
      return D;
   end Of_Text;

   Alphabet : constant array (0 .. 5) of Digit := [0, 1, 2, 5, 6, 9];
   D : Digit_String := [others => 0];
begin
   Run (Of_Text ("25525511135"), 11, " 25525511135", 2);
   Run (Of_Text ("0000"), 4, " 0000", 1);
   Run (Of_Text ("101023"), 6, " 101023", 5);
   Run (Of_Text ("255255255255"), 12, " 255255255255", 1);
   Run (Of_Text ("2552552552551"), 13, " 13 digits", 0);
   for Len in 0 .. 7 loop
      for M in 0 .. 6 ** Len - 1 loop
         declare
            X : Natural := M;
         begin
            for P in 1 .. Len loop
               D (P) := Alphabet (X mod 6);
               X := X / 6;
            end loop;
         end;
         Run (D, Len, " exhaustive len" & Len'Image & " M =" & M'Image);
      end loop;
   end loop;
   for T in 1 .. 20_000 loop
      declare
         Len : constant String_Length := Rand (Max_Len + 1);
      begin
         for P in 1 .. Len loop
            D (P) := (if Rand (4) = 0 then Rand (3) else Rand (10));
         end loop;
         Run (D, Len, " random" & T'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Restore_IP_Addresses own checks:" & Cases'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
