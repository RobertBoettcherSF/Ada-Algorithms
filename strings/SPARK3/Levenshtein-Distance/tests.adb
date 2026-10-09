pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Levenshtein_Distance; use Levenshtein_Distance;
procedure Tests is
   A : constant Char_Array := ('k', 'i', 't', 't', 'e', 'n');
   B : constant Char_Array := ('s', 'i', 't', 't', 'i', 'n', 'g');
   E : constant Char_Array (1 .. 0) := [];
begin
   Assert (Distance (E, E) = 0);
   Assert (Distance (A, A) = 0);
   Assert (Distance (A, B) = 3);
   Assert (Distance (['a'], ['b']) = 1);
   Put_Line ("PASS Levenshtein_Distance Distance");

   --  Any origin: the same strings at origins 1, 5, 200 and ending at
   --  Positive'Last give the origin-1 distance (A at one origin, B at
   --  another, every pair of lengths 0 .. Max_Len over a small alphabet).
   declare
      Seed : Natural := 12345;
      function Next return Character is
      begin
         Seed := (Seed * 1103 + 12345) mod 65536;
         return Character'Val (Character'Pos ('a') + Seed / 256 mod 3);
      end Next;
      Bad : Natural := 0;
   begin
      for LA in 0 .. Max_Len loop
         for LB in 0 .. Max_Len loop
            for Trial in 1 .. 4 loop
               declare
                  A1 : Char_Array (1 .. LA);
                  B1 : Char_Array (1 .. LB);
                  Want : Natural;
               begin
                  for C of A1 loop C := Next; end loop;
                  for C of B1 loop C := Next; end loop;
                  Want := Distance (A1, B1);
                  for OA in 1 .. 3 loop
                     for OB in 1 .. 3 loop
                        declare
                           SA : constant Positive :=
                             (case OA is when 1 => 5, when 2 => 200,
                                         when others =>
                                           (if LA = 0 then Positive'Last
                                            else Positive'Last - LA + 1));
                           SB : constant Positive :=
                             (case OB is when 1 => 1, when 2 => 7,
                                         when others =>
                                           (if LB = 0 then Positive'Last
                                            else Positive'Last - LB + 1));
                           A2 : Char_Array (SA .. SA + (LA - 1));
                           B2 : Char_Array (SB .. SB + (LB - 1));
                        begin
                           for K in 0 .. LA - 1 loop A2 (SA + K) := A1 (1 + K); end loop;
                           for K in 0 .. LB - 1 loop B2 (SB + K) := B1 (1 + K); end loop;
                           if Distance (A2, B2) /= Want then
                              Bad := Bad + 1;
                           end if;
                        end;
                     end loop;
                  end loop;
               end;
            end loop;
         end loop;
      end loop;
      Assert (Bad = 0, "shifted origins disagree with origin 1:" & Bad'Image);
      Put_Line ("PASS Levenshtein_Distance any origin");
   end;
   Put_Line ("All Levenshtein_Distance SPARK topic tests passed.");
end Tests;
