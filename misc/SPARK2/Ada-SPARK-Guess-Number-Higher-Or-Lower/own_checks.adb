--  Own tests for Guess_Number_Higher_Or_Lower (written for this
--  repository; see tests/SOURCES.txt). Assumption: Guess_Number returns
--  the wrong number, or uses more guesses than a binary search needs.
--  Reference: no second search; for every N in 1 .. 32 and every Secret
--  in 1 .. N (528 games) the checks are: the answer is Secret; the guess
--  count is at least 1 and at most M (N), the smallest M with
--  2 ** M - 1 >= N, computed here by doubling; some secret needs exactly
--  M (N) guesses (the worst case of an optimal search); and at most
--  2 ** (K - 1) secrets are found with exactly K guesses (a search whose
--  answers are lower / higher / equal has at most that many positions at
--  depth K). Probe is checked against the integer order for all pairs.
--  No randomness, so no seed.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Guess_Number_Higher_Or_Lower; use Guess_Number_Higher_Or_Lower;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   procedure Fail (Msg : String) is
   begin
      Failures := Failures + 1;
      if Failures <= 5 then
         Put_Line ("FAIL " & Msg);
      end if;
   end Fail;
begin
   for S in Number loop
      for G in Number loop
         Cases := Cases + 1;
         if Probe (S, G) /= (if S < G then Lower elsif S = G then Equal else Higher) then
            Fail ("Probe (" & S'Image & "," & G'Image & ")");
         end if;
      end loop;
   end loop;
   for N in Number loop
      declare
         M     : Natural := 0;
         Power : Natural := 1;   --  2 ** M
         Worst : Natural := 0;
         At_Depth : array (1 .. 40) of Natural := [others => 0];
      begin
         while Power - 1 < N loop
            M := M + 1;
            Power := Power * 2;
         end loop;
         for S in 1 .. N loop
            declare
               R : constant Result := Guess_Number (N, S);
            begin
               Cases := Cases + 1;
               if R.Answer /= S then
                  Fail ("N" & N'Image & ", secret" & S'Image & ": answer" & R.Answer'Image);
               elsif R.Probes < 1 or else R.Probes > M then
                  Fail ("N" & N'Image & ", secret" & S'Image & ":" & R.Probes'Image
                        & " guesses, bound" & M'Image);
               else
                  Worst := Natural'Max (Worst, R.Probes);
                  At_Depth (R.Probes) := At_Depth (R.Probes) + 1;
               end if;
            end;
         end loop;
         if Worst /= M then
            Fail ("N" & N'Image & ": worst case" & Worst'Image & ", expected" & M'Image);
         end if;
         for K in 1 .. M loop
            if At_Depth (K) > 2 ** (K - 1) then
               Fail ("N" & N'Image & ":" & At_Depth (K)'Image & " secrets at depth" & K'Image);
            end if;
         end loop;
      end;
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image
             & " cases (all 528 games: answer, guess bound and worst case; Probe on all pairs)");
end Own_Checks;
