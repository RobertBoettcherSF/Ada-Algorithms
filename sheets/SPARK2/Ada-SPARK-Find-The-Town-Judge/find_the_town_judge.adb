pragma Ada_2022;
package body Find_The_Town_Judge with SPARK_Mode => On is
   function Find_Judge (Trust : Trust_Matrix) return Judge is
   begin
      for Candidate in Person loop
         declare
            Candidate_Is_Judge : Boolean := True;
         begin
            for Other in Person loop
               if Trust (Candidate, Other) then
                  Candidate_Is_Judge := False;
               elsif Other /= Candidate and then not Trust (Other, Candidate) then
                  Candidate_Is_Judge := False;
               end if;
            end loop;
            if Candidate_Is_Judge then
               return Candidate;
            end if;
         end;
      end loop;
      return 0;
   end Find_Judge;
end Find_The_Town_Judge;
