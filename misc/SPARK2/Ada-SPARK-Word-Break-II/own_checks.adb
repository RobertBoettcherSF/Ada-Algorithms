pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Word_Break_II; use Word_Break_II;
--  Own checks (H122): Word Break II on a text of up to 12 letters and a
--  dictionary of up to 50 words. Every sentence (a split of the text into
--  dictionary words) must be listed exactly once, and Count_Sentences must
--  count them. Reference: try all 2 ** (N - 1) splits and keep those whose
--  pieces are all in the dictionary (brute force). Exhaustive over texts of
--  length 0 .. 6 on {a, b} with the dictionary {a, b, ab, ba, aa, aba};
--  2,000 random texts / dictionaries on {a, b, c} (seed 20261009).
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

   function Word_Of (W : String) return Dict_Word is
      R : Dict_Word := (Chars => [others => ' '], Len => W'Length);
   begin
      for I in W'Range loop
         R.Chars (I - W'First + 1) := W (I);
      end loop;
      return R;
   end Word_Of;

   function In_Dict (S : Text; From, To : Positive; D : Dictionary; DC : Word_Count) return Boolean is
   begin
      for K in 1 .. DC loop
         if D (K).Len = To - From + 1 then
            declare
               Same : Boolean := True;
            begin
               for I in From .. To loop
                  Same := Same and then D (K).Chars (I - From + 1) = S (I);
               end loop;
               if Same then
                  return True;
               end if;
            end;
         end if;
      end loop;
      return False;
   end In_Dict;

   --  break set as a number: bit P - 1 set when a word ends at P
   function Code (B : Break_Set; N : Text_Length) return Natural is
      C : Natural := 0;
   begin
      for P in 1 .. N loop
         if B (P) then
            C := C + 2 ** (P - 1);
         end if;
      end loop;
      return C;
   end Code;

   procedure Run (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count; Tag : String) is
      Want  : array (0 .. 4095) of Boolean := [others => False];
      NW    : Natural := 0;
      List  : Sentence_List;
      Count : Natural;
      Seen  : array (0 .. 4095) of Boolean := [others => False];
   begin
      if N = 0 then
         Want (0) := True;
         NW := 1;
      else
         for M in 0 .. 2 ** (N - 1) - 1 loop
            --  bit P - 1 of M (P < N): a word ends at P; a word always ends at N
            declare
               From : Positive := 1;
               Ok   : Boolean := True;
            begin
               for P in 1 .. N loop
                  if P = N or else (M / 2 ** (P - 1)) mod 2 = 1 then
                     Ok := Ok and then In_Dict (S, From, P, D, DC);
                     From := P + 1;
                  end if;
               end loop;
               if Ok then
                  Want (M + 2 ** (N - 1)) := True;
                  NW := NW + 1;
               end if;
            end;
         end loop;
      end if;
      Check (Count_Sentences (S, N, D, DC) = NW, "count" & Tag);
      Sentences (S, N, D, DC, List, Count);
      Check (Count = NW, "listed" & Tag);
      for K in 1 .. Natural'Min (Count, Max_Sentences) loop
         declare
            C : constant Natural := Code (List (K), N);
         begin
            Check (C <= 4095 and then Want (C) and then not Seen (C), "sentence" & K'Image & Tag);
            if C <= 4095 then
               Seen (C) := True;
            end if;
         end;
      end loop;
   end Run;

   S  : Text := [others => 'a'];
   D  : Dictionary := [others => Word_Of ("a")];
begin
   --  exhaustive: all texts of length 0 .. 6 on {a, b}, fixed dictionary
   D (1 .. 6) := [Word_Of ("a"), Word_Of ("b"), Word_Of ("ab"), Word_Of ("ba"), Word_Of ("aa"), Word_Of ("aba")];
   for N in 0 .. 6 loop
      for M in 0 .. 2 ** N - 1 loop
         for P in 1 .. N loop
            S (P) := (if (M / 2 ** (P - 1)) mod 2 = 1 then 'b' else 'a');
         end loop;
         Run (S, N, D, 6, " exhaustive N =" & N'Image & " M =" & M'Image);
      end loop;
   end loop;
   --  all-'a' text of length 12 with every word a .. aaaaaaaaaaaa: 2 ** 11 sentences
   for L in 1 .. 12 loop
      D (L) := Word_Of ([1 .. L => 'a']);
   end loop;
   S := [others => 'a'];
   Run (S, 12, D, 12, " all a, 12 words");
   --  random
   for T in 1 .. 2_000 loop
      declare
         N  : constant Text_Length := Rand (Max_Len + 1);
         DC : constant Word_Count := Rand (Max_Words + 1);
      begin
         for P in 1 .. N loop
            S (P) := Character'Val (Character'Pos ('a') + Rand (3));
         end loop;
         for K in 1 .. DC loop
            declare
               L : constant Positive := 1 + Rand (if Rand (4) = 0 then Max_Word_Len else 3);
               W : String (1 .. L);
            begin
               for I in W'Range loop
                  W (I) := Character'Val (Character'Pos ('a') + Rand (3));
               end loop;
               D (K) := Word_Of (W);
            end;
         end loop;
         Run (S, N, D, DC, " random" & T'Image);
      end;
   end loop;
   if Fails = 0 then
      Put_Line ("PASS Word_Break_II own checks:" & Cases'Image & " checks (seed 20261009)");
   else
      Put_Line ("FAILED" & Fails'Image & " of" & Cases'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Own_Checks;
