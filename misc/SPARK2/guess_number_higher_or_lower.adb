pragma Ada_2022;

package body Guess_Number_Higher_Or_Lower with SPARK_Mode => On is
   function Guess_Number (Secret : Number) return Number is
      Candidate : Number;
   begin
      for Guess in Number loop
         Candidate := Guess;
         exit when Guess = Secret;
      end loop;
      return Candidate;
   end Guess_Number;
end Guess_Number_Higher_Or_Lower;
